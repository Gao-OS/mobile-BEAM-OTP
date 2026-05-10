defmodule Mix.Tasks.E2e.Run do
  @shortdoc "Run E2E tests on mobile emulators/simulators"

  @moduledoc """
  Runs E2E tests on already-built test applications.

  Use `mix e2e.build` to build test apps first, then use this task to run them.
  For a combined build-and-run workflow, use `mix e2e.test`.

  ## Usage

      # Run tests on specific architecture
      mix e2e.run --arch android-x86_64

      # Run with JUnit XML output
      mix e2e.run --arch android-x86_64 --output-format junit --output results.xml

      # Run on multiple architectures
      mix e2e.run --arch android-x86_64 --arch ios-arm64-simulator

      # Run on all architectures
      mix e2e.run --all

  ## Options

      --all             Run on all supported architectures
      --arch            Target architecture (can be specified multiple times)
      --timeout         Per-suite timeout in milliseconds (default: 300000)
      --output          Output file path (default: _build/e2e/junit.xml)
      --output-format   Output format: text, junit (default: text)
      --retries         Max infrastructure retries (default: 3)
      --verbose         Enable verbose logging
      --keep-alive      Keep emulator/simulator running after tests
      --help            Show this help

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

      0  All tests passed
      1  One or more tests failed
      2  Infrastructure/execution error
      3  Invalid arguments
  """

  use Mix.Task

  alias MobileRuntimes.E2E.{Architecture, JUnitXML, Runner, TestReport}

  @default_timeout 300_000
  @default_output "_build/e2e/junit.xml"
  @default_retries 3

  @impl Mix.Task
  def run(args) do
    case parse_args(args) do
      {:ok, opts} ->
        run_tests(opts)

      {:error, message} ->
        Mix.shell().error(message)
        exit({:shutdown, 3})
    end
  end

  defp parse_args(args) do
    {parsed, _remaining, invalid} =
      OptionParser.parse(args,
        strict: [
          all: :boolean,
          arch: [:string, :keep],
          timeout: :integer,
          output: :string,
          output_format: :string,
          retries: :integer,
          verbose: :boolean,
          keep_alive: :boolean,
          help: :boolean
        ],
        aliases: [h: :help, v: :verbose, a: :all, o: :output, t: :timeout, f: :output_format]
      )

    cond do
      invalid != [] ->
        {key, _} = hd(invalid)
        {:error, "Invalid option: #{key}. Run `mix help e2e.run` for usage."}

      Keyword.get(parsed, :help) ->
        Mix.Task.run("help", ["e2e.run"])
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

    output_format =
      case Keyword.get(parsed, :output_format, "text") do
        "text" -> :text
        "junit" -> :junit
        other -> {:error, "Invalid output format: #{other}. Valid options: text, junit"}
      end

    with {:ok, architectures} <- archs,
         format when is_atom(format) <- output_format do
      {:ok,
       %{
         architectures: architectures,
         timeout: Keyword.get(parsed, :timeout, @default_timeout),
         output: Keyword.get(parsed, :output, @default_output),
         output_format: format,
         retries: Keyword.get(parsed, :retries, @default_retries),
         verbose: Keyword.get(parsed, :verbose, false),
         keep_alive: Keyword.get(parsed, :keep_alive, false)
       }}
    else
      {:error, _} = error -> error
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

  defp run_tests(opts) do
    Mix.shell().info("Running E2E tests for: #{format_arch_list(opts.architectures)}")

    if opts.verbose do
      Logger.configure(level: :debug)
      Mix.shell().info("Options: #{inspect(opts)}")
    end

    case execute_tests(opts) do
      {:ok, report} ->
        # Output results based on format
        output_results(report, opts)

        # Print summary
        Mix.shell().info(TestReport.summary(report))

        # Exit with appropriate code
        case TestReport.status(report) do
          :passed -> exit(:normal)
          :failed -> exit({:shutdown, 1})
          :error -> exit({:shutdown, 2})
        end

      {:error, reason} ->
        formatted = MobileRuntimes.E2E.Retry.format_error(reason)
        Mix.shell().error("E2E test execution failed: #{formatted}")
        exit({:shutdown, 2})
    end
  end

  defp format_arch_list(archs) do
    archs
    |> Enum.map(&format_arch/1)
    |> Enum.join(", ")
  end

  defp execute_tests(opts) do
    runner_opts = [
      timeout: opts.timeout,
      retries: opts.retries,
      skip_build: true,
      verbose: opts.verbose,
      keep_alive: opts.keep_alive
    ]

    case Runner.run(opts.architectures, runner_opts) do
      {:ok, suites} ->
        {:ok, TestReport.new(suites)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp output_results(report, opts) do
    case opts.output_format do
      :junit ->
        # Ensure output directory exists
        output_dir = Path.dirname(opts.output)
        File.mkdir_p!(output_dir)

        :ok = JUnitXML.write_to_file(report, opts.output)
        Mix.shell().info("\nJUnit XML report: #{opts.output}")

      :text ->
        # Text output is handled by the summary
        :ok
    end
  end
end
