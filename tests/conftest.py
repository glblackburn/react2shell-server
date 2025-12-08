"""
Pytest configuration and shared fixtures for Selenium tests.

This file now serves as the main pytest configuration file, importing
fixtures and plugins from organized modules.
"""
import pytest

# Import fixtures from organized modules
# Pytest automatically discovers fixtures in conftest.py and subdirectories
# We import here to ensure they're available at the test level
from fixtures.webdriver import driver
from fixtures.servers import start_servers
from fixtures.app import app_page
from fixtures.version import react_version

# Import performance plugin
# The plugin hooks are automatically registered when the module is imported
import plugins.performance

# Test configuration - import from server_constants for consistency
from utils.server_constants import (
    FRONTEND_URL as BASE_URL,
    BACKEND_URL as API_URL,
    FRONTEND_PORT,
    BACKEND_PORT
)


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
