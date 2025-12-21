"""
Test suite for Next.js version API verification.

These tests verify that all Next.js versions can start and the version API
returns the correct version information.
"""
import pytest
import subprocess
import requests
import time
import json
from utils.server_manager import (
    stop_servers,
    start_servers,
    check_server_running,
    wait_for_server
)
from utils.server_constants import get_version_endpoint
from utils.nextjs_version_constants import ALL_NEXTJS_VERSIONS
from utils.framework_detector import get_framework_mode


@pytest.mark.smoke
class TestNextJSVersionAPI:
    """Tests for Next.js version API verification."""

    def test_all_nextjs_versions_start_and_respond(self):
        """Verify all Next.js versions can start and API responds."""
        # Ensure we're in Next.js mode
        framework = get_framework_mode()
        if framework != "nextjs":
            pytest.skip("This test requires Next.js mode. Run 'make use-nextjs' first.")
        
        results = []
        
        for version in ALL_NEXTJS_VERSIONS:
            try:
                # Stop any running servers
                stop_servers()
                time.sleep(1)  # Brief pause to ensure servers are stopped
                
                # Switch to version
                result = subprocess.run(
                    ["make", f"nextjs-{version}"],
                    check=True,
                    capture_output=True,
                    text=True,
                    timeout=300
                )
                
                # Start servers
                if not start_servers():
                    results.append({
                        "version": version,
                        "status": "FAILED",
                        "error": "Failed to start servers"
                    })
                    continue
                
                # Wait for server to be ready
                api_url = get_version_endpoint()
                if not wait_for_server(api_url, max_attempts=60, initial_delay=0.5, max_delay=2.0, max_wait_seconds=60):
                    results.append({
                        "version": version,
                        "status": "FAILED",
                        "error": "Server not ready after 60 seconds"
                    })
                    stop_servers()
                    continue
                
                # Call version API
                try:
                    response = requests.get(api_url, timeout=5)
                    response.raise_for_status()
                    data = response.json()
                    
                    # Verify response structure
                    assert "nextjs" in data, f"Version API response missing 'nextjs' field for {version}"
                    
                    results.append({
                        "version": version,
                        "status": "PASSED",
                        "api_version": data.get("nextjs"),
                        "expected": version
                    })
                except Exception as e:
                    results.append({
                        "version": version,
                        "status": "FAILED",
                        "error": f"API call failed: {str(e)}"
                    })
                
                # Stop servers
                stop_servers()
                time.sleep(1)  # Brief pause between versions
                
            except subprocess.CalledProcessError as e:
                results.append({
                    "version": version,
                    "status": "FAILED",
                    "error": f"Version switch failed: {e.stderr}"
                })
                stop_servers()
            except Exception as e:
                results.append({
                    "version": version,
                    "status": "FAILED",
                    "error": f"Unexpected error: {str(e)}"
                })
                stop_servers()
        
        # Report results
        failed = [r for r in results if r["status"] == "FAILED"]
        passed = [r for r in results if r["status"] == "PASSED"]
        
        if failed:
            error_msg = f"Failed versions: {', '.join([f['version'] for f in failed])}\n"
            for f in failed:
                error_msg += f"  {f['version']}: {f.get('error', 'Unknown error')}\n"
            pytest.fail(error_msg)
        
        # Verify all versions passed
        assert len(passed) == len(ALL_NEXTJS_VERSIONS), \
            f"Expected {len(ALL_NEXTJS_VERSIONS)} versions to pass, got {len(passed)}"

    @pytest.mark.parametrize("nextjs_version", ALL_NEXTJS_VERSIONS)
    def test_nextjs_version_api_returns_correct_version(self, nextjs_version):
        """Verify version API returns correct Next.js version for each version."""
        # Ensure we're in Next.js mode
        framework = get_framework_mode()
        if framework != "nextjs":
            pytest.skip("This test requires Next.js mode. Run 'make use-nextjs' first.")
        
        # Stop any running servers
        stop_servers()
        time.sleep(1)
        
        try:
            # Switch to version
            subprocess.run(
                ["make", f"nextjs-{nextjs_version}"],
                check=True,
                capture_output=True,
                text=True,
                timeout=300
            )
            
            # Start servers
            assert start_servers(), f"Failed to start servers for Next.js {nextjs_version}"
            
            # Wait for server to be ready
            api_url = get_version_endpoint()
            assert wait_for_server(api_url, max_attempts=60, initial_delay=0.5, max_delay=2.0, max_wait_seconds=60), \
                f"Server not ready for Next.js {nextjs_version}"
            
            # Call version API
            response = requests.get(api_url, timeout=5)
            response.raise_for_status()
            data = response.json()
            
            # Verify nextjs version matches
            actual_version = data.get("nextjs")
            assert actual_version == nextjs_version, \
                f"Expected Next.js version {nextjs_version}, got {actual_version}"
            
        finally:
            # Always stop servers
            stop_servers()
            time.sleep(1)

    def test_nextjs_version_api_structure(self):
        """Verify version API returns expected JSON structure."""
        # Ensure we're in Next.js mode
        framework = get_framework_mode()
        if framework != "nextjs":
            pytest.skip("This test requires Next.js mode. Run 'make use-nextjs' first.")
        
        # Use a known version (16.0.6)
        test_version = "16.0.6"
        
        # Stop any running servers
        stop_servers()
        time.sleep(1)
        
        try:
            # Switch to version
            subprocess.run(
                ["make", f"nextjs-{test_version}"],
                check=True,
                capture_output=True,
                text=True,
                timeout=300
            )
            
            # Start servers
            assert start_servers(), "Failed to start servers"
            
            # Wait for server to be ready
            api_url = get_version_endpoint()
            assert wait_for_server(api_url, max_attempts=60, initial_delay=0.5, max_delay=2.0, max_wait_seconds=60), \
                "Server not ready"
            
            # Call version API
            response = requests.get(api_url, timeout=5)
            response.raise_for_status()
            data = response.json()
            
            # Verify required fields exist
            required_fields = ["nextjs", "react", "node"]
            for field in required_fields:
                assert field in data, f"Version API response missing required field: {field}"
            
            # Verify field types
            assert isinstance(data.get("nextjs"), str), "nextjs field should be string"
            assert isinstance(data.get("react"), str), "react field should be string"
            assert isinstance(data.get("node"), str), "node field should be string"
            
            # Check for optional fields (may or may not be present)
            if "reactDom" in data or "react_dom" in data:
                react_dom = data.get("reactDom") or data.get("react_dom")
                assert isinstance(react_dom, str), "reactDom/react_dom field should be string"
            
            if "vulnerable" in data:
                assert isinstance(data.get("vulnerable"), bool), "vulnerable field should be boolean"
            
            if "status" in data:
                status = data.get("status")
                assert status in ["VULNERABLE", "FIXED"], \
                    f"status field should be 'VULNERABLE' or 'FIXED', got '{status}'"
            
        finally:
            # Always stop servers
            stop_servers()
            time.sleep(1)

    def test_nextjs_version_api_server_ready(self):
        """Verify server is ready before calling API."""
        # Ensure we're in Next.js mode
        framework = get_framework_mode()
        if framework != "nextjs":
            pytest.skip("This test requires Next.js mode. Run 'make use-nextjs' first.")
        
        # Use a known version
        test_version = "16.0.6"
        
        # Stop any running servers
        stop_servers()
        time.sleep(1)
        
        try:
            # Switch to version
            subprocess.run(
                ["make", f"nextjs-{test_version}"],
                check=True,
                capture_output=True,
                text=True,
                timeout=300
            )
            
            # Start servers
            assert start_servers(), "Failed to start servers"
            
            # Wait for server to be ready (check port 3000)
            frontend_url = "http://localhost:3000"
            assert wait_for_server(frontend_url, max_attempts=60, initial_delay=0.5, max_delay=2.0, max_wait_seconds=60), \
                "Server not ready on port 3000"
            
            # Verify server is actually responding
            assert check_server_running(frontend_url, timeout=5), \
                "Server check failed even after wait_for_server returned True"
            
            # Call version API
            api_url = get_api_endpoint().replace("/api/hello", "/api/version")
            response = requests.get(api_url, timeout=5)
            
            # Verify response is successful
            assert response.status_code == 200, \
                f"Expected status code 200, got {response.status_code}"
            
            # Verify response is valid JSON
            data = response.json()
            assert "nextjs" in data, "API response should contain 'nextjs' field"
            
        finally:
            # Always stop servers
            stop_servers()
            time.sleep(1)
