# Performance Limits Guide

This guide explains how to set and manage test time limits in the performance tracking system.

## Overview

The performance tracking system enforces time limits on tests to prevent them from running too long. Limits are configured in `tests/performance_config.yaml` and applied automatically during test execution.

## Types of Limits

### 1. Individual Test Limits (Recommended)

Each test can have its own time limit based on historical performance data. These are the most accurate and recommended approach.

**Location:** `tests/performance_config.yaml` → `limits.tests` section

**Example:**
```yaml
limits:
  tests:
    "test_suites/test_hello_world.py::TestHelloWorldButton::test_button_is_visible": 1
    "test_suites/test_hello_world.py::TestHelloWorldButton::test_button_multiple_clicks": 3
    "test_suites/test_hello_world.py::TestHelloWorldButton::test_message_appears_after_click": 5
```

**How it works:**
- Limits are calculated with **10% buffer** above the maximum observed time
- Each test gets its own personalized timeout
- Tests automatically fail if they exceed their individual limit
- Priority: Individual limit is checked first before other limit types

### 2. Category-Based Limits (Fallback)

For tests without individual limits, category-based limits apply based on test markers:

**Location:** `tests/performance_config.yaml` → `limits` section

```yaml
limits:
  default: 7      # Default timeout for tests without specific markers
  smoke: 10       # Smoke tests must complete quickly
  slow: 60        # Slow tests allowed up to 60 seconds
  version_switch: 120  # Version switch tests allowed up to 2 minutes
```

**How it works:**
- Tests with `@pytest.mark.smoke` → 10s limit
- Tests with `@pytest.mark.slow` → 60s limit
- Tests with `@pytest.mark.version_switch` → 120s limit
- All other tests → 7s default limit

### 3. Suite Limits

Total time allowed for all tests in a test suite:

**Location:** `tests/performance_config.yaml` → `limits.suites` section

```yaml
limits:
  suites:
    TestHelloWorldButton: 9
    TestVersionInformation: 49
    TestSecurityStatus: 90
```

**How it works:**
- Suite limits are calculated with **20% buffer** above max observed suite time
- Used for overall suite performance monitoring
- Not enforced as hard timeouts (individual test limits are enforced)

## Limit Priority

When a test runs, limits are checked in this order:

1. **Individual test limit** (if configured in `limits.tests`)
2. **Marker-based limit** (smoke/slow/version_switch)
3. **Default limit** (7s)

## Setting Limits

### Automatic Calculation (Recommended)

Limits are automatically calculated from historical performance data:

1. **Collect performance data** by running tests multiple times:
   ```bash
   # Run tests 10+ times to collect sufficient data
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
           individual_test_limits[test_id] = int(max_time * 1.1) + 1  # 10% buffer
   
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
           new_suite_limits[suite] = int(max_time * 1.2) + 1  # 20% buffer
   
   # Update config
   config['limits']['tests'] = individual_test_limits
   config['limits']['suites'] = new_suite_limits
   
   with open(config_file, 'w') as f:
       yaml.dump(config, f, default_flow_style=False, sort_keys=False)
   
   print(f"✅ Updated {len(individual_test_limits)} test limits and {len(new_suite_limits)} suite limits")
   PYTHON_SCRIPT
   ```

### Manual Editing

You can manually edit `tests/performance_config.yaml` to set custom limits:

```yaml
limits:
  # Set individual test limit
  tests:
    "test_suites/test_hello_world.py::TestHelloWorldButton::test_button_is_visible": 2
  
  # Set category-based limit
  default: 10
  
  # Set suite limit
  suites:
    TestHelloWorldButton: 15
```

**Note:** When manually editing, ensure test IDs with special characters (like `[` and `]`) are quoted:
```yaml
tests:
  "test_suites/test_security_status.py::TestSecurityStatus::test_vulnerable_versions_show_vulnerable_status[19.0-VULNERABLE]": 8
```

## Viewing Limits

### In Performance Report

Generate the comprehensive HTML report to see all limits:

```bash
make test-performance-report
```

The report shows:
- **Individual limits** in blue/bold text
- **Category-based limits** in normal text
- **Status indicators**: ✅ OK, ⚠️ Near Limit, ❌ Over Limit
- **Color coding**: Red for over limit, yellow for near limit

### Command Line

```bash
# View slowest tests with their limits
make test-performance-slowest LIMIT=20

# View performance summary
make test-performance-summary
```

## How Limits Are Applied

Limits are automatically applied during test execution via the `set_test_timeout` fixture in `tests/conftest.py`:

1. **Check for individual limit** in `performance_config.yaml` → `limits.tests[test_id]`
2. **Check for marker-based limit** (smoke/slow/version_switch)
3. **Apply default limit** if no specific limit found
4. **Test fails** if execution time exceeds the limit

## Best Practices

1. **Collect sufficient data** before setting limits (at least 10 runs per test)
2. **Use individual limits** for accurate timeout enforcement
3. **Review limits periodically** as tests evolve
4. **Set reasonable buffers** (10% for tests, 20% for suites) to allow for normal variation
5. **Monitor performance reports** to identify tests approaching limits

## Troubleshooting

### Test Failing Due to Timeout

If a test is failing because it exceeds its limit:

1. **Check the limit** in the performance report:
   ```bash
   make test-performance-report
   ```

2. **Review test performance**:
   ```bash
   make test-performance-trends TEST_ID="your_test_id"
   ```

3. **Update the limit** if the test legitimately needs more time:
   - Edit `tests/performance_config.yaml`
   - Or collect more data and recalculate limits

### Limit Not Being Applied

If a limit doesn't seem to be applied:

1. **Check test ID format** - Must match exactly (including parameterized values)
2. **Verify YAML syntax** - Test IDs with special characters must be quoted
3. **Check priority** - Individual limits override category-based limits
4. **Review conftest.py** - Ensure `set_test_timeout` fixture is working

### Finding Test ID

To find the exact test ID for setting individual limits:

```bash
# Run tests with verbose output
make test -v

# Or check performance report
make test-performance-report
```

Test IDs follow the format: `test_suites/test_file.py::TestClass::test_method[param]`

## See Also

- [PERFORMANCE_TRACKING.md](PERFORMANCE_TRACKING.md) - Complete performance tracking guide
- [performance_config.yaml](performance_config.yaml) - Configuration file
- [conftest.py](conftest.py) - Limit application implementation
