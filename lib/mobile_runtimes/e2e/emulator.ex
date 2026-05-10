defmodule MobileRuntimes.E2E.Emulator do
  @moduledoc """
  Manages Android emulators and iOS simulators for E2E testing.

  Provides unified interface for:
  - Starting/stopping emulators and simulators
  - Installing test apps
  - Running tests and capturing output
  """

  require Logger

  alias MobileRuntimes.E2E.{Architecture, Retry}

  @type emulator_id :: String.t()
  @type run_opts :: [timeout: non_neg_integer()]

  @default_timeout 300_000
  @boot_timeout 120_000

  @doc """
  Start an emulator/simulator for the given architecture.

  Returns `{:ok, emulator_id}` on success, or `{:error, reason}` on failure.
  """
  @spec start(Architecture.t()) :: {:ok, emulator_id()} | {:error, term()}
  def start(arch) do
    case Architecture.platform(arch) do
      :android -> start_android_emulator(arch)
      :ios -> start_ios_simulator(arch)
    end
  end

  @doc """
  Stop an emulator/simulator by ID.
  """
  @spec stop(emulator_id()) :: :ok | {:error, term()}
  def stop(emulator_id) do
    cond do
      String.starts_with?(emulator_id, "emulator-") ->
        stop_android_emulator(emulator_id)

      true ->
        stop_ios_simulator(emulator_id)
    end
  end

  @doc """
  Install test app on emulator/simulator.
  """
  @spec install(emulator_id(), Path.t()) :: :ok | {:error, term()}
  def install(emulator_id, app_path) do
    cond do
      String.starts_with?(emulator_id, "emulator-") ->
        install_android_app(emulator_id, app_path)

      true ->
        install_ios_app(emulator_id, app_path)
    end
  end

  @doc """
  Run test app and capture output.

  Returns `{:ok, output, exit_code}` on success, or `{:error, reason}` on failure.
  """
  @spec run_app(emulator_id(), run_opts()) :: {:ok, String.t(), integer()} | {:error, term()}
  def run_app(emulator_id, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    cond do
      String.starts_with?(emulator_id, "emulator-") ->
        run_android_app(emulator_id, timeout)

      true ->
        run_ios_app(emulator_id, timeout)
    end
  end

  # Android implementation

  defp start_android_emulator(arch) do
    Logger.info("Starting Android emulator for #{inspect(arch)}")

    # Check for running emulator first
    case get_running_android_emulator() do
      {:ok, emulator_id} ->
        Logger.info("Using existing emulator: #{emulator_id}")
        {:ok, emulator_id}

      :none ->
        # Find an AVD and start it
        case find_android_avd(arch) do
          {:ok, avd_name} ->
            launch_android_emulator(avd_name)

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp get_running_android_emulator do
    case System.cmd("adb", ["devices"], stderr_to_stdout: true) do
      {output, 0} ->
        output
        |> String.split("\n")
        |> Enum.find_value(:none, fn line ->
          case Regex.run(~r/^(emulator-\d+)\s+device/, line) do
            [_, emulator_id] -> {:ok, emulator_id}
            _ -> nil
          end
        end)

      _ ->
        :none
    end
  end

  defp find_android_avd(_arch) do
    android_home = System.get_env("ANDROID_HOME") || System.get_env("ANDROID_SDK_ROOT")

    if android_home do
      emulator_path = Path.join([android_home, "emulator", "emulator"])

      case System.cmd(emulator_path, ["-list-avds"], stderr_to_stdout: true) do
        {output, 0} ->
          avds =
            output
            |> String.split("\n")
            |> Enum.reject(&(&1 == ""))
            |> Enum.reject(&String.starts_with?(&1, "INFO"))

          case List.first(avds) do
            nil -> {:error, :no_avd_found}
            avd -> {:ok, avd}
          end

        {error, _} ->
          {:error, {:emulator_list_failed, error}}
      end
    else
      {:error, :android_home_not_set}
    end
  end

  defp launch_android_emulator(avd_name) do
    android_home = System.get_env("ANDROID_HOME") || System.get_env("ANDROID_SDK_ROOT")
    emulator_path = Path.join([android_home, "emulator", "emulator"])

    # Start emulator in background
    port =
      Port.open({:spawn_executable, emulator_path}, [
        :binary,
        :exit_status,
        args: [
          "-avd",
          avd_name,
          "-no-snapshot-save",
          "-no-window",
          "-gpu",
          "swiftshader_indirect",
          "-no-audio"
        ]
      ])

    # Wait for emulator to boot
    case wait_for_android_boot(@boot_timeout) do
      {:ok, emulator_id} ->
        # Store port reference for cleanup
        Process.put(:android_emulator_port, port)
        {:ok, emulator_id}

      {:error, reason} ->
        Port.close(port)
        {:error, reason}
    end
  end

  defp wait_for_android_boot(timeout) do
    start_time = System.monotonic_time(:millisecond)

    wait_for_android_boot_loop(start_time, timeout)
  end

  defp wait_for_android_boot_loop(start_time, timeout) do
    elapsed = System.monotonic_time(:millisecond) - start_time

    if elapsed > timeout do
      {:error, :boot_timeout}
    else
      case get_running_android_emulator() do
        {:ok, emulator_id} ->
          # Wait for boot_completed
          case System.cmd("adb", ["-s", emulator_id, "shell", "getprop", "sys.boot_completed"],
                 stderr_to_stdout: true
               ) do
            {"1\n", 0} ->
              {:ok, emulator_id}

            _ ->
              Process.sleep(2000)
              wait_for_android_boot_loop(start_time, timeout)
          end

        :none ->
          Process.sleep(2000)
          wait_for_android_boot_loop(start_time, timeout)
      end
    end
  end

  defp stop_android_emulator(emulator_id) do
    System.cmd("adb", ["-s", emulator_id, "emu", "kill"], stderr_to_stdout: true)

    case Process.get(:android_emulator_port) do
      nil ->
        :ok

      port ->
        Port.close(port)
        Process.delete(:android_emulator_port)
        :ok
    end
  end

  defp install_android_app(emulator_id, apk_path) do
    Logger.info("Installing APK on #{emulator_id}: #{apk_path}")

    case System.cmd("adb", ["-s", emulator_id, "install", "-r", apk_path], stderr_to_stdout: true) do
      {_, 0} -> :ok
      {error, _} -> Retry.infrastructure_error({:install_failed, error})
    end
  end

  defp run_android_app(emulator_id, timeout) do
    Logger.info("Running test app on #{emulator_id}")

    # Clear logcat
    System.cmd("adb", ["-s", emulator_id, "logcat", "-c"], stderr_to_stdout: true)

    # Start the test app
    case System.cmd(
           "adb",
           ["-s", emulator_id, "shell", "am", "start", "-n", "io.beamtest/.MainActivity"],
           stderr_to_stdout: true
         ) do
      {_, 0} ->
        # Wait for test completion and capture output
        capture_android_output(emulator_id, timeout)

      {error, _} ->
        Retry.infrastructure_error({:start_failed, error})
    end
  end

  defp capture_android_output(emulator_id, timeout) do
    start_time = System.monotonic_time(:millisecond)

    # Poll logcat for test results
    capture_android_output_loop(emulator_id, start_time, timeout, "")
  end

  defp capture_android_output_loop(emulator_id, start_time, timeout, _acc) do
    elapsed = System.monotonic_time(:millisecond) - start_time

    if elapsed > timeout do
      {:error, :timeout}
    else
      case System.cmd("adb", ["-s", emulator_id, "logcat", "-d", "-s", "BeamTest:I"],
             stderr_to_stdout: true
           ) do
        {output, 0} ->
          if String.contains?(output, "E2E_TEST_RESULTS_END") do
            # Extract JSON between markers
            case extract_test_results(output) do
              {:ok, json} -> {:ok, json, 0}
              :not_found -> {:error, :results_not_found}
            end
          else
            Process.sleep(1000)
            capture_android_output_loop(emulator_id, start_time, timeout, output)
          end

        {error, _} ->
          Retry.infrastructure_error({:logcat_failed, error})
      end
    end
  end

  # iOS implementation

  defp start_ios_simulator(arch) do
    Logger.info("Starting iOS simulator for #{inspect(arch)}")

    device_type = get_ios_device_type(arch)

    # Check for booted simulator
    case get_booted_ios_simulator() do
      {:ok, udid} ->
        Logger.info("Using existing simulator: #{udid}")
        {:ok, udid}

      :none ->
        # Create and boot a new simulator
        case create_ios_simulator(device_type, arch) do
          {:ok, udid} ->
            boot_ios_simulator(udid)

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp get_ios_device_type(_arch) do
    # Use iPhone 15 as default test device
    "iPhone 15"
  end

  defp get_booted_ios_simulator do
    case System.cmd("xcrun", ["simctl", "list", "devices", "booted", "-j"],
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, %{"devices" => devices}} ->
            devices
            |> Enum.flat_map(fn {_runtime, device_list} -> device_list end)
            |> Enum.find_value(:none, fn device ->
              if device["state"] == "Booted" do
                {:ok, device["udid"]}
              else
                nil
              end
            end)

          _ ->
            :none
        end

      _ ->
        :none
    end
  end

  defp create_ios_simulator(device_type, arch) do
    runtime = get_ios_runtime(arch)

    case System.cmd("xcrun", ["simctl", "create", "E2E-Test", device_type, runtime],
           stderr_to_stdout: true
         ) do
      {udid, 0} ->
        {:ok, String.trim(udid)}

      {error, _} ->
        # Try to find existing simulator with this name
        case find_existing_simulator("E2E-Test") do
          {:ok, udid} -> {:ok, udid}
          :not_found -> {:error, {:create_failed, error}}
        end
    end
  end

  defp find_existing_simulator(name) do
    case System.cmd("xcrun", ["simctl", "list", "devices", "-j"], stderr_to_stdout: true) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, %{"devices" => devices}} ->
            devices
            |> Enum.flat_map(fn {_runtime, device_list} -> device_list end)
            |> Enum.find_value(:not_found, fn device ->
              if device["name"] == name do
                {:ok, device["udid"]}
              else
                nil
              end
            end)

          _ ->
            :not_found
        end

      _ ->
        :not_found
    end
  end

  defp get_ios_runtime(arch) do
    case arch do
      :ios_arm64_simulator -> "com.apple.CoreSimulator.SimRuntime.iOS-17-5"
      :ios_x86_64_simulator -> "com.apple.CoreSimulator.SimRuntime.iOS-17-5"
      _ -> "com.apple.CoreSimulator.SimRuntime.iOS-17-5"
    end
  end

  defp boot_ios_simulator(udid) do
    case System.cmd("xcrun", ["simctl", "boot", udid], stderr_to_stdout: true) do
      {_, 0} ->
        # Wait for simulator to be ready
        Process.sleep(5000)
        {:ok, udid}

      {error, _} ->
        if String.contains?(error, "already booted") do
          {:ok, udid}
        else
          {:error, {:boot_failed, error}}
        end
    end
  end

  defp stop_ios_simulator(udid) do
    System.cmd("xcrun", ["simctl", "shutdown", udid], stderr_to_stdout: true)
    :ok
  end

  defp install_ios_app(udid, app_path) do
    Logger.info("Installing app on simulator #{udid}: #{app_path}")

    case System.cmd("xcrun", ["simctl", "install", udid, app_path], stderr_to_stdout: true) do
      {_, 0} -> :ok
      {error, _} -> Retry.infrastructure_error({:install_failed, error})
    end
  end

  defp run_ios_app(udid, timeout) do
    Logger.info("Running test app on simulator #{udid}")

    # Launch the app and capture output
    task =
      Task.async(fn ->
        System.cmd("xcrun", ["simctl", "launch", "--console", udid, "io.beamtest"],
          stderr_to_stdout: true
        )
      end)

    case Task.yield(task, timeout) || Task.shutdown(task) do
      {:ok, {output, _exit_code}} ->
        case extract_test_results(output) do
          {:ok, json} -> {:ok, json, 0}
          :not_found -> {:error, :results_not_found}
        end

      nil ->
        {:error, :timeout}
    end
  end

  # Shared helpers

  defp extract_test_results(output) do
    case Regex.run(~r/E2E_TEST_RESULTS_START\n(.*)\nE2E_TEST_RESULTS_END/s, output) do
      [_, json] -> {:ok, String.trim(json)}
      _ -> :not_found
    end
  end
end
