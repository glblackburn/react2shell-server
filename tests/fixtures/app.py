"""
Application page fixtures.
"""
import pytest
from pages.app_page import AppPage


@pytest.fixture(scope="function")
def app_page(driver, request):
    """Create AppPage instance and navigate to application.
    
    If react_version fixture is also used in the test, it will be executed first
    to ensure servers are ready before navigation.
    """
    # If react_version fixture is requested, get its value to ensure it runs first
    # This ensures react_version completes server restart before app_page tries to navigate
    if 'react_version' in request.fixturenames:
        try:
            request.getfixturevalue('react_version')
        except Exception:
            # If react_version fixture fails, we'll still try to navigate
            # but the server check below will catch if server isn't ready
            pass
    
    page = AppPage(driver)
    
    # Before navigating, verify server is ready
    # This is especially important when react_version fixture has just restarted servers
    from utils.server_manager import check_server_running
    from utils.server_constants import get_frontend_url
    import time
    
    frontend_url = get_frontend_url()
    max_attempts = 20
    for attempt in range(max_attempts):
        if check_server_running(frontend_url, timeout=5):
            break
        if attempt < max_attempts - 1:
            time.sleep(1.0)
    else:
        # Server not ready after all attempts
        raise Exception(f"Server not ready at {frontend_url} after {max_attempts} attempts. Cannot navigate.")
    
    page.navigate()
    # Wait for page to be ready (React hydration)
    page.wait_for_page_ready()
    return page
