defmodule MobileRuntimes.E2E.TestReport do
  @moduledoc """
  Aggregates test results from all architectures into a single report.

  The report is used to generate JUnit XML output for CI visualization.
  """

  alias MobileRuntimes.E2E.TestSuite

  @type t :: %__MODULE__{
          id: String.t(),
          generated_at: DateTime.t(),
          suites: [TestSuite.t()],
          total_tests: non_neg_integer(),
          total_failures: non_neg_integer(),
          total_errors: non_neg_integer(),
          total_time_ms: non_neg_integer()
        }

  @enforce_keys [:id, :generated_at, :suites]
  defstruct [
    :id,
    :generated_at,
    suites: [],
    total_tests: 0,
    total_failures: 0,
    total_errors: 0,
    total_time_ms: 0
  ]

  @doc """
  Creates a new report from completed test suites.
  """
  @spec new([TestSuite.t()]) :: t()
  def new(suites) when is_list(suites) do
    now = DateTime.utc_now()
    timestamp = DateTime.to_unix(now)

    stats = calculate_stats(suites)

    %__MODULE__{
      id: "e2e-#{timestamp}",
      generated_at: now,
      suites: suites,
      total_tests: stats.tests,
      total_failures: stats.failures,
      total_errors: stats.errors,
      total_time_ms: stats.time_ms
    }
  end

  @doc """
  Returns true if all suites passed.
  """
  @spec passed?(t()) :: boolean()
  def passed?(%__MODULE__{total_failures: 0, total_errors: 0}), do: true
  def passed?(_), do: false

  @doc """
  Returns the overall status of the report.
  """
  @spec status(t()) :: :passed | :failed | :error
  def status(%__MODULE__{} = report) do
    cond do
      report.total_errors > 0 -> :error
      report.total_failures > 0 -> :failed
      true -> :passed
    end
  end

  @doc """
  Returns a summary string for console output.
  """
  @spec summary(t()) :: String.t()
  def summary(%__MODULE__{} = report) do
    status_str =
      case status(report) do
        :passed -> "PASSED"
        :failed -> "FAILED"
        :error -> "ERROR"
      end

    time_sec = report.total_time_ms / 1000

    """
    E2E Test Report: #{status_str}
    ──────────────────────────────────
    Suites:   #{length(report.suites)}
    Tests:    #{report.total_tests}
    Failures: #{report.total_failures}
    Errors:   #{report.total_errors}
    Time:     #{Float.round(time_sec, 2)}s
    ──────────────────────────────────
    """
  end

  @doc """
  Adds a completed suite to the report.
  """
  @spec add_suite(t(), TestSuite.t()) :: t()
  def add_suite(%__MODULE__{suites: suites} = report, %TestSuite{} = suite) do
    new_suites = suites ++ [suite]
    stats = calculate_stats(new_suites)

    %{
      report
      | suites: new_suites,
        total_tests: stats.tests,
        total_failures: stats.failures,
        total_errors: stats.errors,
        total_time_ms: stats.time_ms
    }
  end

  defp calculate_stats(suites) do
    Enum.reduce(suites, %{tests: 0, failures: 0, errors: 0, time_ms: 0}, fn suite, acc ->
      counts = TestSuite.count_by_status(suite)

      %{
        tests: acc.tests + length(suite.tests),
        failures: acc.failures + counts.failed,
        errors: acc.errors + counts.error,
        time_ms: acc.time_ms + suite.total_time_ms
      }
    end)
  end
end
