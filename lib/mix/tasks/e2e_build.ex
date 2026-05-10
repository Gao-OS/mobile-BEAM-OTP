defmodule Mix.Tasks.E2e.Build do
  @shortdoc "Build E2E test apps for mobile platforms"

  @moduledoc """
  Builds E2E test applications for specified mobile architectures.

  ## Usage

      # Build for specific architecture
      mix e2e.build --arch android-x86_64
      mix e2e.build --arch ios-arm64-simulator

      # Build for all architectures
      mix e2e.build --all

      # Build for multiple architectures
      mix e2e.build --arch android-x86_64 --arch ios-arm64-simulator

  ## Options

      --all           Build for all supported architectures
      --arch          Target architecture (can be specified multiple times)
      --verbose       Enable verbose logging
      --help          Show this help

  ## Supported Architectures

      Android:
        - android-armeabi-v7a  (32-bit ARM)
        - android-arm64-v8a    (64-bit ARM)
        - android-x86_64       (64-bit Intel, emulator)

      iOS:
        - ios-arm64            (64-bit ARM, devices)
        - ios-arm64-simulator  (64-bit ARM, M1/M2 simulator)
        - ios-x86_64-simulator (64-bit Intel, simulator)

  ## Exit Codes

      0  Build succeeded
      1  Build failed
      2  Invalid arguments
  """

  use Mix.Task

  alias MobileRuntimes.E2E.{Architecture, Builder}

  @impl Mix.Task
  def run(args) do
    case parse_args(args) do
      {:ok, opts} ->
        build_apps(opts)

      {:error, message} ->
        Mix.shell().error(message)
        exit({:shutdown, 2})
    end
  end

  defp parse_args(args) do
    {parsed, _remaining, invalid} =
      OptionParser.parse(args,
        strict: [
          all: :boolean,
          arch: [:string, :keep],
          verbose: :boolean,
          help: :boolean
        ],
        aliases: [h: :help, v: :verbose, a: :all]
      )

    cond do
      invalid != [] ->
        {key, _} = hd(invalid)
        {:error, "Invalid option: #{key}. Run `mix help e2e.build` for usage."}

      Keyword.get(parsed, :help) ->
        Mix.Task.run("help", ["e2e.build"])
        exit(:normal)

      true ->
        build_opts(parsed)
    end
  end

  defp build_opts(parsed) do
    archs =
      cond do
        Keyword.get(parsed, :all) ->
          {:ok, Architecture.all()}

        Keyword.has_key?(parsed, :arch) ->
          parse_architectures(Keyword.get_values(parsed, :arch))

        true ->
          {:error, "No architecture specified. Use --arch or --all."}
      end

    case archs do
      {:ok, architectures} ->
        {:ok,
         %{
           architectures: architectures,
           verbose: Keyword.get(parsed, :verbose, false)
         }}

      {:error, _} = error ->
        error
    end
  end

  defp parse_architectures(arch_strings) do
    results = Enum.map(arch_strings, &Architecture.parse/1)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil ->
        {:ok, Enum.map(results, fn {:ok, arch} -> arch end)}

      {:error, :invalid_architecture} ->
        valid = Architecture.all() |> Enum.map(&format_arch/1) |> Enum.join(", ")

        bad =
          Enum.find(arch_strings, fn s ->
            Architecture.parse(s) == {:error, :invalid_architecture}
          end)

        {:error, "Invalid architecture: #{bad}. Valid options: #{valid}"}
    end
  end

  defp format_arch(arch) do
    arch
    |> Atom.to_string()
    |> String.replace("_", "-")
  end

  defp build_apps(opts) do
    Mix.shell().info("Building E2E test apps for: #{format_arch_list(opts.architectures)}")

    if opts.verbose do
      Logger.configure(level: :debug)
    end

    # Group by platform
    android_archs = Enum.filter(opts.architectures, &(Architecture.platform(&1) == :android))
    ios_archs = Enum.filter(opts.architectures, &(Architecture.platform(&1) == :ios))

    with :ok <- build_platform(:android, android_archs),
         :ok <- build_platform(:ios, ios_archs) do
      Mix.shell().info("\nBuild completed successfully!")
      exit(:normal)
    else
      {:error, reason} ->
        Mix.shell().error("\nBuild failed: #{inspect(reason)}")
        exit({:shutdown, 1})
    end
  end

  defp build_platform(_platform, []), do: :ok

  defp build_platform(:android, archs) do
    Mix.shell().info("Building Android test app...")
    Builder.build_android(archs)
  end

  defp build_platform(:ios, archs) do
    Mix.shell().info("Building iOS test app...")
    Builder.build_ios(archs)
  end

  defp format_arch_list(archs) do
    archs
    |> Enum.map(&format_arch/1)
    |> Enum.join(", ")
  end
end
