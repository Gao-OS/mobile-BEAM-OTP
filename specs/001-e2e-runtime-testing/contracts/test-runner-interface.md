# Contract: Test Runner Interface

**Feature**: 001-e2e-runtime-testing
**Date**: 2026-01-06

---

## Mix Task Interface

### `mix e2e.test`

Primary entry point for E2E test execution.

#### Usage

```bash
# Run tests on all architectures
mix e2e.test --all

# Run tests on specific architectures
mix e2e.test --arch android-arm64-v8a --arch ios-arm64-simulator

# Run with custom timeout
mix e2e.test --arch android-x86_64 --timeout 600000

# Output JUnit XML to specific path
mix e2e.test --all --output _build/test-results/e2e-results.xml

# Skip build step (use cached test apps)
mix e2e.test --arch ios-arm64-simulator --skip-build
```

#### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--all` | flag | false | Run on all supported architectures |
| `--arch` | string (multi) | [] | Target architecture(s) |
| `--timeout` | integer | 300000 | Per-suite timeout in ms |
| `--output` | string | `_build/test-results/junit.xml` | JUnit XML output path |
| `--skip-build` | flag | false | Skip test app build |
| `--retries` | integer | 3 | Max infrastructure retries |

#### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tests passed |
| 1 | One or more tests failed |
| 2 | Infrastructure/execution error |
| 3 | Invalid arguments |

---

## Test App Contract

### Native Test Interface (C/C++)

Both Android and iOS test apps must implement this interface:

```c
/**
 * Initialize BEAM runtime with the given root directory.
 *
 * @param erl_root Path to extracted Erlang runtime
 * @return 0 on success, non-zero on failure
 */
int beam_init(const char* erl_root);

/**
 * Run all test cases and return results.
 *
 * @param results Output buffer for JSON results
 * @param results_size Size of output buffer
 * @return Number of failed tests (0 = all passed)
 */
int beam_run_tests(char* results, size_t results_size);

/**
 * Cleanup BEAM runtime.
 */
void beam_cleanup(void);
```

### Test Result JSON Format

Test apps must output results in this JSON format to stdout:

```json
{
  "architecture": "android-arm64-v8a",
  "status": "passed",
  "tests": [
    {
      "id": "boot.vm_initialization",
      "category": "boot",
      "name": "VM initializes within 30 seconds",
      "status": "passed",
      "time_ms": 2300,
      "stdout": "BEAM scheduler started\nAll subsystems operational"
    },
    {
      "id": "execution.arithmetic",
      "category": "execution",
      "name": "Arithmetic operations work",
      "status": "passed",
      "time_ms": 50,
      "stdout": "1 + 1 = 2"
    },
    {
      "id": "nif.crypto_sha256",
      "category": "nif",
      "name": "Crypto SHA256 produces correct hash",
      "status": "passed",
      "time_ms": 120,
      "stdout": "SHA256(\"test\") = 9f86d08..."
    }
  ],
  "total_time_ms": 2470
}
```

### Exit Code Contract

| Exit Code | Meaning |
|-----------|---------|
| 0 | All tests passed |
| 1 | One or more test assertions failed |
| 2 | BEAM initialization failed |
| 3 | NIF loading failed |
| 124 | Timeout (set by test runner) |

---

## Elixir Module Contracts

### MobileRuntimes.E2E.Runner

```elixir
defmodule MobileRuntimes.E2E.Runner do
  @type architecture :: :android_arm64_v8a | :android_armeabi_v7a | :android_x86_64 |
                        :ios_arm64 | :ios_arm64_simulator | :ios_x86_64_simulator

  @type test_result :: %{
    id: String.t(),
    category: :boot | :execution | :nif,
    name: String.t(),
    status: :passed | :failed | :error | :skipped,
    time_ms: non_neg_integer(),
    error_message: String.t() | nil,
    stdout: String.t() | nil
  }

  @type suite_result :: %{
    architecture: architecture(),
    status: :passed | :failed | :error | :timeout,
    tests: [test_result()],
    total_time_ms: non_neg_integer(),
    retry_count: non_neg_integer()
  }

  @doc """
  Run E2E tests on specified architectures.

  ## Options
    * `:timeout` - Per-suite timeout in ms (default: 300_000)
    * `:retries` - Max infrastructure retries (default: 3)
    * `:skip_build` - Skip test app build (default: false)

  ## Returns
    * `{:ok, [suite_result()]}` - All suites completed (may include failures)
    * `{:error, reason}` - Fatal error preventing test execution
  """
  @spec run([architecture()], keyword()) :: {:ok, [suite_result()]} | {:error, term()}
  def run(architectures, opts \\ [])
end
```

### MobileRuntimes.E2E.JUnitXML

```elixir
defmodule MobileRuntimes.E2E.JUnitXML do
  @doc """
  Generate JUnit XML report from test results.

  ## Returns
    * XML string conforming to JUnit schema
  """
  @spec generate([MobileRuntimes.E2E.Runner.suite_result()]) :: String.t()
  def generate(results)

  @doc """
  Write JUnit XML report to file.
  """
  @spec write_to_file([MobileRuntimes.E2E.Runner.suite_result()], Path.t()) :: :ok | {:error, term()}
  def write_to_file(results, path)
end
```

### MobileRuntimes.E2E.Emulator

```elixir
defmodule MobileRuntimes.E2E.Emulator do
  @doc """
  Start an emulator/simulator for the given architecture.

  ## Returns
    * `{:ok, emulator_id}` - Emulator started successfully
    * `{:error, :not_available}` - Emulator not available for architecture
    * `{:error, reason}` - Failed to start
  """
  @spec start(MobileRuntimes.E2E.Runner.architecture()) :: {:ok, String.t()} | {:error, term()}
  def start(architecture)

  @doc """
  Stop an emulator/simulator.
  """
  @spec stop(String.t()) :: :ok | {:error, term()}
  def stop(emulator_id)

  @doc """
  Install test app on emulator/simulator.
  """
  @spec install(String.t(), Path.t()) :: :ok | {:error, term()}
  def install(emulator_id, app_path)

  @doc """
  Run test app and capture output.

  ## Returns
    * `{:ok, output, exit_code}` - App completed
    * `{:error, :timeout}` - Exceeded timeout
    * `{:error, reason}` - Execution failed
  """
  @spec run_app(String.t(), keyword()) :: {:ok, String.t(), integer()} | {:error, term()}
  def run_app(emulator_id, opts \\ [])
end
```

---

## GitHub Actions Workflow Contract

### Inputs

```yaml
inputs:
  architectures:
    description: 'Comma-separated list of architectures to test'
    required: false
    default: 'android-x86_64,ios-arm64-simulator'
  timeout:
    description: 'Per-suite timeout in seconds'
    required: false
    default: '300'
```

### Outputs

```yaml
outputs:
  result:
    description: 'Overall test result (passed/failed/error)'
  report_path:
    description: 'Path to JUnit XML report artifact'
  failures:
    description: 'Number of failed tests'
```

### Artifacts

| Name | Path | Description |
|------|------|-------------|
| `e2e-test-results` | `_build/test-results/` | JUnit XML reports |
| `e2e-test-logs` | `_build/test-logs/` | Emulator/simulator logs |
