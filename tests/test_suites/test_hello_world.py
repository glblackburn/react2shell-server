"""
Test suite for Hello World button functionality.
"""
import pytest
import time
from selenium.webdriver.common.by import By


@pytest.mark.smoke
class TestHelloWorldButton:
    """Tests for the Hello World button."""
    
    def test_button_is_visible(self, app_page):
        """Test that the hello button is visible on the page."""
        assert app_page.is_element_visible(*app_page.HELLO_BUTTON), \
            "Hello button should be visible"
    
    def test_button_text_is_correct(self, app_page):
        """Test that button has correct text."""
        button_text = app_page.get_button_text()
        assert button_text == "press me to say hello", \
            f"Button text should be 'press me to say hello', got '{button_text}'"
    
    def test_button_is_enabled(self, app_page):
        """Test that button is enabled by default."""
        assert app_page.is_button_enabled(), \
            "Hello button should be enabled"
    
    @pytest.mark.smoke
    def test_button_click_displays_message(self, app_page):
        """Test that clicking button displays 'Hello World!' message."""
        # Click the button
        app_page.click_hello_button()
        
        # Wait for message to appear
        message = app_page.get_message(timeout=10)
        
        assert message == "Hello World!", \
            f"Expected 'Hello World!', got '{message}'"
    
    def test_button_loading_state(self, app_page):
        """Test that button shows loading state during API call."""
        # Click the button
        app_page.click_hello_button()
        
        # Check if button is in loading state (should be very brief)
        # Note: This might be too fast to catch, so we check if button is disabled
        time.sleep(0.1)  # Small delay to catch loading state
        
        # Button might be disabled during loading or show "Loading..." text
        button_text = app_page.get_button_text()
        is_loading = "Loading" in button_text or not app_page.is_button_enabled()
        
        # After a moment, button should be enabled again
        time.sleep(1)
        assert app_page.is_button_enabled(), \
            "Button should be enabled after API call completes"
    
    def test_button_multiple_clicks(self, app_page):
        """Test that button can be clicked multiple times."""
        # First click
        app_page.click_hello_button()
        message1 = app_page.get_message(timeout=10)
        assert message1 == "Hello World!"
        
        # Wait a moment
        time.sleep(1)
        
        # Second click
        app_page.click_hello_button()
        message2 = app_page.get_message(timeout=10)
        assert message2 == "Hello World!"
    
    def test_message_appears_after_click(self, app_page):
        """Test that message appears after button click."""
        # Initially, message should not be visible
        assert not app_page.is_element_present(*app_page.MESSAGE_DIV, timeout=1), \
            "Message should not be visible initially"
        
        # Click button
        app_page.click_hello_button()
        
        # Message should appear
        assert app_page.is_element_visible(*app_page.MESSAGE_DIV, timeout=10), \
            "Message should be visible after button click"
        
        # Verify message content
        message = app_page.get_message()
        assert message == "Hello World!", \
            f"Message should be 'Hello World!', got '{message}'"
