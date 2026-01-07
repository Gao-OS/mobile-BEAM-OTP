defmodule MobileRuntimes.E2E.Builder do
  @moduledoc """
  Builds E2E test apps for Android and iOS.

  Handles:
  - Gradle builds for Android APK
  - xcodebuild for iOS app
  - Linking liberlang.a/xcframework
  """

  require Logger

  alias MobileRuntimes.E2E.Architecture

  @android_app_dir "test/e2e/apps/android"
  @ios_app_dir "test/e2e/apps/ios"

  @doc """
  Build Android test app for specified architectures.
  """
  @spec build_android([Architecture.t()]) :: :ok | {:error, term()}
  def build_android([]), do: :ok

  def build_android(archs) do
    Logger.info("Building Android test app...")

    # Verify liberlang.a exists for each architecture
    for arch <- archs do
      liberlang_path = Architecture.liberlang_path(arch)

      unless File.exists?(liberlang_path) do
        Logger.warning("liberlang.a not found for #{inspect(arch)}: #{liberlang_path}")
        Logger.warning("Run 'mix package.android.runtime' first")
      end
    end

    # Build APK using Gradle
    case run_gradle_build(archs) do
      :ok ->
        Logger.info("Android build complete")
        :ok

      {:error, reason} ->
        {:error, {:android_build_failed, reason}}
    end
  end

  @doc """
  Build iOS test app for specified architectures.
  """
  @spec build_ios([Architecture.t()]) :: :ok | {:error, term()}
  def build_ios([]), do: :ok

  def build_ios(archs) do
    Logger.info("Building iOS test app...")

    # Verify xcframework exists
    xcframework_path = "_build/liberlang.xcframework"

    unless File.exists?(xcframework_path) do
      Logger.warning("liberlang.xcframework not found: #{xcframework_path}")
      Logger.warning("Run 'mix package.ios.runtime' first")
    end

    # Build app using xcodebuild
    case run_xcode_build(archs) do
      :ok ->
        Logger.info("iOS build complete")
        :ok

      {:error, reason} ->
        {:error, {:ios_build_failed, reason}}
    end
  end

  defp run_gradle_build(archs) do
    # Determine which flavors to build
    flavors =
      archs
      |> Enum.map(&arch_to_gradle_flavor/1)
      |> Enum.uniq()

    # Ensure gradle wrapper exists, generate if needed
    gradlew_path = Path.join(@android_app_dir, "gradlew")

    final_cmd =
      cond do
        File.exists?(gradlew_path) ->
          "./gradlew"

        gradle_cmd = find_gradle_command() ->
          # Generate wrapper using system gradle
          Logger.info("Generating Gradle wrapper...")
          case System.cmd(gradle_cmd, ["wrapper", "--gradle-version", "8.5"],
                 cd: @android_app_dir,
                 stderr_to_stdout: true
               ) do
            {_, 0} ->
              if File.exists?(gradlew_path), do: "./gradlew", else: gradle_cmd

            {error, _} ->
              Logger.warning("Failed to generate wrapper: #{error}")
              gradle_cmd
          end

        true ->
          Logger.error("Neither gradlew nor gradle found. Install Gradle or add wrapper to project.")
          nil
      end

    if is_nil(final_cmd) do
      {:error, "Gradle not found"}
    else
      # Build each flavor
      Enum.reduce_while(flavors, :ok, fn flavor, _acc ->
        task = "assemble#{String.capitalize(flavor)}Debug"
        Logger.info("Running: #{final_cmd} #{task}")

        case System.cmd(
               final_cmd,
               [task, "--no-daemon"],
               cd: @android_app_dir,
               stderr_to_stdout: true,
               env: android_build_env()
             ) do
          {_output, 0} ->
            {:cont, :ok}

          {error, code} ->
            Logger.error("Gradle build failed (exit #{code}): #{error}")
            {:halt, {:error, error}}
        end
      end)
    end
  end

  defp find_gradle_command do
    # Try to find gradle in common locations
    cond do
      System.find_executable("gradle") -> "gradle"
      File.exists?("/opt/gradle/bin/gradle") -> "/opt/gradle/bin/gradle"
      true -> nil
    end
  end

  defp arch_to_gradle_flavor(arch) do
    case arch do
      :android_armeabi_v7a -> "arm"
      :android_arm64_v8a -> "arm64"
      :android_x86_64 -> "x86_64"
      _ -> "x86_64"
    end
  end

  defp android_build_env do
    android_home = System.get_env("ANDROID_HOME") || System.get_env("ANDROID_SDK_ROOT")
    android_ndk = System.get_env("ANDROID_NDK_HOME")

    [
      {"ANDROID_HOME", android_home},
      {"ANDROID_SDK_ROOT", android_home},
      {"ANDROID_NDK_HOME", android_ndk}
    ]
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
  end

  defp run_xcode_build(archs) do
    # Determine destination based on architecture
    # Use generic destinations to avoid hardcoding simulator names
    destination =
      cond do
        :ios_arm64 in archs -> "generic/platform=iOS"
        :ios_arm64_simulator in archs or :ios_x86_64_simulator in archs ->
          # Find an available iPhone or iPad simulator
          find_available_simulator() || "generic/platform=iOS Simulator"
        true -> "generic/platform=iOS Simulator"
      end

    Logger.info("Running: xcodebuild for destination '#{destination}'")

    args = [
      "build",
      "-project",
      "BeamTest.xcodeproj",
      "-scheme",
      "BeamTest",
      "-configuration",
      "Debug",
      "-destination",
      destination,
      "-derivedDataPath",
      "../../_build/e2e/ios"
    ]

    case System.cmd("xcodebuild", args,
           cd: @ios_app_dir,
           stderr_to_stdout: true
         ) do
      {_output, 0} ->
        :ok

      {error, code} ->
        Logger.error("xcodebuild failed (exit #{code}): #{error}")
        {:error, error}
    end
  end

  defp find_available_simulator do
    # Use xcrun simctl to find an available iOS simulator
    case System.cmd("xcrun", ["simctl", "list", "devices", "available", "-j"], stderr_to_stdout: true) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, %{"devices" => devices}} ->
            # Find first available iPhone or iPad simulator
            devices
            |> Enum.flat_map(fn {runtime, device_list} ->
              if String.contains?(runtime, "iOS") do
                Enum.map(device_list, fn device ->
                  %{name: device["name"], udid: device["udid"], runtime: runtime}
                end)
              else
                []
              end
            end)
            |> Enum.find(fn d ->
              String.starts_with?(d.name, "iPhone") or String.starts_with?(d.name, "iPad")
            end)
            |> case do
              nil -> nil
              device -> "platform=iOS Simulator,id=#{device.udid}"
            end

          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  @doc """
  Get the path to the built APK for an architecture.
  """
  @spec android_apk_path(Architecture.t()) :: String.t()
  def android_apk_path(arch) do
    flavor = arch_to_gradle_flavor(arch)
    "#{@android_app_dir}/app/build/outputs/apk/#{flavor}/debug/app-#{flavor}-debug.apk"
  end

  @doc """
  Get the path to the built iOS app.
  """
  @spec ios_app_path(Architecture.t()) :: String.t()
  def ios_app_path(arch) do
    config =
      case arch do
        :ios_arm64 -> "Release-iphoneos"
        _ -> "Debug-iphonesimulator"
      end

    "_build/e2e/ios/Build/Products/#{config}/BeamTest.app"
  end
end
