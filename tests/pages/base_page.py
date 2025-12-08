"""
Base Page class with common functionality for all page objects.
"""
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException
import logging


logger = logging.getLogger(__name__)


class BasePage:
    """Base page class with common methods."""
    
    def __init__(self, driver):
        """Initialize base page with WebDriver instance."""
        self.driver = driver
        self.wait = WebDriverWait(driver, 5)  # Reduced from 10 to 5 seconds
        self.logger = logger
    
    def navigate(self, url=None):
        """Navigate to a URL."""
        if url:
            self.driver.get(url)
        else:
            # Default to base URL from conftest
            from conftest import BASE_URL
            self.driver.get(BASE_URL)
        self.logger.info(f"Navigated to: {self.driver.current_url}")
    
    def find_element(self, by, value, timeout=5):
        """Find element with explicit wait."""
        try:
            wait = WebDriverWait(self.driver, timeout)
            element = wait.until(EC.presence_of_element_located((by, value)))
            return element
        except TimeoutException:
            self.logger.error(f"Element not found: {by}={value}")
            raise
    
    def find_elements(self, by, value, timeout=5):
        """Find multiple elements with explicit wait."""
        try:
            wait = WebDriverWait(self.driver, timeout)
            wait.until(EC.presence_of_element_located((by, value)))
            return self.driver.find_elements(by, value)
        except TimeoutException:
            self.logger.error(f"Elements not found: {by}={value}")
            return []
    
    def click_element(self, by, value, timeout=5):
        """Click element with explicit wait for clickability."""
        try:
            wait = WebDriverWait(self.driver, timeout)
            element = wait.until(EC.element_to_be_clickable((by, value)))
            element.click()
            self.logger.info(f"Clicked element: {by}={value}")
        except TimeoutException:
            self.logger.error(f"Element not clickable: {by}={value}")
            raise
    
    def get_text(self, by, value, timeout=5):
        """Get text from element."""
        element = self.find_element(by, value, timeout)
        return element.text
    
    def is_element_visible(self, by, value, timeout=5):
        """Check if element is visible."""
        try:
            wait = WebDriverWait(self.driver, timeout)
            wait.until(EC.visibility_of_element_located((by, value)))
            return True
        except TimeoutException:
            return False
    
    def is_element_present(self, by, value, timeout=5):
        """Check if element is present in DOM."""
        try:
            wait = WebDriverWait(self.driver, timeout)
            wait.until(EC.presence_of_element_located((by, value)))
            return True
        except TimeoutException:
            return False
    
    def wait_for_element_to_disappear(self, by, value, timeout=5):
        """Wait for element to disappear."""
        try:
            wait = WebDriverWait(self.driver, timeout)
            wait.until(EC.invisibility_of_element_located((by, value)))
            return True
        except TimeoutException:
            return False
    
    def get_title(self):
        """Get page title."""
        return self.driver.title
    
    def get_current_url(self):
        """Get current URL."""
        return self.driver.current_url
    
    def take_screenshot(self, filename):
        """Take screenshot."""
        self.driver.save_screenshot(filename)
        self.logger.info(f"Screenshot saved: {filename}")
