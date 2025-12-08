"""
Test suite for security status and vulnerability indicators.
"""
import pytest
import subprocess
import json
import time


def get_current_react_version():
    """Get current React version from package.json."""
    try:
        with open("package.json", "r") as f:
            package = json.load(f)
            return package.get("dependencies", {}).get("react", "unknown")
    except Exception:
        return "unknown"


@pytest.mark.version_switch
@pytest.mark.slow
# Note: These tests switch React versions and should not run in parallel
# Use: pytest -m version_switch (without -n flag) to run sequentially
class TestSecurityStatus:
    """Tests for security status display."""
    
    @pytest.mark.parametrize("react_version,expected_status", [
        ("19.0", "VULNERABLE"),
        ("19.1.0", "VULNERABLE"),
        ("19.1.1", "VULNERABLE"),
        ("19.2.0", "VULNERABLE"),
    ], indirect=["react_version"])
    def test_vulnerable_versions_show_vulnerable_status(self, app_page, react_version, expected_status):
        """Test that vulnerable React versions show VULNERABLE status."""
        # react_version fixture switches to the version and restarts servers
        version_info = app_page.get_version_info()
        
        assert version_info is not None, \
            "Version info should be loaded"
        
        assert version_info.get("status") == expected_status, \
            f"Version {react_version} should show {expected_status} status, " \
            f"got {version_info.get('status')}"
        
        assert version_info.get("react") == react_version, \
            f"Expected React version {react_version}, got {version_info.get('react')}"
    
    @pytest.mark.parametrize("react_version,expected_status", [
        ("19.0.1", "FIXED"),
        ("19.1.2", "FIXED"),
        ("19.2.1", "FIXED"),
    ], indirect=["react_version"])
    def test_fixed_versions_show_fixed_status(self, app_page, react_version, expected_status):
        """Test that fixed React versions show FIXED status."""
        # react_version fixture switches to the version and restarts servers
        version_info = app_page.get_version_info()
        
        assert version_info is not None, \
            "Version info should be loaded"
        
        assert version_info.get("status") == expected_status, \
            f"Version {react_version} should show {expected_status} status, " \
            f"got {version_info.get('status')}"
        
        assert version_info.get("react") == react_version, \
            f"Expected React version {react_version}, got {version_info.get('react')}"
    
    def test_vulnerable_indicator_displayed(self, app_page):
        """Test that vulnerable indicator (⚠️) is displayed for vulnerable versions."""
        version_info = app_page.get_version_info()
        
        if version_info and version_info.get("status") == "VULNERABLE":
            # Check for vulnerable indicator
            from selenium.webdriver.common.by import By
            assert app_page.is_vulnerable_indicator_visible() or \
                   app_page.is_element_present(
                       By.CSS_SELECTOR, ".version-value.vulnerable",
                       timeout=2
                   ), \
                "Vulnerable indicator should be visible for vulnerable versions"
    
    def test_fixed_indicator_displayed(self, app_page):
        """Test that fixed indicator (✅) is displayed for fixed versions."""
        version_info = app_page.get_version_info()
        
        if version_info and version_info.get("status") == "FIXED":
            # Check for fixed indicator
            try:
                # Try to get version value text
                version_items = app_page.find_elements(*app_page.VERSION_ITEMS)
                for item in version_items:
                    try:
                        value_elem = item.find_element(*app_page.VERSION_VALUE)
                        if "✅" in value_elem.text or app_page.is_fixed_indicator_visible():
                            assert True
                            return
                    except Exception:
                        pass
            except Exception:
                pass
            assert app_page.is_fixed_indicator_visible(), \
                "Fixed indicator should be visible for fixed versions"
    
    def test_vulnerable_status_color(self, app_page):
        """Test that vulnerable status uses red color."""
        version_info = app_page.get_version_info()
        
        if version_info and version_info.get("status") == "VULNERABLE":
            # Check if status element has vulnerable class or red color
            try:
                status_elem = app_page.find_element(*app_page.STATUS_VULNERABLE, timeout=5)
                assert status_elem is not None, \
                    "Status element with vulnerable class should be present"
            except Exception:
                # If class-based check fails, verify status text
                status_text = app_page.get_text(*app_page.VERSION_STATUS, timeout=5)
                assert "VULNERABLE" in status_text, \
                    "Status should contain 'VULNERABLE'"
    
    def test_fixed_status_color(self, app_page):
        """Test that fixed status uses green color."""
        version_info = app_page.get_version_info()
        
        if version_info and version_info.get("status") == "FIXED":
            # Check if status element has fixed class or green color
            try:
                status_elem = app_page.find_element(*app_page.STATUS_FIXED, timeout=5)
                assert status_elem is not None, \
                    "Status element with fixed class should be present"
            except Exception:
                # If class-based check fails, verify status text
                status_text = app_page.get_text(*app_page.VERSION_STATUS, timeout=5)
                assert "FIXED" in status_text, \
                    "Status should contain 'FIXED'"
    
    def test_react_version_matches_status(self, app_page):
        """Test that React version correctly determines vulnerability status."""
        version_info = app_page.get_version_info()
        
        assert version_info is not None, \
            "Version info should be loaded"
        
        react_version = version_info.get("react")
        status = version_info.get("status")
        
        vulnerable_versions = ["19.0", "19.1.0", "19.1.1", "19.2.0"]
        fixed_versions = ["19.0.1", "19.1.2", "19.2.1"]
        
        if react_version in vulnerable_versions:
            assert status == "VULNERABLE", \
                f"Version {react_version} should be VULNERABLE, got {status}"
        elif react_version in fixed_versions:
            assert status == "FIXED", \
                f"Version {react_version} should be FIXED, got {status}"
