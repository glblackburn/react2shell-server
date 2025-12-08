# Performance Tracking and Historical Analysis

This document explains how to use the performance tracking system to monitor test execution times, detect regressions, and analyze trends over time.

## Overview

The performance tracking system:
- **Tracks execution times** for all tests automatically
- **Stores historical data** in timestamped files
- **Compares against baselines** to detect regressions
- **Provides trend analysis** to identify performance changes over time

## Quick Start

### 1. Collect Performance Data

Run tests to collect performance metrics (history is saved automatically):

```bash
make test-smoke        # Quick - runs smoke tests
make test-parallel     # Comprehensive - runs all tests
make test             # Runs all tests sequentially
```

Each test run automatically saves performance data to `tests/.performance_history/`.

### 2. Generate Performance Report

Generate and view a comprehensive HTML performance report:

```bash
make test-performance-report
```

This generates an HTML report with:
- Recent test runs summary
- Suite performance trends with limits
- Slowest tests with individual limits
- Performance trends over time
- Baseline comparison

The report automatically opens in your browser.

### 3. Update Baseline (Optional)

Before tracking performance regressions, establish a baseline:

```bash
make test-update-baseline
```

This runs all tests and saves their execution times as the baseline for future comparisons.

### 4. View Performance Data (Command Line)

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

- **`make test-performance-report`** - **Generate and open comprehensive HTML performance report** (recommended)
  - Includes all metrics, trends, limits, and comparisons
  - Automatically opens in browser
  - Shows individual test limits vs category-based limits
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

## Setting Test Time Limits

Test time limits are configured in `tests/performance_config.yaml`. There are three types of limits:

### 1. Individual Test Limits (Recommended)

Each test can have its own time limit based on historical performance data. These are stored under `limits.tests`:

```yaml
limits:
  tests:
    "test_suites/test_hello_world.py::TestHelloWorldButton::test_button_is_visible": 1
    "test_suites/test_hello_world.py::TestHelloWorldButton::test_button_multiple_clicks": 3
    "test_suites/test_hello_world.py::TestHelloWorldButton::test_message_appears_after_click": 5
```

**How individual limits are applied:**
- Priority: Individual test limit → Marker-based limit → Default limit
- Tests automatically fail if they exceed their individual limit
- Limits are calculated with 10% buffer above max observed time

**To update individual limits:**
1. Collect performance data by running tests multiple times (at least 10 runs recommended)
2. Run the limit calculation script (see "Updating Limits" section below)

### 2. Category-Based Limits (Fallback)

For tests without individual limits, category-based limits apply:

```yaml
limits:
  default: 7      # Default timeout for tests without specific markers
  smoke: 10       # Smoke tests must complete quickly
  slow: 60        # Slow tests allowed up to 60 seconds
  version_switch: 120  # Version switch tests allowed up to 2 minutes
```

### 3. Suite Limits

Total time allowed for all tests in a test suite:

```yaml
limits:
  suites:
    TestHelloWorldButton: 9
    TestVersionInformation: 49
    TestSecurityStatus: 90
```

Suite limits are calculated with 20% buffer above max observed suite time.

## Updating Limits

Limits are automatically calculated based on historical performance data. To update limits:

1. **Collect sufficient data** (at least 10 runs per test):
   ```bash
   # Run tests multiple times to collect data
   for i in {1..12}; do make test-smoke; done
   ```

2. **Calculate and update limits**:
   ```bash
   cd tests
   ../venv/bin/python3 << 'PYTHON_SCRIPT'
   import yaml
   from pathlib import Path
   from utils.performance_history import load_history_files
   
   config_file = Path('performance_config.yaml')
   with open(config_file, 'r') as f:
       config = yaml.safe_load(f) or {}
   
   history = load_history_files(limit=100)
   
   # Calculate individual test limits (10% buffer)
   test_max_times = {}
   for run in history:
       for test_id, test_data in run.get('tests', {}).items():
           if test_id not in test_max_times:
               test_max_times[test_id] = []
           test_max_times[test_id].append(test_data.get('max', test_data.get('avg', 0)))
   
   individual_test_limits = {}
   for test_id, times in test_max_times.items():
       if times:
           max_time = max(times)
           individual_test_limits[test_id] = int(max_time * 1.1) + 1
   
   # Calculate suite limits (20% buffer)
   suite_max_times = {}
   for run in history:
       for suite, time in run.get('suites', {}).items():
           if suite not in suite_max_times:
               suite_max_times[suite] = []
           suite_max_times[suite].append(time)
   
   new_suite_limits = {}
   for suite, times in suite_max_times.items():
       if times:
           max_time = max(times)
           new_suite_limits[suite] = int(max_time * 1.2) + 1
   
   # Update config
   config['limits']['tests'] = individual_test_limits
   config['limits']['suites'] = new_suite_limits
   
   with open(config_file, 'w') as f:
       yaml.dump(config, f, default_flow_style=False, sort_keys=False)
   
   print(f"✅ Updated {len(individual_test_limits)} test limits and {len(new_suite_limits)} suite limits")
   PYTHON_SCRIPT
   ```

**Manual limit editing:**
You can also manually edit `tests/performance_config.yaml` to set custom limits for specific tests or suites.

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

## Generating Performance Reports

### HTML Performance Report

The easiest way to view all performance metrics is to generate the comprehensive HTML report:

```bash
make test-performance-report
```

This command:
1. Loads all performance history from `tests/.performance_history/`
2. Generates an HTML report with:
   - Recent test runs summary
   - Suite performance trends with limits and status indicators
   - Slowest tests with individual limits highlighted
   - Performance trends over time
   - Baseline comparison with regressions
3. Saves the report to `tests/reports/performance_history_report.html`
4. Automatically opens the report in your browser

**Report Features:**
- **Individual test limits** shown in blue/bold (calculated from historical data)
- **Category-based limits** shown in normal text (fallback for tests without individual limits)
- **Status indicators**: ✅ OK, ⚠️ Near Limit, ❌ Over Limit
- **Color coding**: Red background for tests over limit, yellow for near limit
- **Trend arrows**: Shows if performance is improving (↓) or degrading (↑)

### Command Line Reports

For quick command-line analysis:

```bash
# Summary of recent runs
make test-performance-summary

# Compare against baseline
make test-performance-compare

# View trends
make test-performance-trends
```

## See Also

- `tests/PERFORMANCE_METRICS_DESIGN.md` - Design document for performance tracking
- `tests/performance_config.yaml` - Configuration file (where limits are set)
- `tests/conftest.py` - Performance tracking implementation
- `tests/generate_performance_report.sh` - Report generation script
