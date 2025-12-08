"""
Performance tracking plugin for pytest.

Tracks execution times, maintains baselines, and detects regressions.
"""
import pytest
import time
import json
import os
import tempfile
import glob
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Optional
from datetime import datetime

# Import performance history utilities
from utils.performance_history import save_run_history

# Configuration
PERFORMANCE_BASELINE_FILE = Path("tests/.performance_baseline.json")
PERFORMANCE_CONFIG_FILE = Path("tests/performance_config.yaml")
PERFORMANCE_REGRESSION_THRESHOLD = 1.5  # 50% slower = regression
PERFORMANCE_WARNING_THRESHOLD = 1.2  # 20% slower = warning

# Load performance config if available
_performance_config = {}
if PERFORMANCE_CONFIG_FILE.exists():
    try:
        import yaml
        with open(PERFORMANCE_CONFIG_FILE) as f:
            _performance_config = yaml.safe_load(f) or {}
        # Override thresholds from config if present
        if _performance_config.get('regression', {}).get('threshold'):
            PERFORMANCE_REGRESSION_THRESHOLD = _performance_config['regression']['threshold']
        if _performance_config.get('regression', {}).get('warning_threshold'):
            PERFORMANCE_WARNING_THRESHOLD = _performance_config['regression']['warning_threshold']
    except ImportError:
        # YAML not available - use defaults
        pass
    except Exception:
        # Invalid config - use defaults
        pass


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
        baseline_data = {}
        for test_id, data in self.current_run.items():
            if isinstance(data, list):
                durations = [d['duration'] for d in data if 'duration' in d]
                if durations:
                    baseline_data[test_id] = {
                        'avg': sum(durations) / len(durations),
                        'min': min(durations),
                        'max': max(durations),
                        'runs': len(durations)
                    }
            elif isinstance(data, dict) and 'duration' in data:
                baseline_data[test_id] = {
                    'avg': data['duration'],
                    'min': data['duration'],
                    'max': data['duration'],
                    'runs': 1
                }
        
        PERFORMANCE_BASELINE_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(PERFORMANCE_BASELINE_FILE, 'w') as f:
            json.dump(baseline_data, f, indent=2)
    
    def check_regression(self, test_id: str, duration: float) -> Optional[Dict]:
        """Check if test is slower than baseline."""
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
        if isinstance(self.current_run[test_id], list):
            self.current_run[test_id].append({'duration': duration, 'status': status})
        else:
            self.current_run[test_id] = [self.current_run[test_id], {'duration': duration, 'status': status}]
    
    def record_suite_time(self, suite_name: str, duration: float):
        """Record suite execution time."""
        self.suite_times[suite_name] += duration


# Global tracker instance
_performance_tracker = PerformanceTracker()


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_call(item):
    """Track test execution start time for performance tracking."""
    test_id = item.nodeid
    # Only track if not a setup/teardown phase
    if hasattr(item, 'function') or hasattr(item, 'cls'):
        _performance_tracker.test_start_times[test_id] = time.time()
    outcome = yield


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """Take screenshot on test failure and track performance."""
    outcome = yield
    rep = outcome.get_result()
    
    # Performance tracking
    if call.when == "call":
        test_id = item.nodeid
        start_time = _performance_tracker.test_start_times.get(test_id, time.time())
        duration = time.time() - start_time
        status = 'passed' if rep.passed else 'failed'
        _performance_tracker.record_test_time(test_id, duration, status)
        
        suite_name = item.cls.__name__ if item.cls else item.module.__name__
        _performance_tracker.record_suite_time(suite_name, duration)
        
        regression = _performance_tracker.check_regression(test_id, duration)
        if regression:
            if regression['severity'] == 'regression':
                _performance_tracker.regressions.append(regression)
            else:
                _performance_tracker.warnings.append(regression)
    
    if rep.when == "call" and rep.failed:
        # Take screenshot if driver is available
        if "driver" in item.fixturenames:
            driver = item.funcargs.get("driver")
            if driver:
                # Try to get report directory from environment or config, fallback to default
                config = item.config
                report_dir = os.environ.get('PYTEST_REPORT_DIR', "reports")
                if hasattr(config, 'option') and hasattr(config.option, 'htmlpath'):
                    # Extract directory from HTML report path if set
                    html_path = config.option.htmlpath
                    if html_path:
                        report_dir = os.path.dirname(html_path)
                elif hasattr(config, '_report_dir'):
                    # Use custom report directory if set
                    report_dir = config._report_dir
                
                screenshot_dir = os.path.join(report_dir, "screenshots")
                os.makedirs(screenshot_dir, exist_ok=True)
                screenshot_path = os.path.join(screenshot_dir, f"{item.name}_failure.png")
                try:
                    driver.save_screenshot(screenshot_path)
                    print(f"\n📸 Screenshot saved: {screenshot_path}")
                except Exception as e:
                    print(f"\n⚠️  Failed to save screenshot: {e}")


def pytest_sessionfinish(session, exitstatus):
    """Generate performance report at end of session."""
    import tempfile
    
    # Check if we're in a worker process (pytest-xdist)
    # Workers have a 'workerinput' attribute, master doesn't
    is_worker = hasattr(session.config, 'workerinput')
    
    if is_worker:
        # Worker process: write performance data to temp file
        worker_id = session.config.workerinput.get('workerid', 'unknown')
        temp_dir = tempfile.gettempdir()
        perf_file = os.path.join(temp_dir, f"pytest_perf_{os.getpid()}_{worker_id}.json")
        
        try:
            perf_data = {
                'current_run': _performance_tracker.current_run,
                'suite_times': dict(_performance_tracker.suite_times),
                'regressions': _performance_tracker.regressions,
                'warnings': _performance_tracker.warnings
            }
            with open(perf_file, 'w') as f:
                json.dump(perf_data, f)
        except Exception as e:
            # Silently fail in worker - master will handle reporting
            pass
        return
    
    # Master process: aggregate data from all workers
    aggregated_tracker = PerformanceTracker()
    temp_dir = tempfile.gettempdir()
    perf_files = glob.glob(os.path.join(temp_dir, "pytest_perf_*.json"))
    
    # Aggregate data from worker files
    for perf_file in perf_files:
        try:
            with open(perf_file, 'r') as f:
                worker_data = json.load(f)
            
            # Aggregate current_run
            for test_id, times in worker_data.get('current_run', {}).items():
                if test_id not in aggregated_tracker.current_run:
                    aggregated_tracker.current_run[test_id] = []
                if isinstance(times, list):
                    aggregated_tracker.current_run[test_id].extend(times)
                else:
                    aggregated_tracker.current_run[test_id].append(times)
            
            # Aggregate suite times
            for suite, duration in worker_data.get('suite_times', {}).items():
                aggregated_tracker.suite_times[suite] += duration
            
            # Aggregate regressions and warnings
            aggregated_tracker.regressions.extend(worker_data.get('regressions', []))
            aggregated_tracker.warnings.extend(worker_data.get('warnings', []))
            
            # Clean up worker file
            try:
                os.remove(perf_file)
            except:
                pass
        except Exception:
            # Skip invalid files
            continue
    
    # Also include master process data if any (for non-xdist runs)
    if _performance_tracker.current_run:
        for test_id, times in _performance_tracker.current_run.items():
            if test_id not in aggregated_tracker.current_run:
                aggregated_tracker.current_run[test_id] = []
            if isinstance(times, list):
                aggregated_tracker.current_run[test_id].extend(times)
            else:
                aggregated_tracker.current_run[test_id].append(times)
        
        for suite, duration in _performance_tracker.suite_times.items():
            aggregated_tracker.suite_times[suite] += duration
        
        aggregated_tracker.regressions.extend(_performance_tracker.regressions)
        aggregated_tracker.warnings.extend(_performance_tracker.warnings)
    
    # Use aggregated tracker for reporting
    tracker = aggregated_tracker if aggregated_tracker.current_run else _performance_tracker
    
    # Save to history (always save, even if some tests failed)
    if tracker.current_run:
        try:
            # Get framework mode for history
            try:
                from utils.framework_detector import get_framework_mode
                framework_mode = get_framework_mode()
            except Exception:
                framework_mode = "unknown"
            
            timestamp = datetime.now().isoformat()
            history_file = save_run_history(
                tracker.current_run,
                tracker.suite_times,
                timestamp=timestamp,
                framework_mode=framework_mode
            )
            # Only print if explicitly requested to reduce noise
            if os.environ.get('PYTEST_SAVE_HISTORY') == 'true':
                print(f"\n📊 Performance history saved: {history_file} (Framework: {framework_mode})")
        except Exception as e:
            # Silently fail - history is optional
            pass
    
    # Save baseline if requested (always try, even if some tests failed)
    if os.environ.get('PYTEST_UPDATE_BASELINE') == 'true' and tracker.current_run:
        try:
            tracker.save_baseline()
            print(f"\n✓ Baseline updated: {PERFORMANCE_BASELINE_FILE}")
        except Exception as e:
            print(f"\n⚠️  Failed to update baseline: {e}")
    
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


@pytest.fixture(autouse=True)
def set_test_timeout(request):
    """Automatically set timeout based on test markers or individual test limits.
    
    Priority:
    1. Individual test limit from performance_config.yaml
    2. Marker-based limits (smoke > slow > version_switch)
    3. Default limit
    """
    test_id = request.node.nodeid
    
    # Try to load individual test limit from config
    individual_limit = None
    if PERFORMANCE_CONFIG_FILE.exists():
        try:
            import yaml
            with open(PERFORMANCE_CONFIG_FILE) as f:
                perf_config = yaml.safe_load(f) or {}
            test_limits = perf_config.get('limits', {}).get('tests', {})
            individual_limit = test_limits.get(test_id)
        except Exception:
            pass
    
    # If individual limit found, use it
    if individual_limit:
        if not request.node.get_closest_marker('timeout'):
            request.node.add_marker(
                pytest.mark.timeout(individual_limit, method='thread')
            )
        return
    
    # Fall back to marker-based timeouts
    timeout_markers = {
        'smoke': 10,           # Smoke tests should be fast
        'slow': 60,            # Slow tests get 60s
        'version_switch': 120, # Version switch tests get 2min
    }
    
    # Check markers in priority order
    for marker_name, timeout in timeout_markers.items():
        marker = request.node.get_closest_marker(marker_name)
        if marker:
            # Apply timeout marker if not already set
            if not request.node.get_closest_marker('timeout'):
                request.node.add_marker(
                    pytest.mark.timeout(timeout, method='thread')
                )
            break
