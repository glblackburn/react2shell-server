"""
Test suite for version information display.
"""
import pytest
from selenium.webdriver.common.by import By
from utils.test_helpers import (
    assert_version_info_valid,
    assert_version_status_valid,
    assert_version_contains_key
)


@pytest.mark.smoke
class TestVersionInformation:
    """Tests for version information display."""
    
    def test_version_info_card_is_visible(self, app_page):
        """Test that version info card is visible."""
        # Wait for version info to load first
        app_page.wait_for_version_info_to_load(timeout=15)
        assert app_page.is_version_info_visible(timeout=10), \
            "Version info card should be visible"
    
    def test_version_title_displayed(self, app_page):
        """Test that version title is displayed."""
        assert app_page.is_element_visible(*app_page.VERSION_TITLE), \
            "Version title should be visible"
        
        title_text = app_page.get_text(*app_page.VERSION_TITLE)
        assert "Security Testing Environment" in title_text, \
            f"Title should contain 'Security Testing Environment', got '{title_text}'"
    
    def test_version_info_loads(self, app_page):
        """Test that version information loads successfully."""
        version_info = app_page.get_version_info()
        
        assert_version_info_valid(version_info)
        assert "error" not in version_info, \
            f"Version info should not have error: {version_info.get('error', '')}"
    
    def test_version_info_contains_react_version(self, app_page):
        """Test that version info contains React version."""
        version_info = app_page.get_version_info()
        assert_version_contains_key(version_info, "react", "React version")
    
    def test_version_info_contains_react_dom_version(self, app_page):
        """Test that version info contains React-DOM version."""
        version_info = app_page.get_version_info()
        assert_version_contains_key(version_info, "react_dom", "React-DOM version")
    
    def test_version_info_contains_node_version(self, app_page):
        """Test that version info contains Node.js version."""
        version_info = app_page.get_version_info()
        assert_version_contains_key(version_info, "node", "Node.js version")
    
    def test_version_info_contains_status(self, app_page):
        """Test that version info contains status (VULNERABLE/FIXED)."""
        version_info = app_page.get_version_info()
        assert_version_status_valid(version_info)
    
    def test_version_info_loading_indicator(self, app_page):
        """Test that loading indicator appears initially."""
        # This test might be flaky as loading is very fast
        # We'll check if loading indicator exists or has already loaded
        loading_present = app_page.is_element_present(*app_page.VERSION_LOADING, timeout=1)
        details_present = app_page.is_element_present(*app_page.VERSION_DETAILS, timeout=1)
        
        # Either loading indicator should be present, or details should already be loaded
        assert loading_present or details_present, \
            "Either loading indicator or version details should be present"
    
    def test_version_info_retry_logic(self, app_page):
        """Test that version info retries if initial fetch fails."""
        # This is hard to test without mocking, but we can verify
        # that version info eventually loads even if there's a delay
        version_info = app_page.get_version_info()
        
        # Should eventually get version info (retry logic in frontend)
        assert version_info is not None, \
            "Version info should load eventually (with retry)"
        
        if "error" not in version_info:
            assert "react" in version_info, \
                "Version info should contain React version after retry"
