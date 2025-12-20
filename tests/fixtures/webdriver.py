"""
WebDriver fixtures for Selenium tests.
"""
import pytest
import os
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.firefox.service import Service as FirefoxService
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from webdriver_manager.chrome import ChromeDriverManager
from webdriver_manager.firefox import GeckoDriverManager

# Disable webdriver-manager's automatic version checking to avoid network calls
# Drivers should be pre-installed via 'make test-driver-install'
os.environ['WDM_LOG_LEVEL'] = '0'  # Suppress webdriver-manager logs
os.environ['WDM_PRINT_FIRST_LINE'] = 'False'


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
        
        # Use cached driver (should be pre-installed via make test-driver-install)
        # This will use cached driver if available, avoiding network downloads
        try:
            # Try to use cached driver version to avoid version check network calls
            # If we can determine the cached version, use it directly
            from pathlib import Path
            import glob
            import re
            
            cached_version = None
            # Check multiple possible cache locations
            # Structure 1: ~/.wdm/drivers/chromedriver/mac64/VERSION/chromedriver-mac-x64/chromedriver
            cache_dir1 = Path.home() / ".wdm" / "drivers" / "chromedriver"
            if cache_dir1.exists():
                # Check for OS-specific subdirectories (mac64, linux64, win32, etc.)
                for os_dir in cache_dir1.iterdir():
                    if os_dir.is_dir():
                        # Check version directories
                        for version_dir in os_dir.iterdir():
                            if version_dir.is_dir():
                                # Check for driver executable
                                driver_exe = version_dir / "chromedriver-mac-x64" / "chromedriver"
                                if not driver_exe.exists():
                                    driver_exe = version_dir / "chromedriver"
                                if driver_exe.exists() and driver_exe.is_file():
                                    cached_version = version_dir.name
                                    break
                        if cached_version:
                            break
            
            # Structure 2: ~/.wdm/gw*/drivers/chromedriver/mac64/VERSION/...
            if not cached_version:
                cache_pattern = str(Path.home() / ".wdm" / "gw*" / "drivers" / "chromedriver" / "*" / "*" / "chromedriver")
                driver_paths = glob.glob(cache_pattern)
                if driver_paths:
                    # Extract version from path (e.g., .../143.0.7499.40/...)
                    version_match = re.search(r'/(\d+\.\d+\.\d+\.\d+)/', driver_paths[0])
                    if version_match:
                        cached_version = version_match.group(1)
            
            if cached_version:
                # Use specific driver_version to avoid version check network calls
                # This completely eliminates network calls to googlechromelabs.github.io
                manager = ChromeDriverManager(driver_version=cached_version)
            else:
                # Fallback: use default manager (may make network call)
                manager = ChromeDriverManager()
                # Set environment variable to extend cache validity
                os.environ['WDM_CACHE_VALID_DAYS'] = '365'
            
            driver_path = manager.install()
            service = Service(driver_path)
            driver = webdriver.Chrome(service=service, options=options)
        except Exception as e:
            pytest.fail(f"Failed to start Chrome driver. Run 'make test-driver-install' first. Error: {e}")
        
    elif browser == "firefox":
        options = FirefoxOptions()
        if headless:
            options.add_argument("--headless")
        options.add_argument("--width=1920")
        options.add_argument("--height=1080")
        # Firefox performance optimizations
        options.set_preference("dom.webdriver.enabled", False)
        options.set_preference("useAutomationExtension", False)
        
        # Use cached driver (should be pre-installed via make test-driver-install)
        # This will use cached driver if available, avoiding network downloads
        try:
            manager = GeckoDriverManager()
            # Set cache_valid_range to skip version checks when driver is cached
            if hasattr(manager, 'cache_valid_range'):
                manager.cache_valid_range = 365  # Cache valid for 1 year
            # Also set via environment variable as fallback
            os.environ['WDM_CACHE_VALID_DAYS'] = '365'
            driver_path = manager.install()
            service = FirefoxService(driver_path)
            driver = webdriver.Firefox(service=service, options=options)
        except Exception as e:
            pytest.fail(f"Failed to start Firefox driver. Run 'make test-driver-install' first. Error: {e}")
        
    elif browser == "safari":
        # Safari doesn't need driver manager
        driver = webdriver.Safari()
        
    else:
        pytest.fail(f"Unsupported browser: {browser}")
    
    driver.implicitly_wait(3)  # Reduced from 5 to 3 seconds for faster execution
    driver.set_page_load_timeout(30)  # 30 second timeout for page loads to prevent hanging
    driver.maximize_window()
    
    yield driver
    
    # Cleanup
    driver.quit()
