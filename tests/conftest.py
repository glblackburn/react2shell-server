"""
Pytest configuration and shared fixtures for Selenium tests.
"""
import pytest
import time
import subprocess
import requests
import os
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.firefox.service import Service as FirefoxService
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from webdriver_manager.chrome import ChromeDriverManager
from webdriver_manager.firefox import GeckoDriverManager
from pages.app_page import AppPage

# Performance tracking (integrated from pytest_performance.py)
import json
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Optional

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


# Test configuration
BASE_URL = "http://localhost:5173"
API_URL = "http://localhost:3000"
FRONTEND_PORT = 5173
BACKEND_PORT = 3000


def check_server_running(url, timeout=1):
    """Check if a server is running at the given URL."""
    try:
        response = requests.get(url, timeout=timeout)
        return response.status_code == 200
    except requests.exceptions.RequestException:
        return False


def wait_for_server(url, max_attempts=30, delay=1):
    """Wait for server to be ready."""
    for attempt in range(max_attempts):
        if check_server_running(url, timeout=1):
            return True
        if attempt < max_attempts - 1:  # Don't sleep on last attempt
            time.sleep(delay)
    return False


@pytest.fixture(scope="session")
def start_servers():
    """Start both frontend and backend servers before tests."""
    print("\n🚀 Starting servers...")
    
    # Check if servers are already running
    try:
        requests.get(f"{BASE_URL}", timeout=2)
        requests.get(f"{API_URL}/api/hello", timeout=2)
        print("✓ Servers already running")
        yield
        return
    except requests.exceptions.RequestException:
        pass
    
    # Start servers using Makefile
    try:
        subprocess.run(["make", "start"], check=True, capture_output=True)
        print("✓ Started servers with 'make start'")
        
        # Wait for servers to be ready
        print("⏳ Waiting for servers to be ready...")
        frontend_ready = wait_for_server(BASE_URL)
        backend_ready = wait_for_server(f"{API_URL}/api/hello")
        
        if frontend_ready and backend_ready:
            print("✓ Both servers are ready!")
        else:
            pytest.fail("Servers failed to start or become ready")
        
        yield
        
    finally:
        # Stop servers after tests
        print("\n🛑 Stopping servers...")
        try:
            subprocess.run(["make", "stop"], check=True, capture_output=True)
            print("✓ Servers stopped")
        except subprocess.CalledProcessError:
            print("⚠️  Error stopping servers (may already be stopped)")


@pytest.fixture(scope="function")
def driver(request, start_servers):
    """Create and configure WebDriver instance."""
    browser = request.config.getoption("--browser", default="chrome")
    headless_str = request.config.getoption("--headless", default="true")
    headless = headless_str.lower() == "true"
    
    # Always use headless for faster execution unless explicitly disabled
    if headless_str == "default":
        headless = True
    
    if browser == "chrome":
        options = Options()
        if headless:
            options.add_argument("--headless=new")  # Use new headless mode (faster)
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--disable-gpu")
        options.add_argument("--disable-extensions")
        options.add_argument("--disable-logging")
        options.add_argument("--log-level=3")  # Suppress logs
        options.add_argument("--window-size=1920,1080")
        options.add_argument("--disable-background-timer-throttling")
        options.add_argument("--disable-backgrounding-occluded-windows")
        options.add_argument("--disable-renderer-backgrounding")
        
        service = Service(ChromeDriverManager().install())
        driver = webdriver.Chrome(service=service, options=options)
        
    elif browser == "firefox":
        options = FirefoxOptions()
        if headless:
            options.add_argument("--headless")
        options.add_argument("--width=1920")
        options.add_argument("--height=1080")
        # Firefox performance optimizations
        options.set_preference("dom.webdriver.enabled", False)
        options.set_preference("useAutomationExtension", False)
        
        service = FirefoxService(GeckoDriverManager().install())
        driver = webdriver.Firefox(service=service, options=options)
        
    elif browser == "safari":
        # Safari doesn't need driver manager
        driver = webdriver.Safari()
        
    else:
        pytest.fail(f"Unsupported browser: {browser}")
    
    driver.implicitly_wait(3)  # Reduced from 5 to 3 seconds for faster execution
    driver.maximize_window()
    
    yield driver
    
    # Cleanup
    driver.quit()


@pytest.fixture(scope="function")
def app_page(driver):
    """Create AppPage instance and navigate to application."""
    page = AppPage(driver)
    page.navigate()
    return page


@pytest.fixture(scope="function")
def react_version(request):
    """Parameterized fixture that switches React versions for testing.
    
    Usage:
        @pytest.mark.parametrize("react_version", ["19.0", "19.1.0"], indirect=True)
        def test_something(app_page, react_version):
            # react_version will be the version string, and servers will be restarted
    """
    from utils.server_manager import (
        switch_react_version, stop_servers, start_servers as start_servers_func, 
        wait_for_server, check_server_running, get_current_react_version, check_version_installed
    )
    
    # Get version from parameter if provided
    version = request.param if hasattr(request, 'param') else None
    
    if version:
        # Check if already on this version
        current = get_current_react_version()
        already_installed = check_version_installed(version)
        
        if current == version and already_installed:
            print(f"✓ React {version} already active, skipping switch")
            # Just ensure servers are running
            if not check_server_running("http://localhost:5173") or not check_server_running("http://localhost:3000/api/hello"):
                print(f"🔄 Servers not running, starting for React {version}...")
                start_servers_func()
                wait_for_server("http://localhost:5173", max_attempts=20, delay=1)
                wait_for_server("http://localhost:3000/api/hello", max_attempts=20, delay=1)
        else:
            print(f"\n🔄 Switching to React {version}...")
            # Stop servers before switching version
            stop_servers()
            
            # Switch React version
            if switch_react_version(version):
                # Restart servers after version switch
                print(f"🔄 Restarting servers for React {version}...")
                start_servers_func()
                # Wait for servers to be ready (optimized wait times)
                frontend_url = "http://localhost:5173"
                api_url = "http://localhost:3000"
                if not wait_for_server(frontend_url, max_attempts=20, delay=1):
                    pytest.fail(f"Frontend server not ready after switching to React {version}")
                if not wait_for_server(f"{api_url}/api/hello", max_attempts=20, delay=1):
                    pytest.fail(f"Backend server not ready after switching to React {version}")
                print(f"✓ React {version} ready for testing")
            else:
                pytest.skip(f"Failed to switch to React {version}")
    
    yield version
    
    # Note: We don't restore the original version here to avoid slowing down tests
    # The original version should be restored manually or in CI/CD


# Pytest command line options
def pytest_addoption(parser):
    """Add custom command line options."""
    parser.addoption(
        "--browser",
        action="store",
        default="chrome",
        choices=["chrome", "firefox", "safari"],
        help="Browser to use for tests (default: chrome)"
    )
    parser.addoption(
        "--headless",
        action="store",
        default="true",
        choices=["true", "false"],
        help="Run browser in headless mode (default: true)"
    )
    # Note: --base-url is provided by pytest-selenium plugin, don't add it here




@pytest.fixture(autouse=True)
def set_test_timeout(request):
    """Automatically set timeout based on test markers.
    
    This fixture applies per-marker timeouts to tests based on their markers.
    Priority: smoke > slow > version_switch > default
    """
    # Timeout values in seconds for each marker
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


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_call(item):
    """Track test execution start time for performance tracking."""
    test_id = item.nodeid
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
    # Save baseline if requested
    if os.environ.get('PYTEST_UPDATE_BASELINE') == 'true' and _performance_tracker.current_run:
        _performance_tracker.save_baseline()
        print(f"\n✓ Baseline updated: {PERFORMANCE_BASELINE_FILE}")
    
    if not _performance_tracker.current_run:
        return
    
    # Print performance summary
    has_issues = _performance_tracker.regressions or _performance_tracker.warnings
    
    if has_issues or _performance_tracker.suite_times:
        print("\n" + "="*70)
        print("PERFORMANCE REPORT")
        print("="*70)
        
        if _performance_tracker.regressions:
            print("\n❌ Performance Regressions Detected (>50% slower):")
            for reg in _performance_tracker.regressions:
                print(f"  {reg['test_id']}")
                print(f"    Current: {reg['current']:.2f}s")
                print(f"    Baseline: {reg['baseline']:.2f}s")
                print(f"    Slower by: {reg['slower_by']:.2f}s ({reg['percent_slower']:.1f}%)")
        
        if _performance_tracker.warnings:
            print("\n⚠️  Performance Warnings (>20% slower):")
            for warn in _performance_tracker.warnings:
                print(f"  {warn['test_id']}")
                print(f"    Current: {warn['current']:.2f}s")
                print(f"    Baseline: {warn['baseline']:.2f}s")
                print(f"    Slower by: {warn['slower_by']:.2f}s ({warn['percent_slower']:.1f}%)")
    
    # Print suite execution times
    if _performance_tracker.suite_times:
        print("\n📊 Suite Execution Times:")
        for suite, total_time in sorted(_performance_tracker.suite_times.items(), 
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
    """Configure pytest and performance tracking."""
    config.addinivalue_line(
        "markers", "smoke: Smoke tests - critical functionality (timeout: 10s)"
    )
    config.addinivalue_line(
        "markers", "regression: Regression tests"
    )
    config.addinivalue_line(
        "markers", "version_switch: Tests that switch React versions (timeout: 120s)"
    )
    config.addinivalue_line(
        "markers", "slow: Tests that take longer to run (timeout: 60s)"
    )
    
    if config.getoption("--update-baseline"):
        os.environ['PYTEST_UPDATE_BASELINE'] = 'true'
