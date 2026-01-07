# Data Model: E2E Runtime Testing

**Feature**: 001-e2e-runtime-testing
**Date**: 2026-01-06

---

## Core Entities

### TestSuite

Represents a collection of tests for a specific architecture.

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| id | string | Unique identifier | Format: `{platform}-{arch}-{timestamp}` |
| architecture | Architecture | Target architecture | Required, one of 6 supported |
| status | SuiteStatus | Current execution status | Required |
| tests | list(TestCase) | Individual test cases | Required, non-empty |
| started_at | datetime | Execution start time | Set on start |
| completed_at | datetime | Execution end time | Set on completion |
| total_time_ms | integer | Total execution time | Calculated |
| retry_count | integer | Number of retry attempts | 0-3 |

### TestCase

Represents a single test within a suite.

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| id | string | Test identifier | Format: `{category}.{name}` |
| category | TestCategory | Test category | Required |
| name | string | Human-readable name | Required |
| status | TestStatus | Test result status | Required |
| time_ms | integer | Execution time in ms | >= 0 |
| error_message | string | Failure details | Present only on failure |
| stdout | string | Test output | Optional |

### TestReport

JUnit XML report aggregating all test results.

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| id | string | Report identifier | Format: `e2e-{timestamp}` |
| generated_at | datetime | Report generation time | Required |
| suites | list(TestSuite) | All test suites | Required |
| total_tests | integer | Sum of all tests | Calculated |
| total_failures | integer | Sum of all failures | Calculated |
| total_errors | integer | Sum of all errors | Calculated |
| total_time_ms | integer | Total execution time | Calculated |

---

## Enumerations

### Architecture

Supported target architectures.

| Value | Platform | Description |
|-------|----------|-------------|
| `android-armeabi-v7a` | Android | 32-bit ARM |
| `android-arm64-v8a` | Android | 64-bit ARM |
| `android-x86_64` | Android | 64-bit Intel (emulator) |
| `ios-arm64` | iOS | 64-bit ARM (devices) |
| `ios-arm64-simulator` | iOS | 64-bit ARM (M1/M2 simulator) |
| `ios-x86_64-simulator` | iOS | 64-bit Intel (simulator) |

### TestCategory

Categories of E2E tests.

| Value | Description | Priority |
|-------|-------------|----------|
| `boot` | BEAM VM initialization | P1 |
| `execution` | Elixir code execution | P1 |
| `nif` | NIF integration tests | P2 |

### SuiteStatus

Test suite execution status.

| Value | Description |
|-------|-------------|
| `pending` | Not yet started |
| `running` | Currently executing |
| `passed` | All tests passed |
| `failed` | One or more tests failed |
| `error` | Infrastructure/execution error |
| `timeout` | Exceeded time limit |

### TestStatus

Individual test result status.

| Value | Description |
|-------|-------------|
| `passed` | Test assertion succeeded |
| `failed` | Test assertion failed |
| `error` | Test execution error |
| `skipped` | Test was skipped |

---

## State Transitions

### TestSuite Lifecycle

```
pending → running → passed
                 → failed
                 → error (infrastructure) → [retry up to 3x] → error
                 → timeout
```

### Retry Flow

```
running → error (infra) → pending (retry 1) → running → ...
                       → pending (retry 2) → running → ...
                       → pending (retry 3) → running → error (final)
```

---

## Relationships

```
TestReport 1──* TestSuite 1──* TestCase
                    │
                    └── Architecture (enum)
                    └── SuiteStatus (enum)
                           │
                           └── TestStatus (enum)
                           └── TestCategory (enum)
```

---

## Validation Rules

### TestSuite
- `architecture` must be one of the 6 supported values
- `tests` must contain at least one TestCase
- `retry_count` must be 0-3
- `total_time_ms` must be < 600000 (10 minutes per spec)

### TestCase
- `category` must be one of: boot, execution, nif
- `time_ms` must be >= 0
- If `status` is `failed` or `error`, `error_message` must be present

### TestReport
- `suites` must cover all requested architectures
- `total_*` fields must match sum of suite values

---

## Example Data

### Successful Test Run

```json
{
  "id": "e2e-20260106-143022",
  "generated_at": "2026-01-06T14:30:22Z",
  "suites": [
    {
      "id": "android-arm64-v8a-20260106-143000",
      "architecture": "android-arm64-v8a",
      "status": "passed",
      "tests": [
        {"id": "boot.vm_initialization", "category": "boot", "status": "passed", "time_ms": 2300},
        {"id": "execution.arithmetic", "category": "execution", "status": "passed", "time_ms": 50},
        {"id": "nif.crypto_sha256", "category": "nif", "status": "passed", "time_ms": 120}
      ],
      "started_at": "2026-01-06T14:30:00Z",
      "completed_at": "2026-01-06T14:30:15Z",
      "total_time_ms": 15000,
      "retry_count": 0
    }
  ],
  "total_tests": 3,
  "total_failures": 0,
  "total_errors": 0,
  "total_time_ms": 15000
}
```

### Failed Test with Retry

```json
{
  "id": "android-x86_64-20260106-143500",
  "architecture": "android-x86_64",
  "status": "passed",
  "retry_count": 1,
  "tests": [
    {"id": "boot.vm_initialization", "category": "boot", "status": "passed", "time_ms": 3100}
  ],
  "started_at": "2026-01-06T14:35:00Z",
  "completed_at": "2026-01-06T14:35:20Z",
  "total_time_ms": 20000
}
```
