"""
Application page fixtures.
"""
import pytest
from pages.app_page import AppPage


@pytest.fixture(scope="function")
def app_page(driver):
    """Create AppPage instance and navigate to application."""
    page = AppPage(driver)
    
    # Before navigating, verify server is ready
    # This is especially important when react_version fixture has just restarted servers
    from utils.server_manager import check_server_running
    from utils.server_constants import get_frontend_url
    import time
    
    frontend_url = get_frontend_url()
    max_attempts = 10
    for attempt in range(max_attempts):
        if check_server_running(frontend_url, timeout=2):
            break
        if attempt < max_attempts - 1:
            time.sleep(0.5)
    else:
        # Server not ready after all attempts
        raise Exception(f"Server not ready at {frontend_url} after {max_attempts} attempts. Cannot navigate.")
    
    page.navigate()
    # Wait for page to be ready (React hydration)
    page.wait_for_page_ready()
    return page
