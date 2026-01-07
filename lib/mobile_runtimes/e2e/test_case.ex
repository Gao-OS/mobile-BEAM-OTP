defmodule MobileRuntimes.E2E.TestCase do
  @moduledoc """
  Represents a single test within an E2E test suite.

  Each test case validates a specific aspect of BEAM runtime functionality:
  - `:boot` - BEAM VM initialization
  - `:execution` - Elixir code execution
  - `:nif` - NIF integration (crypto, exqlite)
  """

  @type category :: :boot | :execution | :nif

  @type status :: :passed | :failed | :error | :skipped

  @type t :: %__MODULE__{
          id: String.t(),
          category: category(),
          name: String.t(),
          status: status(),
          time_ms: non_neg_integer(),
          error_message: String.t() | nil,
          stdout: String.t() | nil
        }

  @enforce_keys [:id, :category, :name, :status]
  defstruct [
    :id,
    :category,
    :name,
    :status,
    :error_message,
    :stdout,
    time_ms: 0
  ]

  @doc """
  Creates a new test case.

  ## Examples

      iex> MobileRuntimes.E2E.TestCase.new("boot.vm_init", :boot, "VM initializes successfully")
      %MobileRuntimes.E2E.TestCase{
        id: "boot.vm_init",
        category: :boot,
        name: "VM initializes successfully",
        status: :pending
      }
  """
  @spec new(String.t(), category(), String.t()) :: t()
  def new(id, category, name) when category in [:boot, :execution, :nif] do
    %__MODULE__{
      id: id,
      category: category,
      name: name,
      status: :skipped
    }
  end

  @doc """
  Marks a test case as passed with execution time.
  """
  @spec passed(t(), non_neg_integer(), String.t() | nil) :: t()
  def passed(%__MODULE__{} = test_case, time_ms, stdout \\ nil) do
    %{test_case | status: :passed, time_ms: time_ms, stdout: stdout}
  end

  @doc """
  Marks a test case as failed with error message.
  """
  @spec failed(t(), non_neg_integer(), String.t(), String.t() | nil) :: t()
  def failed(%__MODULE__{} = test_case, time_ms, error_message, stdout \\ nil) do
    %{test_case | status: :failed, time_ms: time_ms, error_message: error_message, stdout: stdout}
  end

  @doc """
  Marks a test case as errored (execution error, not assertion failure).
  """
  @spec error(t(), non_neg_integer(), String.t()) :: t()
  def error(%__MODULE__{} = test_case, time_ms, error_message) do
    %{test_case | status: :error, time_ms: time_ms, error_message: error_message}
  end

  @doc """
  Returns true if the test case passed.
  """
  @spec passed?(t()) :: boolean()
  def passed?(%__MODULE__{status: :passed}), do: true
  def passed?(_), do: false

  @doc """
  Parses a test case from JSON map (from native test app output).
  """
  @spec from_json(map()) :: {:ok, t()} | {:error, term()}
  def from_json(%{"id" => id, "category" => category, "name" => name, "status" => status} = json) do
    with {:ok, cat} <- parse_category(category),
         {:ok, stat} <- parse_status(status) do
      {:ok,
       %__MODULE__{
         id: id,
         category: cat,
         name: name,
         status: stat,
         time_ms: Map.get(json, "time_ms", 0),
         error_message: Map.get(json, "error_message"),
         stdout: Map.get(json, "stdout")
       }}
    end
  end

  def from_json(_), do: {:error, :invalid_json}

  defp parse_category("boot"), do: {:ok, :boot}
  defp parse_category("execution"), do: {:ok, :execution}
  defp parse_category("nif"), do: {:ok, :nif}
  defp parse_category(_), do: {:error, :invalid_category}

  defp parse_status("passed"), do: {:ok, :passed}
  defp parse_status("failed"), do: {:ok, :failed}
  defp parse_status("error"), do: {:ok, :error}
  defp parse_status("skipped"), do: {:ok, :skipped}
  defp parse_status(_), do: {:error, :invalid_status}
end
