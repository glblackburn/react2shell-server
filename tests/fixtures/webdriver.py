"""
WebDriver fixtures for Selenium tests.
"""
import pytest
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.firefox.service import Service as FirefoxService
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from webdriver_manager.chrome import ChromeDriverManager
from webdriver_manager.firefox import GeckoDriverManager


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
