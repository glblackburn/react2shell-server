"""
Application page fixtures.
"""
import pytest
from pages.app_page import AppPage


@pytest.fixture(scope="function")
def app_page(driver):
    """Create AppPage instance and navigate to application."""
    page = AppPage(driver)
    page.navigate()
    return page
