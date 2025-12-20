"""
Base Page class with common functionality for all page objects.
"""
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException, WebDriverException
import logging


logger = logging.getLogger(__name__)


class BasePage:
    """Base page class with common methods."""
    
    def __init__(self, driver):
        """Initialize base page with WebDriver instance."""
        self.driver = driver
        self.wait = WebDriverWait(driver, 3)  # Reduced from 5 to 3 seconds for faster execution
        self.logger = logger
    
    def navigate(self, url=None):
        """Navigate to a URL."""
        if url:
            target_url = url
        else:
            # Default to base URL from server_constants (get dynamically)
            try:
                from utils.server_constants import get_frontend_url
                frontend_url = get_frontend_url()
                # Ensure we have a valid URL string
                if not frontend_url or not isinstance(frontend_url, str) or frontend_url.strip() == "":
                    self.logger.warning(f"Invalid frontend_url from get_frontend_url(): '{frontend_url}', using fallback")
                    frontend_url = "http://localhost:3000"
                target_url = frontend_url
            except Exception as e:
                self.logger.warning(f"Error getting frontend URL: {e}, using fallback")
                target_url = "http://localhost:3000"
            
            self.logger.info(f"Navigating to: {target_url}")
            try:
                self.driver.get(target_url)
                self.logger.info(f"Navigated to: {self.driver.current_url}")
            except (TimeoutException, WebDriverException) as e:
                self.logger.error(f"Failed to navigate to {target_url}: {e}")
                # Check if server is running
                try:
                    from utils.server_manager import check_server_running
                    server_running = check_server_running(target_url, timeout=2)
                    if not server_running:
                        raise Exception(f"Server is not running at {target_url}. Navigation timed out after 30s. Please ensure the server is started.")
                except Exception as check_error:
                    self.logger.error(f"Server check failed: {check_error}")
                raise
            except Exception as e:
                self.logger.error(f"Unexpected error navigating to {target_url}: {e}")
                raise
    
    def find_element(self, by, value, timeout=3):
        """Find element with explicit wait."""
        try:
            wait = WebDriverWait(self.driver, timeout)
            element = wait.until(EC.presence_of_element_located((by, value)))
            return element
        except TimeoutException:
            self.logger.error(f"Element not found: {by}={value}")
            raise
    
    def find_elements(self, by, value, timeout=3):
        """Find multiple elements with explicit wait."""
        try:
            wait = WebDriverWait(self.driver, timeout)
            wait.until(EC.presence_of_element_located((by, value)))
            return self.driver.find_elements(by, value)
        except TimeoutException:
            self.logger.error(f"Elements not found: {by}={value}")
            return []
    
    def click_element(self, by, value, timeout=3):
        """Click element with explicit wait for clickability."""
        try:
            wait = WebDriverWait(self.driver, timeout)
            element = wait.until(EC.element_to_be_clickable((by, value)))
            element.click()
            self.logger.info(f"Clicked element: {by}={value}")
        except TimeoutException:
            self.logger.error(f"Element not clickable: {by}={value}")
            raise
    
    def get_text(self, by, value, timeout=3):
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
    
    def is_element_present(self, by, value, timeout=3):
        """Check if element is present in DOM."""
        try:
            wait = WebDriverWait(self.driver, timeout)
            wait.until(EC.presence_of_element_located((by, value)))
            return True
        except TimeoutException:
            return False
    
    def wait_for_element_to_disappear(self, by, value, timeout=3):
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
