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
            manager = ChromeDriverManager()
            # Set cache_valid_range to avoid version checks if driver exists
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
    driver.maximize_window()
    
    yield driver
    
    # Cleanup
    driver.quit()
