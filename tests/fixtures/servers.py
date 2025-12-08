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
from utils.server_constants import FRONTEND_URL, API_ENDPOINT


@pytest.fixture(scope="session")
def start_servers():
    """Start both frontend and backend servers before tests."""
    print("\n🚀 Starting servers...")
    
    # Check if servers are already running
    try:
        requests.get(FRONTEND_URL, timeout=2)
        requests.get(API_ENDPOINT, timeout=2)
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
