# Performance Metrics and Time Limits - Design Document

## Current State

### What We Have
- ✅ `pytest-timeout` installed (v2.2.0+) - Global 300s timeout configured
- ✅ `slow` marker defined for slow tests
- ✅ Basic pytest hooks for screenshots
- ✅ Test execution times visible in pytest output

### What's Missing
- ❌ Per-test time limits (only global timeout exists)
- ❌ Per-suite time limits
- ❌ Performance baseline tracking
- ❌ Automatic detection of tests running slower than expected
- ❌ Performance regression detection
- ❌ Historical performance data

## Design Options

### Option 1: pytest-timeout (Already Installed) - Per-Test Timeouts

**How it works:**
- Set timeouts at test, class, or module level
- Tests fail if they exceed the timeout
- Can use decorators, markers, or config

**Implementation:**
```python
# Per-test timeout
@pytest.mark.timeout(30)  # 30 seconds
def test_something():
    pass

# Per-class timeout
@pytest.mark.timeout(120)  # 2 minutes for entire class
class TestSecurityStatus:
    pass

# Via pytest.ini
[pytest]
timeout = 300  # Global default
timeout_method = thread  # or signal
```

**Pros:**
- ✅ Already installed
- ✅ Simple to use
- ✅ Fails fast on slow tests
- ✅ Can be set per test/class/module

**Cons:**
- ❌ No historical tracking
- ❌ No baseline comparison
- ❌ No warnings (only hard failures)
- ❌ No suite-level aggregation

---

### Option 2: pytest-benchmark (New Plugin)

**What it does:**
- Measures and tracks execution times
- Compares against historical baselines
- Detects performance regressions
- Generates performance reports

**Installation:**
```bash
pip install pytest-benchmark
```

**Usage:**
```python
def test_something(benchmark):
    result = benchmark(some_function)
    # Automatically tracks execution time
```

**Pros:**
- ✅ Historical tracking
- ✅ Baseline comparison
- ✅ Regression detection
- ✅ Statistical analysis (min/max/mean/stddev)
- ✅ JSON/CSV export

**Cons:**
- ❌ Requires code changes (benchmark fixture)
- ❌ More complex setup
- ❌ Designed for micro-benchmarks, not E2E tests
- ❌ May not work well with Selenium (browser overhead)

---

### Option 3: Custom pytest Plugin (Recommended for E2E)

**What it would do:**
- Track execution times for all tests
- Store baselines in JSON/YAML
- Compare current run vs baseline
- Warn/fail on regressions
- Support per-test and per-suite limits
- Generate performance reports

**Implementation approach:**
```python
# tests/pytest_performance.py
import pytest
import time
import json
from pathlib import Path

PERFORMANCE_BASELINE_FILE = Path("tests/.performance_baseline.json")

class PerformanceTracker:
    def __init__(self):
        self.baselines = self.load_baselines()
        self.current_run = {}
    
    def load_baselines(self):
        if PERFORMANCE_BASELINE_FILE.exists():
            return json.load(open(PERFORMANCE_BASELINE_FILE))
        return {}
    
    def save_baseline(self):
        json.dump(self.baselines, open(PERFORMANCE_BASELINE_FILE, 'w'), indent=2)

@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    start_time = time.time()
    outcome = yield
    duration = time.time() - start_time
    
    if call.when == "call":
        test_id = item.nodeid
        tracker.current_run[test_id] = duration
        
        # Check against baseline
        baseline = tracker.baselines.get(test_id, {})
        if baseline and duration > baseline.get('max', float('inf')):
            # Test is slower than baseline
            pass
```

**Pros:**
- ✅ Full control over behavior
- ✅ Customized for E2E tests
- ✅ Can track suite-level times
- ✅ Baseline comparison
- ✅ Regression detection
- ✅ No code changes needed (uses hooks)

**Cons:**
- ❌ Requires development
- ❌ Need to maintain baseline file
- ❌ More code to maintain

---

### Option 4: pytest-profiling (For Deep Analysis)

**What it does:**
- Profiles test execution
- Identifies bottlenecks
- Generates call graphs
- Shows where time is spent

**Installation:**
```bash
pip install pytest-profiling
```

**Usage:**
```bash
pytest --profile
pytest --profile-svg  # Generate SVG call graph
```

**Pros:**
- ✅ Identifies bottlenecks
- ✅ Useful for optimization
- ✅ Visual call graphs

**Cons:**
- ❌ Heavy overhead
- ❌ Not for regular runs
- ❌ Doesn't set limits or track baselines

---

## Recommended Approach: Hybrid Solution

### Phase 1: Enhanced pytest-timeout (Immediate)

**Add per-test and per-suite timeouts:**

```python
# tests/conftest.py
import pytest

# Per-test timeout markers
@pytest.fixture(autouse=True)
def set_test_timeout(request):
    """Set timeout based on markers."""
    timeout_markers = {
        'smoke': 10,      # Smoke tests should be fast
        'slow': 60,       # Slow tests get 60s
        'version_switch': 120,  # Version switch tests get 2min
    }
    
    for marker_name, timeout in timeout_markers.items():
        if request.node.get_closest_marker(marker_name):
            request.node.add_marker(
                pytest.mark.timeout(timeout, method='thread')
            )
            break
```

**Update pytest.ini:**
```ini
[pytest]
timeout = 300  # Global default (5 minutes)
timeout_method = thread  # More reliable than signal for Selenium

# Per-marker timeouts
markers =
    smoke: Smoke tests - must complete in 10s
    slow: Slow tests - allowed up to 60s
    version_switch: Version switch tests - allowed up to 120s
```

### Phase 2: Custom Performance Tracker (Future)

**Create `tests/pytest_performance.py`:**

```python
"""
Performance tracking plugin for pytest.

Tracks execution times, maintains baselines, and detects regressions.
"""
import pytest
import time
import json
from pathlib import Path
from collections import defaultdict

PERFORMANCE_BASELINE_FILE = Path("tests/.performance_baseline.json")
PERFORMANCE_REGRESSION_THRESHOLD = 1.5  # 50% slower = regression

class PerformanceTracker:
    def __init__(self):
        self.baselines = self._load_baselines()
        self.current_run = {}
        self.suite_times = defaultdict(float)
        self.warnings = []
        self.failures = []
    
    def _load_baselines(self):
        if PERFORMANCE_BASELINE_FILE.exists():
            with open(PERFORMANCE_BASELINE_FILE) as f:
                return json.load(f)
        return {}
    
    def save_baseline(self):
        """Save current run as new baseline."""
        with open(PERFORMANCE_BASELINE_FILE, 'w') as f:
            json.dump(self.current_run, f, indent=2)
    
    def check_regression(self, test_id, duration):
        """Check if test is slower than baseline."""
        baseline = self.baselines.get(test_id, {})
        if not baseline:
            return None
        
        baseline_time = baseline.get('avg', baseline.get('max', 0))
        if baseline_time == 0:
            return None
        
        ratio = duration / baseline_time
        if ratio > PERFORMANCE_REGRESSION_THRESHOLD:
            return {
                'test_id': test_id,
                'current': duration,
                'baseline': baseline_time,
                'ratio': ratio,
                'slower_by': duration - baseline_time
            }
        return None

tracker = PerformanceTracker()

@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """Track test execution times."""
    start_time = time.time()
    outcome = yield
    duration = time.time() - start_time
    
    if call.when == "call":
        test_id = item.nodeid
        tracker.current_run[test_id] = {
            'duration': duration,
            'status': 'passed' if outcome.get_result().passed else 'failed'
        }
        
        # Track suite time
        suite_name = item.cls.__name__ if item.cls else item.module.__name__
        tracker.suite_times[suite_name] += duration
        
        # Check for regression
        regression = tracker.check_regression(test_id, duration)
        if regression:
            tracker.warnings.append(regression)
            # Optionally fail the test
            # outcome.force_result(pytest.ExitCode.TESTS_FAILED)

def pytest_sessionfinish(session, exitstatus):
    """Generate performance report at end of session."""
    if tracker.warnings:
        print("\n⚠️  Performance Regressions Detected:")
        for reg in tracker.warnings:
            print(f"  {reg['test_id']}: {reg['current']:.2f}s "
                  f"(baseline: {reg['baseline']:.2f}s, "
                  f"{reg['ratio']:.1f}x slower)")
    
    print("\n📊 Suite Execution Times:")
    for suite, total_time in sorted(tracker.suite_times.items(), 
                                     key=lambda x: x[1], reverse=True):
        print(f"  {suite}: {total_time:.2f}s")
```

### Phase 3: Configuration File

**Create `tests/performance_config.yaml`:**

```yaml
# Performance limits and baselines
limits:
  # Per-test limits (in seconds)
  default: 30
  smoke: 10
  slow: 60
  version_switch: 120
  
  # Per-suite limits (in seconds)
  suites:
    TestHelloWorldButton: 60
    TestVersionInformation: 90
    TestSecurityStatus: 300  # Includes version switching

# Regression detection
regression:
  enabled: true
  threshold: 1.5  # 50% slower triggers warning
  fail_on_regression: false  # Set to true to fail tests on regression
  
# Baseline management
baseline:
  file: tests/.performance_baseline.json
  auto_update: false  # Set to true to auto-update after successful runs
  min_runs: 3  # Minimum runs before establishing baseline
```

---

## Implementation Plan

### Step 1: Enhanced Timeouts (Quick Win)
1. Add per-marker timeout configuration
2. Update `pytest.ini` with marker-specific timeouts
3. Add timeout markers to existing tests
4. Test that timeouts work correctly

### Step 2: Performance Tracking Plugin
1. Create `tests/pytest_performance.py`
2. Implement basic time tracking
3. Add baseline file support
4. Add regression detection
5. Generate performance reports

### Step 3: Configuration and Integration
1. Create `performance_config.yaml`
2. Integrate with existing test infrastructure
3. Add Makefile targets for performance testing
4. Update documentation

### Step 4: CI/CD Integration
1. Store baselines in version control or artifact storage
2. Compare against baselines in CI
3. Fail builds on significant regressions
4. Generate performance trend reports

---

## Usage Examples

### Setting Per-Test Limits

```python
# Via marker
@pytest.mark.timeout(30)
def test_something():
    pass

# Via config file
# performance_config.yaml sets default to 30s
```

### Setting Per-Suite Limits

```python
# Via class marker
@pytest.mark.timeout(120)
class TestSecurityStatus:
    pass

# Via config file
# suites.TestSecurityStatus: 120
```

### Tracking and Comparing

```bash
# Run tests and track performance
make test-parallel

# Update baseline after optimization
pytest --update-baseline

# Check for regressions
pytest --check-performance

# Generate performance report
pytest --performance-report
```

---

## Questions to Consider

1. **Should slow tests fail or just warn?**
   - Recommendation: Warn by default, fail on CI

2. **How to handle flaky timing?**
   - Recommendation: Use average of last N runs, ignore outliers

3. **Where to store baselines?**
   - Options: Git (committed), CI artifacts, separate storage
   - Recommendation: Git for now, CI artifacts for production

4. **How to handle new tests?**
   - Recommendation: First run establishes baseline, subsequent runs compare

5. **Should suite limits be sum or max?**
   - Recommendation: Sum (total time for all tests in suite)

6. **How to handle parallel execution?**
   - Recommendation: Track individual test times, aggregate suite times

---

## Next Steps

1. **Immediate**: Enhance pytest-timeout with per-marker limits
2. **Short-term**: Build custom performance tracker plugin
3. **Long-term**: Integrate with CI/CD for regression detection

Would you like me to implement any of these phases?
