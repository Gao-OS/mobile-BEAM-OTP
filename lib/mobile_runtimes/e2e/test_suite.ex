defmodule MobileRuntimes.E2E.TestSuite do
  @moduledoc """
  Represents a collection of tests for a specific architecture.

  A test suite aggregates all test cases run on a single platform/architecture
  combination and tracks retry attempts for infrastructure failures.
  """

  alias MobileRuntimes.E2E.{Architecture, TestCase}

  @type status :: :pending | :running | :passed | :failed | :error | :timeout

  @type t :: %__MODULE__{
          id: String.t(),
          architecture: Architecture.t(),
          status: status(),
          tests: [TestCase.t()],
          started_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil,
          total_time_ms: non_neg_integer(),
          retry_count: non_neg_integer()
        }

  @enforce_keys [:id, :architecture]
  defstruct [
    :id,
    :architecture,
    :started_at,
    :completed_at,
    status: :pending,
    tests: [],
    total_time_ms: 0,
    retry_count: 0
  ]

  @max_retries 3

  @doc """
  Creates a new test suite for an architecture.
  """
  @spec new(Architecture.t()) :: t()
  def new(architecture) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    arch_str = Architecture.to_string(architecture) |> String.replace("-", "_")

    %__MODULE__{
      id: "#{arch_str}-#{timestamp}",
      architecture: architecture
    }
  end

  @doc """
  Marks the suite as running and records start time.
  """
  @spec start(t()) :: t()
  def start(%__MODULE__{} = suite) do
    %{suite | status: :running, started_at: DateTime.utc_now()}
  end

  @doc """
  Completes the suite with test results.
  """
  @spec complete(t(), [TestCase.t()]) :: t()
  def complete(%__MODULE__{started_at: started_at} = suite, tests) do
    completed_at = DateTime.utc_now()

    total_time_ms =
      if started_at do
        DateTime.diff(completed_at, started_at, :millisecond)
      else
        Enum.reduce(tests, 0, fn test, acc -> acc + test.time_ms end)
      end

    status = derive_status(tests)

    %{
      suite
      | status: status,
        tests: tests,
        completed_at: completed_at,
        total_time_ms: total_time_ms
    }
  end

  @doc """
  Marks the suite as failed due to timeout.
  """
  @spec timeout(t()) :: t()
  def timeout(%__MODULE__{} = suite) do
    %{suite | status: :timeout, completed_at: DateTime.utc_now()}
  end

  @doc """
  Marks the suite as errored due to infrastructure failure.
  """
  @spec infrastructure_error(t()) :: t()
  def infrastructure_error(%__MODULE__{} = suite) do
    %{suite | status: :error, completed_at: DateTime.utc_now()}
  end

  @doc """
  Increments retry count and resets suite for retry.
  """
  @spec retry(t()) :: {:ok, t()} | {:error, :max_retries_exceeded}
  def retry(%__MODULE__{retry_count: count} = suite) when count < @max_retries do
    {:ok,
     %{
       suite
       | status: :pending,
         retry_count: count + 1,
         started_at: nil,
         completed_at: nil,
         tests: []
     }}
  end

  def retry(_suite), do: {:error, :max_retries_exceeded}

  @doc """
  Returns true if the suite can be retried.
  """
  @spec can_retry?(t()) :: boolean()
  def can_retry?(%__MODULE__{retry_count: count}), do: count < @max_retries

  @doc """
  Returns true if the suite passed all tests.
  """
  @spec passed?(t()) :: boolean()
  def passed?(%__MODULE__{status: :passed}), do: true
  def passed?(_), do: false

  @doc """
  Counts tests by status.
  """
  @spec count_by_status(t()) :: %{passed: integer(), failed: integer(), error: integer(), skipped: integer()}
  def count_by_status(%__MODULE__{tests: tests}) do
    Enum.reduce(tests, %{passed: 0, failed: 0, error: 0, skipped: 0}, fn test, acc ->
      Map.update!(acc, test.status, &(&1 + 1))
    end)
  end

  @doc """
  Parses a test suite from JSON map (from native test app output).
  """
  @spec from_json(map()) :: {:ok, t()} | {:error, term()}
  def from_json(%{"architecture" => arch_str, "status" => status, "tests" => tests_json} = json) do
    with {:ok, arch} <- Architecture.parse(arch_str),
         {:ok, status} <- parse_status(status),
         {:ok, tests} <- parse_tests(tests_json) do
      suite = new(arch)

      {:ok,
       %{
         suite
         | status: status,
           tests: tests,
           total_time_ms: Map.get(json, "total_time_ms", 0)
       }}
    end
  end

  def from_json(_), do: {:error, :invalid_json}

  defp derive_status(tests) do
    cond do
      Enum.any?(tests, &(&1.status == :error)) -> :error
      Enum.any?(tests, &(&1.status == :failed)) -> :failed
      Enum.all?(tests, &(&1.status in [:passed, :skipped])) -> :passed
      true -> :failed
    end
  end

  defp parse_status("pending"), do: {:ok, :pending}
  defp parse_status("running"), do: {:ok, :running}
  defp parse_status("passed"), do: {:ok, :passed}
  defp parse_status("failed"), do: {:ok, :failed}
  defp parse_status("error"), do: {:ok, :error}
  defp parse_status("timeout"), do: {:ok, :timeout}
  defp parse_status(_), do: {:error, :invalid_status}

  defp parse_tests(tests_json) when is_list(tests_json) do
    results =
      Enum.map(tests_json, fn test_json ->
        TestCase.from_json(test_json)
      end)

    if Enum.all?(results, &match?({:ok, _}, &1)) do
      {:ok, Enum.map(results, fn {:ok, test} -> test end)}
    else
      {:error, :invalid_tests}
    end
  end

  defp parse_tests(_), do: {:error, :invalid_tests}
end
