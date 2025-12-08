"""
Performance tracking plugin for pytest.

Tracks execution times, maintains baselines, and detects regressions.
"""
import pytest
import time
import json
import os
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Optional

# Configuration
PERFORMANCE_BASELINE_FILE = Path("tests/.performance_baseline.json")
PERFORMANCE_REGRESSION_THRESHOLD = 1.5  # 50% slower = regression
PERFORMANCE_WARNING_THRESHOLD = 1.2  # 20% slower = warning


class PerformanceTracker:
    """Tracks test execution times and compares against baselines."""
    
    def __init__(self):
        self.baselines = self._load_baselines()
        self.current_run: Dict[str, Dict] = {}
        self.suite_times: Dict[str, float] = defaultdict(float)
        self.warnings: List[Dict] = []
        self.regressions: List[Dict] = []
        self.test_start_times: Dict[str, float] = {}
    
    def _load_baselines(self) -> Dict:
        """Load performance baselines from file."""
        if PERFORMANCE_BASELINE_FILE.exists():
            try:
                with open(PERFORMANCE_BASELINE_FILE) as f:
                    return json.load(f)
            except (json.JSONDecodeError, IOError):
                return {}
        return {}
    
    def save_baseline(self):
        """Save current run as new baseline."""
        # Calculate averages for tests that ran multiple times
        baseline_data = {}
        for test_id, data in self.current_run.items():
            if isinstance(data, list):
                # Multiple runs - calculate average
                durations = [d['duration'] for d in data if 'duration' in d]
                if durations:
                    baseline_data[test_id] = {
                        'avg': sum(durations) / len(durations),
                        'min': min(durations),
                        'max': max(durations),
                        'runs': len(durations)
                    }
            elif isinstance(data, dict) and 'duration' in data:
                # Single run
                baseline_data[test_id] = {
                    'avg': data['duration'],
                    'min': data['duration'],
                    'max': data['duration'],
                    'runs': 1
                }
        
        # Save to file
        PERFORMANCE_BASELINE_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(PERFORMANCE_BASELINE_FILE, 'w') as f:
            json.dump(baseline_data, f, indent=2)
    
    def check_regression(self, test_id: str, duration: float) -> Optional[Dict]:
        """Check if test is slower than baseline.
        
        Returns regression info if test is significantly slower, None otherwise.
        """
        baseline = self.baselines.get(test_id, {})
        if not baseline:
            return None
        
        baseline_time = baseline.get('avg', baseline.get('max', 0))
        if baseline_time == 0:
            return None
        
        ratio = duration / baseline_time
        
        regression_info = {
            'test_id': test_id,
            'current': duration,
            'baseline': baseline_time,
            'ratio': ratio,
            'slower_by': duration - baseline_time,
            'percent_slower': (ratio - 1) * 100
        }
        
        if ratio > PERFORMANCE_REGRESSION_THRESHOLD:
            regression_info['severity'] = 'regression'
            return regression_info
        elif ratio > PERFORMANCE_WARNING_THRESHOLD:
            regression_info['severity'] = 'warning'
            return regression_info
        
        return None
    
    def record_test_time(self, test_id: str, duration: float, status: str):
        """Record test execution time."""
        if test_id not in self.current_run:
            self.current_run[test_id] = []
        
        # Handle both single dict and list formats
        if isinstance(self.current_run[test_id], list):
            self.current_run[test_id].append({
                'duration': duration,
                'status': status
            })
        else:
            # Convert to list if it was a single dict
            self.current_run[test_id] = [self.current_run[test_id], {
                'duration': duration,
                'status': status
            }]
    
    def record_suite_time(self, suite_name: str, duration: float):
        """Record suite execution time."""
        self.suite_times[suite_name] += duration


# Global tracker instance
tracker = PerformanceTracker()


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_call(item):
    """Track test execution start time."""
    test_id = item.nodeid
    tracker.test_start_times[test_id] = time.time()
    outcome = yield
    # Execution time is tracked in pytest_runtest_makereport


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """Track test execution times and check for regressions.
    
    This hook wraps the existing pytest_runtest_makereport to add performance tracking.
    """
    outcome = yield
    rep = outcome.get_result()
    
    if call.when == "call":
        test_id = item.nodeid
        start_time = tracker.test_start_times.get(test_id, time.time())
        duration = time.time() - start_time
        
        status = 'passed' if rep.passed else 'failed'
        tracker.record_test_time(test_id, duration, status)
        
        # Track suite time
        suite_name = item.cls.__name__ if item.cls else item.module.__name__
        tracker.record_suite_time(suite_name, duration)
        
        # Check for regression
        regression = tracker.check_regression(test_id, duration)
        if regression:
            if regression['severity'] == 'regression':
                tracker.regressions.append(regression)
            else:
                tracker.warnings.append(regression)


def pytest_sessionfinish(session, exitstatus):
    """Generate performance report at end of session."""
    # Save baseline if requested (do this first)
    if os.environ.get('PYTEST_UPDATE_BASELINE') == 'true' and tracker.current_run:
        tracker.save_baseline()
        print(f"\n✓ Baseline updated: {PERFORMANCE_BASELINE_FILE}")
    
    if not tracker.current_run:
        return
    
    # Print performance summary
    has_issues = tracker.regressions or tracker.warnings
    
    if has_issues or tracker.suite_times:
        print("\n" + "="*70)
        print("PERFORMANCE REPORT")
        print("="*70)
        
        if tracker.regressions:
            print("\n❌ Performance Regressions Detected (>50% slower):")
            for reg in tracker.regressions:
                print(f"  {reg['test_id']}")
                print(f"    Current: {reg['current']:.2f}s")
                print(f"    Baseline: {reg['baseline']:.2f}s")
                print(f"    Slower by: {reg['slower_by']:.2f}s ({reg['percent_slower']:.1f}%)")
        
        if tracker.warnings:
            print("\n⚠️  Performance Warnings (>20% slower):")
            for warn in tracker.warnings:
                print(f"  {warn['test_id']}")
                print(f"    Current: {warn['current']:.2f}s")
                print(f"    Baseline: {warn['baseline']:.2f}s")
                print(f"    Slower by: {warn['slower_by']:.2f}s ({warn['percent_slower']:.1f}%)")
    
    # Print suite execution times
    if tracker.suite_times:
        print("\n📊 Suite Execution Times:")
        for suite, total_time in sorted(tracker.suite_times.items(), 
                                         key=lambda x: x[1], reverse=True):
            print(f"  {suite}: {total_time:.2f}s")


def pytest_addoption(parser):
    """Add command line options for performance tracking."""
    parser.addoption(
        "--update-baseline",
        action="store_true",
        default=False,
        help="Update performance baseline with current run results"
    )


def pytest_configure(config):
    """Configure performance tracking."""
    if config.getoption("--update-baseline"):
        os.environ['PYTEST_UPDATE_BASELINE'] = 'true'
