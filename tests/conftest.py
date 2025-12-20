"""
Pytest configuration and shared fixtures for Selenium tests.

This file now serves as the main pytest configuration file, importing
fixtures and plugins from organized modules.
"""
import pytest
import logging
from pathlib import Path

# Import fixtures from organized modules
# Pytest automatically discovers fixtures in conftest.py and subdirectories
# We import here to ensure they're available at the test level
from fixtures.webdriver import driver
from fixtures.servers import start_servers
from fixtures.app import app_page
from fixtures.version import react_version

logger = logging.getLogger(__name__)


@pytest.fixture(scope="session", autouse=True)
def verify_framework_mode():
    """Verify framework mode is set correctly before tests."""
    from utils.framework_detector import get_framework_mode
    
    # Get project root (assume we're in tests/, go up 1 level)
    project_root = Path(__file__).parent.parent
    framework_mode_file = project_root / ".framework-mode"
    
    # Get framework mode
    framework = get_framework_mode()
    
    # Log framework mode for debugging
    logger.info(f"Framework mode: {framework}")
    
    # Verify framework mode file exists
    if not framework_mode_file.exists():
        logger.warning(".framework-mode file not found")
    else:
        try:
            with open(framework_mode_file, "r") as f:
                framework_from_file = f.read().strip() or "vite"
            if framework_from_file != framework:
                logger.warning(f"Framework mode mismatch: detector={framework}, file={framework_from_file}")
            logger.info(f"Framework mode file: {framework_mode_file}, value: '{framework_from_file}'")
        except Exception as e:
            logger.warning(f"Could not read .framework-mode file: {e}")
    
    yield

# Import performance plugin
# The plugin hooks are automatically registered when the module is imported
import plugins.performance

# Test configuration - import from server_constants for consistency
# Use functions to get dynamic URLs
from utils.server_constants import (
    get_frontend_url,
    get_backend_url,
    _get_urls
)

# Get URLs dynamically
def get_base_url():
    """Get the base URL dynamically."""
    return get_frontend_url()

def get_api_url():
    """Get the API URL dynamically."""
    return get_backend_url()

# For backward compatibility, set BASE_URL and API_URL
# These will be evaluated at import time, but tests should use the functions
_urls = _get_urls()
BASE_URL = _urls["FRONTEND_URL"]
API_URL = _urls["BACKEND_URL"]
FRONTEND_PORT = _urls["FRONTEND_PORT"]
BACKEND_PORT = _urls["BACKEND_PORT"]


# Pytest command line options
def pytest_addoption(parser):
    """Add custom command line options."""
    parser.addoption(
        "--browser",
        action="store",
        default="chrome",
        choices=["chrome", "firefox", "safari"],
        help="Browser to use for tests (default: chrome)"
    )
    parser.addoption(
        "--headless",
        action="store",
        default="true",
        choices=["true", "false"],
        help="Run browser in headless mode (default: true)"
    )
    parser.addoption(
        "--update-baseline",
        action="store_true",
        default=False,
        help="Update performance baseline with current run results"
    )
    # Note: --base-url is provided by pytest-selenium plugin, don't add it here


def pytest_configure(config):
    """Configure pytest and register markers."""
    config.addinivalue_line(
        "markers", "smoke: Smoke tests - critical functionality (timeout: 10s)"
    )
    config.addinivalue_line(
        "markers", "regression: Regression tests"
    )
    config.addinivalue_line(
        "markers", "version_switch: Tests that switch React versions (timeout: 120s)"
    )
    config.addinivalue_line(
        "markers", "slow: Tests that take longer to run (timeout: 60s)"
    )
    config.addinivalue_line(
        "markers", "scanner: Scanner verification tests (requires external scanner)"
    )
    
    if config.getoption("--update-baseline"):
        import os
        os.environ['PYTEST_UPDATE_BASELINE'] = 'true'
