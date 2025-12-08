"""
Server management fixtures for tests.
"""
import pytest
import requests
import subprocess
from utils.server_manager import (
    start_servers as start_servers_func,
    stop_servers as stop_servers_func,
    wait_for_server,
    check_server_running
)
from utils.server_constants import get_frontend_url, get_api_endpoint


@pytest.fixture(scope="session")
def start_servers():
    """Start servers before tests (framework-aware)."""
    from utils.framework_detector import get_framework_mode
    
    framework = get_framework_mode()
    print(f"\n🚀 Starting servers (Framework: {framework})...")
    
    # Check if servers are already running
    try:
        frontend_url = get_frontend_url()
        requests.get(frontend_url, timeout=2)
        if framework == "vite":
            api_endpoint = get_api_endpoint()
            requests.get(api_endpoint, timeout=2)
        print("✓ Servers already running")
        yield
        return
    except requests.exceptions.RequestException:
        pass
    
    # Start servers using server_manager
    try:
        if start_servers_func():
            print("✓ Started servers")
        else:
            pytest.fail("Servers failed to start or become ready")
        
        yield
        
    finally:
        # Stop servers after tests
        print("\n🛑 Stopping servers...")
        stop_servers_func()
        print("✓ Servers stopped")
