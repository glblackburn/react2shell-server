"""
Pytest configuration and shared fixtures for Selenium tests.
"""
import pytest
import time
import subprocess
import requests
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.firefox.service import Service as FirefoxService
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from webdriver_manager.chrome import ChromeDriverManager
from webdriver_manager.firefox import GeckoDriverManager
from pages.app_page import AppPage


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
    
    driver.implicitly_wait(5)  # Reduced from 10 to 5 seconds
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


# Pytest hooks
def pytest_configure(config):
    """Configure pytest."""
    config.addinivalue_line(
        "markers", "smoke: Smoke tests - critical functionality"
    )
    config.addinivalue_line(
        "markers", "regression: Regression tests"
    )
    config.addinivalue_line(
        "markers", "version_switch: Tests that switch React versions"
    )


@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """Take screenshot on test failure."""
    outcome = yield
    rep = outcome.get_result()
    
    if rep.when == "call" and rep.failed:
        # Take screenshot if driver is available
        if "driver" in item.fixturenames:
            driver = item.funcargs.get("driver")
            if driver:
                screenshot_path = f"reports/screenshots/{item.name}_failure.png"
                try:
                    driver.save_screenshot(screenshot_path)
                    print(f"\n📸 Screenshot saved: {screenshot_path}")
                except Exception as e:
                    print(f"\n⚠️  Failed to save screenshot: {e}")
