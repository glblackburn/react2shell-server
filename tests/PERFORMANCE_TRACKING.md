# Performance Tracking and Historical Analysis

This document explains how to use the performance tracking system to monitor test execution times, detect regressions, and analyze trends over time.

## Overview

The performance tracking system:
- **Tracks execution times** for all tests automatically
- **Stores historical data** in timestamped files
- **Compares against baselines** to detect regressions
- **Provides trend analysis** to identify performance changes over time

## Quick Start

### 1. Update Baseline (First Time)

Before tracking performance, establish a baseline:

```bash
make test-update-baseline
```

This runs all tests and saves their execution times as the baseline for future comparisons.

### 2. Run Tests (History is Saved Automatically)

When you run tests, performance data is automatically saved to history:

```bash
make test-parallel        # Saves history automatically
make test                 # Saves history automatically
make test-performance-check  # Explicitly saves history
```

### 3. View Performance Data

```bash
# Compare latest run against baseline
make test-performance-compare

# View trends for all tests
make test-performance-trends

# View trends for a specific test
make test-performance-trends TEST_ID="test_suites/test_hello_world.py::TestHelloWorldButton::test_button_is_visible"

# List slowest tests
make test-performance-slowest LIMIT=20

# View recent history
make test-performance-history LIMIT=10

# Get summary of recent runs
make test-performance-summary LIMIT=5
```

## Commands Reference

### Baseline Management

- **`make test-update-baseline`** - Update the performance baseline with current test times
- **`make test-performance-check`** - Run tests and check for regressions (saves history)

### Performance Analysis

- **`make test-performance-compare`** - Compare the latest test run against the baseline
- **`make test-performance-trends [TEST_ID=...] [LIMIT=N]`** - Show performance trends
  - `TEST_ID`: Optional specific test to analyze
  - `LIMIT`: Number of historical runs to analyze (default: 10)
- **`make test-performance-slowest [LIMIT=N]`** - List the slowest tests (default: 10)
- **`make test-performance-history [LIMIT=N]`** - List recent performance history (default: 10)
- **`make test-performance-summary [LIMIT=N]`** - Show summary of recent runs (default: 5)

### Direct Python Script Usage

You can also use the performance report script directly:

```bash
cd tests
venv/bin/python3 performance_report.py [command] [options]
```

Commands:
- `trends [test_id]` - Show performance trends
- `compare` - Compare latest run against baseline
- `slowest [--limit N]` - List slowest tests
- `history [--limit N]` - List recent history
- `summary [--limit N]` - Show summary

## Understanding the Output

### Performance Report (After Test Runs)

After running tests, you'll see a performance report like:

```
======================================================================
PERFORMANCE REPORT
======================================================================

❌ Performance Regressions Detected (>50% slower):
  test_suites/test_security_status.py::TestSecurityStatus::test_react_version_matches_status
    Current: 8.45s
    Baseline: 5.23s
    Slower by: 3.22s (61.6%)

⚠️  Performance Warnings (>20% slower):
  test_suites/test_hello_world.py::TestHelloWorldButton::test_button_click_displays_message
    Current: 1.25s
    Baseline: 1.01s
    Slower by: 0.24s (23.8%)

📊 Suite Execution Times:
  TestSecurityStatus: 45.23s
  TestHelloWorldButton: 12.45s
  TestVersionInformation: 8.92s
```

### Trend Report

Trend reports show how test performance changes over time:

```
================================================================================
PERFORMANCE TREND REPORT
================================================================================
Analyzing 10 historical runs
Most recent run: 2025-12-08T05:48:39
Oldest run: 2025-12-07T22:00:15

Test: test_suites/test_hello_world.py::TestHelloWorldButton::test_button_is_visible
--------------------------------------------------------------------------------
Run                  Avg (s)      Min (s)      Max (s)      Change      
--------------------------------------------------------------------------------
2025-12-08T05-48-39  0.059         0.055         0.062         +2.1%
2025-12-08T04-30-12  0.058         0.056         0.060         -1.7%
2025-12-08T03-15-45  0.059         0.057         0.061         +1.7%
...

Overall trend: +0.5% (slower)
```

### Comparison Report

Comparison reports show how the latest run compares to the baseline:

```
================================================================================
PERFORMANCE COMPARISON: Latest Run vs Baseline
================================================================================
Total tests: 58
New tests: 2
Improved: 5
Regressed (>50% slower): 1

❌ Performance Regressions (>50% slower):
  test_suites/test_security_status.py::TestSecurityStatus::test_react_version_matches_status
    Current: 8.45s
    Baseline: 5.23s
    Slower by: 61.6%

✓ Performance Improvements:
  test_suites/test_hello_world.py::TestHelloWorldButton::test_button_text_is_correct: 12.3% faster
  ...
```

## Data Storage

### Baseline File

- **Location**: `tests/.performance_baseline.json`
- **Format**: JSON with test IDs as keys, containing `avg`, `min`, `max`, `runs`
- **Purpose**: Reference point for regression detection
- **Update**: Run `make test-update-baseline` to update

### History Files

- **Location**: `tests/.performance_history/`
- **Format**: Timestamped JSON files (`run_YYYY-MM-DDTHH-MM-SS.json`)
- **Purpose**: Historical record of all test runs
- **Update**: Automatically saved on each test run (when `PYTEST_SAVE_HISTORY=true`)

### Configuration

- **Location**: `tests/performance_config.yaml`
- **Purpose**: Configure thresholds, limits, and reporting options

## Best Practices

1. **Establish Baseline Early**: Run `make test-update-baseline` after initial test suite is stable
2. **Regular Monitoring**: Check `make test-performance-compare` after significant changes
3. **Investigate Regressions**: When regressions are detected, investigate the cause
4. **Update Baseline**: Periodically update baseline as tests evolve (but only when performance is acceptable)
5. **Review Trends**: Use `make test-performance-trends` to identify gradual performance degradation

## Troubleshooting

### No History Found

If you see "No performance history found":
- Ensure tests have been run with history saving enabled
- Check that `tests/.performance_history/` directory exists
- Verify `PYTEST_SAVE_HISTORY=true` is set (automatic in `make test-parallel`)

### No Baseline Found

If you see "No baseline found":
- Run `make test-update-baseline` to create a baseline
- Check that `tests/.performance_baseline.json` exists

### Performance Data Not Showing

If performance reports aren't appearing:
- Ensure you're running tests (not just collecting)
- Check that tests are completing successfully
- Verify performance tracking is enabled in `conftest.py`

## Integration with CI/CD

For CI/CD pipelines:

```bash
# Run tests and save history
make test-parallel

# Check for regressions (fails if regressions found and fail_on_regression=true)
make test-performance-check

# Generate trend report
make test-performance-summary > performance_summary.txt
```

You can configure `performance_config.yaml` to fail tests on regressions:

```yaml
regression:
  fail_on_regression: true  # Fail tests if regressions detected
```

## Advanced Usage

### Analyzing Specific Test

```bash
# Get trends for a specific test
make test-performance-trends TEST_ID="test_suites/test_hello_world.py::TestHelloWorldButton::test_button_is_visible" LIMIT=20
```

### Custom Analysis Script

You can write custom scripts using the `performance_history` module:

```python
from utils.performance_history import load_history_files, get_test_trends

# Load recent history
history = load_history_files(limit=10)

# Get trends for a test
trends = get_test_trends("test_suites/test_hello_world.py::TestHelloWorldButton::test_button_is_visible", limit=10)
```

## See Also

- `tests/PERFORMANCE_METRICS_DESIGN.md` - Design document for performance tracking
- `tests/performance_config.yaml` - Configuration file
- `tests/conftest.py` - Performance tracking implementation
