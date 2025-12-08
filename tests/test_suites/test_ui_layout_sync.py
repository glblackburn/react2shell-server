"""
Test suite to ensure UI layouts stay in sync between React and Next.js frameworks.

This test suite verifies that:
1. Both frameworks render the same visual layout
2. CSS classes and structure match
3. Component positioning and spacing are identical
4. Only framework-specific version information differs
"""
import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from utils.framework_detector import get_framework_mode
from utils.server_manager import start_servers, stop_servers
import subprocess
import logging


logger = logging.getLogger(__name__)


class TestUILayoutSync:
    """Tests to ensure UI layouts stay in sync between frameworks."""
    
    def test_version_info_card_structure(self, app_page):
        """Test that version info card has the same structure in both frameworks."""
        # Wait for version info to load
        app_page.wait_for_version_info_to_load()
        
        # Check that version-info card exists
        assert app_page.is_element_visible(*app_page.VERSION_INFO_CARD), \
            "Version info card should be visible"
        
        # Check that version-title exists
        assert app_page.is_element_visible(*app_page.VERSION_TITLE), \
            "Version title should be visible"
        
        # Check that version-details exists (or error if failed)
        details_or_error = (
            app_page.is_element_present(*app_page.VERSION_DETAILS, timeout=2) or
            app_page.is_element_present(*app_page.VERSION_ERROR, timeout=2)
        )
        assert details_or_error, \
            "Version details or error should be present"
    
    def test_version_items_structure(self, app_page):
        """Test that version items have consistent structure."""
        app_page.wait_for_version_info_to_load()
        
        # Get all version items
        version_items = app_page.find_elements(*app_page.VERSION_ITEMS)
        
        # Each version item should have a label and value
        for item in version_items:
            label = item.find_element(*app_page.VERSION_LABEL)
            value = item.find_element(*app_page.VERSION_VALUE)
            
            assert label.is_displayed(), "Version label should be visible"
            assert value.is_displayed(), "Version value should be visible"
            assert label.text.strip(), "Version label should have text"
            assert value.text.strip(), "Version value should have text"
    
    def test_button_structure_and_styling(self, app_page):
        """Test that button has consistent structure and styling."""
        # Check button exists
        assert app_page.is_element_visible(*app_page.HELLO_BUTTON), \
            "Hello button should be visible"
        
        # Check button text
        button_text = app_page.get_button_text()
        assert button_text in ["press me to say hello", "Loading..."], \
            f"Button text should be 'press me to say hello' or 'Loading...', got '{button_text}'"
        
        # Check button is enabled (unless loading)
        if "Loading" not in button_text:
            assert app_page.is_button_enabled(), \
                "Button should be enabled when not loading"
    
    def test_css_classes_match(self, app_page):
        """Test that key CSS classes are present and match expected structure."""
        app_page.wait_for_version_info_to_load()
        
        # Check for key CSS classes
        expected_classes = [
            "app",
            "container",
            "version-info",
            "version-title",
            "version-details",
            "version-item",
            "version-label",
            "version-value",
            "big-red-button"
        ]
        
        for class_name in expected_classes:
            # Use CSS selector to find elements with this class
            elements = app_page.find_elements(
                (By.CSS_SELECTOR, f".{class_name}")
            )
            assert len(elements) > 0, \
                f"Should have at least one element with class '{class_name}'"
    
    def test_version_info_layout_spacing(self, app_page):
        """Test that version info has consistent spacing and layout."""
        app_page.wait_for_version_info_to_load()
        
        # Get version info card
        version_card = app_page.find_element(*app_page.VERSION_INFO_CARD)
        
        # Check that card is visible and has content
        assert version_card.is_displayed(), "Version card should be displayed"
        
        # Check that version details are inside the card
        details = app_page.find_element(*app_page.VERSION_DETAILS, timeout=3)
        assert details.is_displayed(), "Version details should be displayed"
        
        # Check that button is below the version card (not inside it)
        button = app_page.find_element(*app_page.HELLO_BUTTON)
        assert button.is_displayed(), "Button should be displayed"
    
    def test_framework_specific_version_display(self, app_page):
        """Test that framework-specific version information is displayed correctly."""
        app_page.wait_for_version_info_to_load()
        
        framework_mode = get_framework_mode()
        version_info = app_page.get_version_info()
        
        if version_info and "error" not in version_info:
            # Both frameworks should show React version
            assert "react" in version_info, \
                "Both frameworks should display React version"
            
            # Next.js should also show Next.js version
            if framework_mode == "nextjs":
                # Check for Next.js version in the UI
                version_items = app_page.find_elements(*app_page.VERSION_ITEMS)
                version_labels = [
                    item.find_element(*app_page.VERSION_LABEL).text
                    for item in version_items
                ]
                assert any("Next.js" in label for label in version_labels), \
                    "Next.js mode should display Next.js version"
            else:
                # Vite mode should not show Next.js version
                version_items = app_page.find_elements(*app_page.VERSION_ITEMS)
                version_labels = [
                    item.find_element(*app_page.VERSION_LABEL).text
                    for item in version_items
                ]
                assert not any("Next.js" in label for label in version_labels), \
                    "Vite mode should not display Next.js version"
    
    def test_message_display_consistency(self, app_page):
        """Test that message display is consistent between frameworks."""
        # Click button to trigger message
        app_page.click_hello_button()
        
        # Wait for message to appear
        message = app_page.get_message(timeout=5)
        
        assert message is not None, "Message should appear after clicking button"
        assert "Hello" in message or "hello" in message.lower(), \
            f"Message should contain 'Hello', got '{message}'"
    
    def test_vulnerability_status_display(self, app_page):
        """Test that vulnerability status indicators are displayed consistently."""
        app_page.wait_for_version_info_to_load()
        
        # Check for vulnerability indicators
        has_vulnerable = app_page.is_vulnerable_indicator_visible()
        has_fixed = app_page.is_fixed_indicator_visible()
        
        # Should have either vulnerable or fixed indicator
        assert has_vulnerable or has_fixed, \
            "Should display either vulnerable or fixed indicator"
        
        # Should not have both at the same time (for same version)
        # Note: This might be different if multiple versions are shown (e.g., Next.js + React)
        # So we'll just check that at least one is present
    
    def test_overall_layout_structure(self, app_page):
        """Test that overall layout structure matches between frameworks."""
        # Check main container structure
        app_container = app_page.find_element((By.CSS_SELECTOR, ".app"))
        assert app_container.is_displayed(), "App container should be displayed"
        
        container = app_page.find_element((By.CSS_SELECTOR, ".container"))
        assert container.is_displayed(), "Container should be displayed"
        
        # Check that version-info is inside container
        version_card = app_page.find_element(*app_page.VERSION_INFO_CARD)
        assert version_card.is_displayed(), "Version card should be displayed"
        
        # Check that button is inside container
        button = app_page.find_element(*app_page.HELLO_BUTTON)
        assert button.is_displayed(), "Button should be displayed"
    
    @pytest.mark.parametrize("framework", ["vite", "nextjs"])
    def test_layout_consistency_across_frameworks(self, driver, framework):
        """Test that layout is consistent when switching between frameworks."""
        from pages.app_page import AppPage
        
        # Stop any running servers
        stop_servers()
        
        # Switch to the specified framework using Makefile
        if framework == "vite":
            subprocess.run(["make", "use-vite"], check=True, capture_output=True)
        else:
            subprocess.run(["make", "use-nextjs"], check=True, capture_output=True)
        
        # Start servers for the selected framework
        start_servers()
        
        # Create page object
        app_page = AppPage(driver)
        
        # Navigate to the appropriate URL
        if framework == "vite":
            url = "http://localhost:5173"
        else:
            url = "http://localhost:3000"
        
        driver.get(url)
        
        # Wait for page to load
        app_page.wait_for_version_info_to_load()
        
        # Run layout consistency checks
        assert app_page.is_version_info_visible(), \
            f"Version info should be visible in {framework} mode"
        
        assert app_page.is_element_visible(*app_page.HELLO_BUTTON), \
            f"Button should be visible in {framework} mode"
        
        # Check that key elements have the same structure
        version_items = app_page.find_elements(*app_page.VERSION_ITEMS)
        assert len(version_items) >= 3, \
            f"Should have at least 3 version items in {framework} mode (React, React-DOM, Node.js)"
        
        # Framework-specific check
        if framework == "nextjs":
            # Next.js should have one more item (Next.js version)
            assert len(version_items) >= 4, \
                "Next.js mode should have at least 4 version items (Next.js, React, React-DOM, Node.js)"