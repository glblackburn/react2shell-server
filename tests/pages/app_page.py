"""
Page Object Model for the main application page.
"""
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from pages.base_page import BasePage
import logging


logger = logging.getLogger(__name__)


class AppPage(BasePage):
    """Page Object for the React application."""
    
    # Locators
    VERSION_INFO_CARD = (By.CLASS_NAME, "version-info")
    VERSION_TITLE = (By.CLASS_NAME, "version-title")
    VERSION_LOADING = (By.CLASS_NAME, "version-loading")
    VERSION_ERROR = (By.CLASS_NAME, "version-error")
    VERSION_DETAILS = (By.CLASS_NAME, "version-details")
    
    # Version detail locators
    VERSION_ITEMS = (By.CLASS_NAME, "version-item")
    VERSION_LABEL = (By.CLASS_NAME, "version-label")
    VERSION_VALUE = (By.CLASS_NAME, "version-value")
    VERSION_STATUS = (By.CLASS_NAME, "version-status")
    STATUS_VULNERABLE = (By.CLASS_NAME, "status-vulnerable")
    STATUS_FIXED = (By.CLASS_NAME, "status-fixed")
    
    # Button and message locators
    HELLO_BUTTON = (By.CLASS_NAME, "big-red-button")
    MESSAGE_DIV = (By.CLASS_NAME, "message")
    
    def __init__(self, driver):
        """Initialize AppPage."""
        super().__init__(driver)
        self.logger = logger
    
    def wait_for_version_info_to_load(self, timeout=10):
        """Wait for version information to finish loading."""
        try:
            # Wait for either version details or error to appear
            wait = WebDriverWait(self.driver, timeout)
            wait.until(
                lambda d: self.is_element_present(*self.VERSION_DETAILS, timeout=1) or 
                         self.is_element_present(*self.VERSION_ERROR, timeout=1)
            )
            # If loading indicator is present, wait for it to disappear
            if self.is_element_present(*self.VERSION_LOADING, timeout=1):
                wait.until(EC.invisibility_of_element_located(self.VERSION_LOADING))
            return True
        except TimeoutException:
            self.logger.warning("Version info did not load within timeout")
            return False
    
    def get_version_info(self):
        """Get version information as a dictionary."""
        info = {}
        
        if not self.wait_for_version_info_to_load():
            return None
        
        # Check if there's an error
        if self.is_element_present(*self.VERSION_ERROR, timeout=2):
            error_text = self.get_text(*self.VERSION_ERROR, timeout=2)
            return {"error": error_text}
        
        # Get version items
        version_items = self.find_elements(*self.VERSION_ITEMS)
        for item in version_items:
            try:
                label_elem = item.find_element(*self.VERSION_LABEL)
                value_elem = item.find_element(*self.VERSION_VALUE)
                label = label_elem.text.strip()
                value = value_elem.text.strip()
                
                # Parse label to extract key
                if "Frontend React" in label:
                    info["react"] = value.split()[0]  # Get version number
                    info["react_vulnerable"] = "VULNERABLE" in value
                elif "React-DOM" in label:
                    info["react_dom"] = value
                elif "Backend Node.js" in label:
                    info["node"] = value
            except Exception as e:
                self.logger.warning(f"Error parsing version item: {e}")
        
        # Get status
        try:
            status_elem = self.find_element(*self.VERSION_STATUS, timeout=3)
            status_text = status_elem.text
            if "VULNERABLE" in status_text:
                info["status"] = "VULNERABLE"
            elif "FIXED" in status_text:
                info["status"] = "FIXED"
        except TimeoutException:
            pass
        
        return info
    
    def click_hello_button(self):
        """Click the 'press me to say hello' button."""
        self.click_element(*self.HELLO_BUTTON)
        self.logger.info("Clicked hello button")
    
    def get_message(self, timeout=5):
        """Get the message displayed after clicking button."""
        try:
            wait = WebDriverWait(self.driver, timeout)
            wait.until(EC.visibility_of_element_located(self.MESSAGE_DIV))
            message = self.get_text(*self.MESSAGE_DIV)
            return message
        except TimeoutException:
            self.logger.warning("Message did not appear within timeout")
            return None
    
    def is_button_enabled(self):
        """Check if hello button is enabled."""
        try:
            button = self.find_element(*self.HELLO_BUTTON)
            return button.is_enabled()
        except TimeoutException:
            return False
    
    def is_button_loading(self):
        """Check if button is in loading state."""
        try:
            button = self.find_element(*self.HELLO_BUTTON)
            button_text = button.text
            return "Loading" in button_text or not button.is_enabled()
        except TimeoutException:
            return False
    
    def get_button_text(self):
        """Get the text of the hello button."""
        try:
            return self.get_text(*self.HELLO_BUTTON)
        except TimeoutException:
            return None
    
    def is_version_info_visible(self):
        """Check if version info card is visible."""
        return self.is_element_visible(*self.VERSION_INFO_CARD)
    
    def is_vulnerable_indicator_visible(self):
        """Check if vulnerable indicator (⚠️) is visible."""
        try:
            # Check for vulnerable class in version value
            vulnerable_elements = self.find_elements(
                (By.CSS_SELECTOR, ".version-value.vulnerable")
            )
            return len(vulnerable_elements) > 0
        except Exception:
            return False
    
    def is_fixed_indicator_visible(self):
        """Check if fixed indicator (✅) is visible."""
        try:
            # Check for fixed class in version value
            fixed_elements = self.find_elements(
                (By.CSS_SELECTOR, ".version-value.fixed")
            )
            return len(fixed_elements) > 0
        except Exception:
            return False
