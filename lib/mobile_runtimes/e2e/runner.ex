defmodule MobileRuntimes.E2E.Runner do
  @moduledoc """
  Orchestrates E2E test execution across multiple architectures.

  This module:
  1. Builds test apps for each architecture
  2. Starts emulators/simulators
  3. Installs and runs test apps
  4. Collects results and generates reports
  """

  require Logger

  alias MobileRuntimes.E2E.{Architecture, Builder, Emulator, Retry, TestCase, TestSuite}

  @type run_opts :: [
          timeout: non_neg_integer(),
          retries: non_neg_integer(),
          skip_build: boolean(),
          verbose: boolean(),
          keep_alive: boolean()
        ]

  @default_timeout 300_000
  @default_retries 3

  @doc """
  Run E2E tests on specified architectures.

  ## Options

    * `:timeout` - Per-suite timeout in ms (default: 300_000)
    * `:retries` - Max infrastructure retries (default: 3)
    * `:skip_build` - Skip test app build (default: false)
    * `:verbose` - Enable verbose logging (default: false)
    * `:keep_alive` - Keep emulator running after tests (default: false)

  ## Returns

    * `{:ok, [TestSuite.t()]}` - All suites completed (may include failures)
    * `{:error, reason}` - Fatal error preventing test execution
  """
  @spec run([Architecture.t()], run_opts()) :: {:ok, [TestSuite.t()]} | {:error, term()}
  def run(architectures, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    retries = Keyword.get(opts, :retries, @default_retries)
    skip_build = Keyword.get(opts, :skip_build, false)
    verbose = Keyword.get(opts, :verbose, false)
    keep_alive = Keyword.get(opts, :keep_alive, false)

    if verbose do
      Logger.configure(level: :debug)
    end

    # Build test apps if needed
    unless skip_build do
      case build_test_apps(architectures) do
        :ok -> :ok
        {:error, reason} -> throw({:build_failed, reason})
      end
    end

    # Run tests for each architecture
    results =
      Enum.map(architectures, fn arch ->
        run_architecture(arch, timeout, retries, keep_alive)
      end)

    {:ok, results}
  catch
    {:build_failed, reason} ->
      {:error, {:build_failed, reason}}
  end

  @doc """
  Run tests for a single architecture.
  """
  @spec run_single(Architecture.t(), run_opts()) :: {:ok, TestSuite.t()} | {:error, term()}
  def run_single(arch, opts \\ []) do
    case run([arch], opts) do
      {:ok, [suite]} -> {:ok, suite}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_test_apps(architectures) do
    Logger.info("Building test apps for: #{inspect(architectures)}")

    # Group by platform
    android_archs = Enum.filter(architectures, &(Architecture.platform(&1) == :android))
    ios_archs = Enum.filter(architectures, &(Architecture.platform(&1) == :ios))

    with :ok <- build_android_apps(android_archs),
         :ok <- build_ios_apps(ios_archs) do
      :ok
    end
  end

  defp build_android_apps([]), do: :ok

  defp build_android_apps(archs) do
    Logger.info("Building Android test app for: #{inspect(archs)}")
    Builder.build_android(archs)
  end

  defp build_ios_apps([]), do: :ok

  defp build_ios_apps(archs) do
    Logger.info("Building iOS test app for: #{inspect(archs)}")
    Builder.build_ios(archs)
  end

  defp run_architecture(arch, timeout, max_retries, keep_alive) do
    suite = TestSuite.new(arch)
    Logger.info("Running E2E tests for #{inspect(arch)}")

    run_with_retry(suite, arch, timeout, max_retries, keep_alive)
  end

  defp run_with_retry(suite, arch, timeout, max_retries, keep_alive) do
    retry_opts = [
      max_retries: max_retries,
      initial_delay_ms: 2000,
      on_retry: fn attempt, reason ->
        Logger.warning("Retry #{attempt}/#{max_retries} for #{inspect(arch)}: #{inspect(reason)}")
      end
    ]

    result =
      Retry.with_retry(fn ->
        execute_suite(arch, timeout, keep_alive)
      end, retry_opts)

    case result do
      {:ok, {tests, total_time}} ->
        TestSuite.complete(suite, tests)
        |> Map.put(:total_time_ms, total_time)

      {:error, :max_retries_exceeded, reason} ->
        Logger.error("Max retries exceeded for #{inspect(arch)}: #{inspect(reason)}")
        TestSuite.infrastructure_error(suite)

      {:error, :timeout} ->
        Logger.error("Timeout for #{inspect(arch)}")
        TestSuite.timeout(suite)

      {:error, reason} ->
        Logger.error("Error for #{inspect(arch)}: #{inspect(reason)}")
        TestSuite.infrastructure_error(suite)
    end
  end

  defp execute_suite(arch, timeout, keep_alive) do
    start_time = System.monotonic_time(:millisecond)

    with {:ok, emulator_id} <- Emulator.start(arch),
         app_path <- get_app_path(arch),
         :ok <- Emulator.install(emulator_id, app_path),
         {:ok, output, _exit_code} <- Emulator.run_app(emulator_id, timeout: timeout),
         {:ok, tests} <- parse_test_results(output) do
      unless keep_alive do
        Emulator.stop(emulator_id)
      end

      total_time = System.monotonic_time(:millisecond) - start_time
      {:ok, {tests, total_time}}
    else
      {:error, :infrastructure, reason} ->
        Retry.infrastructure_error(reason)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_app_path(arch) do
    case Architecture.platform(arch) do
      :android ->
        abi = Architecture.to_string(arch)
        "_build/e2e/android/app/build/outputs/apk/#{abi}/debug/app-#{abi}-debug.apk"

      :ios ->
        "_build/e2e/ios/Build/Products/Debug-iphonesimulator/BeamTest.app"
    end
  end

  defp parse_test_results(json_output) do
    case Jason.decode(json_output) do
      {:ok, %{"tests" => tests_json}} ->
        tests =
          Enum.map(tests_json, fn test_json ->
            case TestCase.from_json(test_json) do
              {:ok, test} -> test
              {:error, _} -> nil
            end
          end)
          |> Enum.reject(&is_nil/1)

        {:ok, tests}

      {:ok, _} ->
        {:error, :invalid_results_format}

      {:error, reason} ->
        {:error, {:json_parse_error, reason}}
    end
  end
end
