defmodule MobileRuntimes.E2E.Retry do
  @moduledoc """
  Retry helper with exponential backoff for infrastructure operations.

  Used to handle transient failures in emulator startup, app installation,
  and test execution. Only infrastructure errors trigger retries, not test
  assertion failures.
  """

  require Logger

  @default_max_retries 3
  @default_initial_delay_ms 1000
  @default_max_delay_ms 30_000

  @type retry_opts :: [
          max_retries: non_neg_integer(),
          initial_delay_ms: non_neg_integer(),
          max_delay_ms: non_neg_integer(),
          on_retry: (integer(), term() -> :ok)
        ]

  @doc """
  Executes a function with retry on infrastructure failure.

  The function should return:
  - `{:ok, result}` - Success, no retry needed
  - `{:error, :infrastructure, reason}` - Infrastructure failure, retry
  - `{:error, reason}` - Non-retriable error

  ## Options

  - `:max_retries` - Maximum retry attempts (default: 3)
  - `:initial_delay_ms` - Initial delay before first retry (default: 1000)
  - `:max_delay_ms` - Maximum delay cap (default: 30000)
  - `:on_retry` - Callback `fn attempt, reason -> :ok end`

  ## Examples

      iex> MobileRuntimes.E2E.Retry.with_retry(fn -> {:ok, :success} end)
      {:ok, :success}

      iex> MobileRuntimes.E2E.Retry.with_retry(fn -> {:error, :infrastructure, :timeout} end)
      {:error, :max_retries_exceeded, :timeout}
  """
  @spec with_retry(
          (-> {:ok, term()} | {:error, term()} | {:error, :infrastructure, term()}),
          retry_opts()
        ) ::
          {:ok, term()} | {:error, term()} | {:error, :max_retries_exceeded, term()}
  def with_retry(fun, opts \\ []) when is_function(fun, 0) do
    max_retries = Keyword.get(opts, :max_retries, @default_max_retries)
    initial_delay = Keyword.get(opts, :initial_delay_ms, @default_initial_delay_ms)
    max_delay = Keyword.get(opts, :max_delay_ms, @default_max_delay_ms)
    on_retry = Keyword.get(opts, :on_retry, fn _, _ -> :ok end)

    do_retry(fun, 0, max_retries, initial_delay, max_delay, on_retry, nil)
  end

  defp do_retry(fun, attempt, max_retries, initial_delay, max_delay, on_retry, _last_reason) do
    case fun.() do
      {:ok, result} ->
        {:ok, result}

      {:error, :infrastructure, reason} when attempt < max_retries ->
        delay = calculate_delay(attempt, initial_delay, max_delay)
        on_retry.(attempt + 1, reason)

        Logger.info(
          "Retry attempt #{attempt + 1}/#{max_retries} after #{delay}ms: #{inspect(reason)}"
        )

        Process.sleep(delay)
        do_retry(fun, attempt + 1, max_retries, initial_delay, max_delay, on_retry, reason)

      {:error, :infrastructure, reason} ->
        {:error, :max_retries_exceeded, reason}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Calculates exponential backoff delay with jitter.

  Formula: min(initial * 2^attempt + jitter, max_delay)
  """
  @spec calculate_delay(non_neg_integer(), non_neg_integer(), non_neg_integer()) ::
          non_neg_integer()
  def calculate_delay(attempt, initial_delay, max_delay) do
    base = (initial_delay * :math.pow(2, attempt)) |> round()
    jitter = :rand.uniform(div(initial_delay, 2))
    min(base + jitter, max_delay)
  end

  @doc """
  Wraps a function result to indicate infrastructure failure.

  Use this when an operation fails due to external factors (emulator crash,
  network timeout) rather than the test itself.
  """
  @spec infrastructure_error(term()) :: {:error, :infrastructure, term()}
  def infrastructure_error(reason) do
    {:error, :infrastructure, reason}
  end

  @doc """
  Classifies an error and returns appropriate retry behavior.

  Returns `{:retry, classified_reason}` for retriable errors,
  or `{:no_retry, reason}` for non-retriable errors.
  """
  @spec classify_error(term()) :: {:retry, term()} | {:no_retry, term()}
  def classify_error(reason) do
    case reason do
      # Infrastructure errors - should retry
      :emulator_timeout ->
        {:retry, :emulator_timeout}

      :emulator_crash ->
        {:retry, :emulator_crash}

      :simulator_timeout ->
        {:retry, :simulator_timeout}

      :simulator_crash ->
        {:retry, :simulator_crash}

      :adb_connection_failed ->
        {:retry, :adb_connection_failed}

      :xcrun_failed ->
        {:retry, :xcrun_failed}

      {:install_failed, _} ->
        {:retry, reason}

      {:app_start_failed, _} ->
        {:retry, reason}

      :connection_refused ->
        {:retry, :connection_refused}

      :network_timeout ->
        {:retry, :network_timeout}

      # Non-retriable errors
      :out_of_memory ->
        {:no_retry, {:fatal, :out_of_memory, "System ran out of memory"}}

      :architecture_mismatch ->
        {:no_retry, {:fatal, :architecture_mismatch, "App built for wrong architecture"}}

      :invalid_architecture ->
        {:no_retry, {:config, :invalid_architecture, "Invalid architecture specified"}}

      :test_app_not_found ->
        {:no_retry, {:config, :test_app_not_found, "Test app not built. Run mix e2e.build first"}}

      :ndk_not_found ->
        {:no_retry, {:config, :ndk_not_found, "Android NDK not found. Set ANDROID_NDK_HOME"}}

      :xcode_not_found ->
        {:no_retry,
         {:config, :xcode_not_found, "Xcode not found. Install Xcode and command line tools"}}

      {:test_failed, _} ->
        {:no_retry, reason}

      # Unknown errors - don't retry by default
      _ ->
        {:no_retry, reason}
    end
  end

  @doc """
  Formats an error for user-friendly display.
  """
  @spec format_error(term()) :: String.t()
  def format_error(reason) do
    case reason do
      {:fatal, type, message} -> "[FATAL] #{type}: #{message}"
      {:config, type, message} -> "[CONFIG] #{type}: #{message}"
      {:test_failed, details} -> "[TEST] Test failed: #{inspect(details)}"
      :emulator_timeout -> "[INFRA] Android emulator timed out"
      :emulator_crash -> "[INFRA] Android emulator crashed"
      :simulator_timeout -> "[INFRA] iOS simulator timed out"
      :simulator_crash -> "[INFRA] iOS simulator crashed"
      :max_retries_exceeded -> "[INFRA] Maximum retries exceeded"
      other -> "[ERROR] #{inspect(other)}"
    end
  end
end
