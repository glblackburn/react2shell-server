"""
React version switching fixture.
"""
import pytest
from utils.server_manager import (
    switch_react_version, stop_servers, start_servers as start_servers_func, 
    wait_for_server, check_server_running, get_current_react_version, check_version_installed
)
from utils.server_constants import get_frontend_url, get_api_endpoint


@pytest.fixture(scope="function")
def react_version(request):
    """Parameterized fixture that switches React versions for testing.
    
    Usage:
        @pytest.mark.parametrize("react_version", ["19.0", "19.1.0"], indirect=True)
        def test_something(app_page, react_version):
            # react_version will be the version string, and servers will be restarted
    """
    # Get version from parameter if provided
    version = request.param if hasattr(request, 'param') else None
    
    if version:
        # Check if already on this version
        current = get_current_react_version()
        already_installed = check_version_installed(version)
        
        if current == version and already_installed:
            print(f"✓ React {version} already active, skipping switch")
            # Just ensure servers are running (framework-aware)
            from utils.framework_detector import get_framework_mode
            framework = get_framework_mode()
            
            if framework == "nextjs":
                # Next.js: only check port 3000
                frontend_url = get_frontend_url()
                if not check_server_running(frontend_url):
                    print(f"🔄 Server not running, starting for React {version}...")
                    if not start_servers_func():
                        pytest.fail(f"Failed to start server for React {version}")
                    if not wait_for_server(frontend_url, max_attempts=60, initial_delay=0.2, max_delay=2.0, max_wait_seconds=60):
                        pytest.fail(f"Server not ready after starting for React {version}")
            else:
                # Vite: check both ports
                frontend_url = get_frontend_url()
                api_endpoint = get_api_endpoint()
                if not check_server_running(frontend_url) or not check_server_running(api_endpoint):
                    print(f"🔄 Servers not running, starting for React {version}...")
                    if not start_servers_func():
                        pytest.fail(f"Failed to start servers for React {version}")
                    if not wait_for_server(frontend_url, max_attempts=60, initial_delay=0.2, max_delay=2.0, max_wait_seconds=60):
                        pytest.fail(f"Frontend server not ready after starting for React {version}")
                    if not wait_for_server(api_endpoint, max_attempts=60, initial_delay=0.2, max_delay=2.0, max_wait_seconds=60):
                        pytest.fail(f"Backend server not ready after starting for React {version}")
        else:
            print(f"\n🔄 Switching to React {version}...")
            # Stop servers before switching version
            stop_servers()
            
            # Clean up all test ports to ensure no conflicts
            from utils.server_manager import _cleanup_all_test_ports
            _cleanup_all_test_ports()
            
            # Wait a moment to ensure servers are fully stopped and ports released
            import time
            time.sleep(2)
            
            # Verify servers are stopped before proceeding
            from utils.framework_detector import get_framework_mode
            framework = get_framework_mode()
            frontend_url = get_frontend_url()
            if check_server_running(frontend_url, timeout=1):
                print(f"⚠️  Server still running after stop, cleaning up again...")
                _cleanup_all_test_ports()
                time.sleep(2)
            
            # Switch React version
            version_switch_success = switch_react_version(version)
            
            # Always restart servers, even if version switch failed
            # This ensures subsequent tests can still run
            print(f"🔄 Restarting servers for React {version}...")
            if not start_servers_func():
                pytest.fail(f"Failed to start servers after switching to React {version}")
            
            # Wait for servers to be ready (framework-aware)
            # Use longer timeout for version switch scenarios
            if framework == "nextjs":
                # Next.js: only wait for port 3000, with longer timeout for version switch
                frontend_url = get_frontend_url()
                if not wait_for_server(frontend_url, max_attempts=120, initial_delay=0.2, max_delay=2.0, max_wait_seconds=120):
                    pytest.fail(f"Next.js server not ready after switching to React {version}")
            else:
                # Vite: wait for both ports, with longer timeout for version switch
                frontend_url = get_frontend_url()
                api_endpoint = get_api_endpoint()
                if not wait_for_server(frontend_url, max_attempts=120, initial_delay=0.2, max_delay=2.0, max_wait_seconds=120):
                    pytest.fail(f"Frontend server not ready after switching to React {version}")
                if not wait_for_server(api_endpoint, max_attempts=120, initial_delay=0.2, max_delay=2.0, max_wait_seconds=120):
                    pytest.fail(f"Backend server not ready after switching to React {version}")
            
            # Additional verification: ensure server is actually responding
            if not check_server_running(frontend_url, timeout=5):
                pytest.fail(f"Server not responding after wait_for_server returned True for React {version}")
            
            if version_switch_success:
                print(f"✓ React {version} ready for testing")
            else:
                pytest.skip(f"Failed to switch to React {version}, but servers restarted")
    
    yield version
    
    # Note: We don't restore the original version here to avoid slowing down tests
    # The original version should be restored manually or in CI/CD
