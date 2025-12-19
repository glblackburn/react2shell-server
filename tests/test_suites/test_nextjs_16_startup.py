"""
Test Next.js 16.0.6 server startup and functionality.

This test verifies that Next.js 16.0.6 can be switched to and started successfully.
Note: Next.js 16.0.6 is patched to work with Node.js 18.20.8, so tests will run
regardless of Node.js version.
"""
import pytest
import subprocess
import time
import requests
import os
import sys
from pathlib import Path

# Add tests directory to path for imports
tests_dir = Path(__file__).parent.parent
sys.path.insert(0, str(tests_dir))

from utils.server_manager import start_servers, stop_servers, wait_for_server, check_server_running
from utils.framework_detector import get_framework_mode
from utils.server_constants import get_frontend_url, get_api_endpoint


@pytest.fixture(scope="module")
def ensure_nextjs_mode():
    """Ensure we're in Next.js mode before running tests."""
    project_root = Path(__file__).parent.parent.parent
    framework_mode_file = project_root / ".framework-mode"
    
    # Read current mode
    current_mode = None
    if framework_mode_file.exists():
        current_mode = framework_mode_file.read_text().strip()
    
    # Switch to Next.js if not already
    if current_mode != "nextjs":
        result = subprocess.run(
            ["make", "use-nextjs"],
            cwd=project_root,
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode != 0:
            pytest.skip(f"Failed to switch to Next.js mode: {result.stderr}")
    
    yield
    
    # Restore original mode if needed
    if current_mode and current_mode != "nextjs":
        subprocess.run(
            ["make", f"use-{current_mode}"],
            cwd=project_root,
            capture_output=True,
            timeout=10
        )


@pytest.fixture(scope="module")
def check_node_version():
    """Check Node.js version (for informational purposes only).
    
    Note: Next.js 16.0.6 is patched to work with Node.js 18.20.8,
    so tests will run regardless of Node.js version.
    """
    result = subprocess.run(
        ["node", "--version"],
        capture_output=True,
        text=True
    )
    if result.returncode != 0:
        pytest.skip("Node.js not found")
    
    # Extract version number (e.g., "v18.20.8" -> (18, 20, 8))
    version_str = result.stdout.strip().lstrip("v")
    try:
        major, minor, patch = map(int, version_str.split("."))
        # Don't skip - Next.js 16.0.6 is patched to work with any Node.js version
        # Just return version info for potential logging
        return (major, minor, patch)
    except ValueError:
        # Still don't skip - just return None if we can't parse
        return None


@pytest.fixture(scope="function")
def switch_to_nextjs_16():
    """Switch to Next.js 16.0.6 and yield, then cleanup."""
    project_root = Path(__file__).parent.parent.parent
    
    # Switch to Next.js 16.0.6
    result = subprocess.run(
        ["make", "nextjs-16.0.6"],
        cwd=project_root,
        capture_output=True,
        text=True,
        timeout=60
    )
    
    if result.returncode != 0:
        pytest.fail(f"Failed to switch to Next.js 16.0.6: {result.stderr}")
    
    yield
    
    # Cleanup: stop servers
    stop_servers()


class TestNextJS16Startup:
    """Test Next.js 16.0.6 startup and functionality."""
    
    @pytest.mark.slow
    def test_switch_to_nextjs_16(self, ensure_nextjs_mode, switch_to_nextjs_16):
        """Test that we can switch to Next.js 16.0.6."""
        # The fixture handles the switch, just verify we're in Next.js mode
        assert get_framework_mode() == "nextjs", "Should be in Next.js mode"
    
    @pytest.mark.slow
    def test_nextjs_16_server_starts(
        self, 
        ensure_nextjs_mode, 
        check_node_version,
        switch_to_nextjs_16
    ):
        """Test that Next.js 16.0.6 server starts successfully."""
        # Stop any existing servers
        stop_servers()
        time.sleep(1)
        
        # Start servers
        started = start_servers()
        assert started, "Failed to start servers"
        
        # Wait for server to be ready (start_servers already waits, but verify)
        frontend_url = get_frontend_url()
        max_wait = 30  # Next.js typically starts in 1-2 seconds after patching
        ready = wait_for_server(frontend_url, max_attempts=max_wait, delay=1)
        
        if not ready:
            # Check server log for errors
            project_root = Path(__file__).parent.parent.parent
            log_file = project_root / ".logs" / "server.log"
            log_content = ""
            if log_file.exists():
                log_content = log_file.read_text()
            
            # Also check if process is running
            import os
            pid_file = project_root / ".pids" / "nextjs.pid"
            pid_info = ""
            if pid_file.exists():
                try:
                    with open(pid_file) as f:
                        pid = int(f.read().strip())
                    # Check if process exists
                    try:
                        os.kill(pid, 0)
                        pid_info = f"Process {pid} is running"
                    except OSError:
                        pid_info = f"Process {pid} is NOT running"
                except Exception as e:
                    pid_info = f"Could not check PID: {e}"
            
            pytest.fail(
                f"Server did not become ready at {frontend_url} within {max_wait} seconds.\n"
                f"{pid_info}\n"
                f"Server log (last 2000 chars):\n{log_content[-2000:]}"  # Last 2000 chars
            )
        
        # Verify server is actually responding
        assert check_server_running(frontend_url), "Server should be running"
    
    @pytest.mark.slow
    def test_nextjs_16_homepage_loads(
        self,
        ensure_nextjs_mode,
        check_node_version,
        switch_to_nextjs_16
    ):
        """Test that Next.js 16.0.6 homepage loads correctly."""
        # Ensure servers are running
        stop_servers()
        time.sleep(1)
        start_servers()
        
        frontend_url = get_frontend_url()
        ready = wait_for_server(frontend_url, max_attempts=30, delay=1)
        assert ready, f"Server should be ready at {frontend_url}"
        
        # Make request to homepage
        try:
            response = requests.get(frontend_url, timeout=10)
            assert response.status_code == 200, f"Expected 200, got {response.status_code}"
            assert len(response.text) > 0, "Response should have content"
        except requests.exceptions.RequestException as e:
            pytest.fail(f"Failed to load homepage: {e}")
    
    @pytest.mark.slow
    def test_nextjs_16_api_endpoint(
        self,
        ensure_nextjs_mode,
        check_node_version,
        switch_to_nextjs_16
    ):
        """Test that Next.js 16.0.6 API endpoint works."""
        # Ensure servers are running
        stop_servers()
        time.sleep(1)
        start_servers()
        
        frontend_url = get_frontend_url()
        ready = wait_for_server(frontend_url, max_attempts=30, delay=1)
        assert ready, f"Server should be ready at {frontend_url}"
        
        # Test API endpoint
        api_url = get_api_endpoint()
        try:
            response = requests.get(api_url, timeout=10)
            assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        except requests.exceptions.RequestException as e:
            pytest.fail(f"Failed to access API endpoint {api_url}: {e}")
    
    @pytest.mark.slow
    def test_nextjs_16_version_api(
        self,
        ensure_nextjs_mode,
        check_node_version,
        switch_to_nextjs_16
    ):
        """Test that Next.js 16.0.6 version API returns correct version."""
        # Ensure servers are running
        stop_servers()
        time.sleep(1)
        start_servers()
        
        frontend_url = get_frontend_url()
        ready = wait_for_server(frontend_url, max_attempts=30, delay=1)
        assert ready, f"Server should be ready at {frontend_url}"
        
        # Test version API
        version_url = f"{frontend_url}/api/version"
        try:
            response = requests.get(version_url, timeout=10)
            assert response.status_code == 200, f"Expected 200, got {response.status_code}"
            
            data = response.json()
            assert "nextjs" in data, "Response should include Next.js version"
            assert data["nextjs"] == "16.0.6", f"Expected Next.js 16.0.6, got {data.get('nextjs')}"
        except requests.exceptions.RequestException as e:
            pytest.fail(f"Failed to access version API {version_url}: {e}")
        except ValueError as e:
            pytest.fail(f"Version API did not return valid JSON: {e}")
