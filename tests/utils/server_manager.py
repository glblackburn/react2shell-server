"""
Utility functions for managing server lifecycle in tests.
"""
import subprocess
import time
import requests
import logging
import json
import os
from .server_constants import (
    FRONTEND_URL,
    BACKEND_URL,
    API_ENDPOINT
)


logger = logging.getLogger(__name__)


def check_server_running(url, timeout=1):
    """Check if a server is running at the given URL."""
    try:
        response = requests.get(url, timeout=timeout)
        return response.status_code == 200
    except requests.exceptions.RequestException:
        return False


def wait_for_server(url, max_attempts=30, delay=1):
    """Wait for server to be ready."""
    for attempt in range(max_attempts):
        if check_server_running(url, timeout=0.5):  # Reduced timeout
            logger.info(f"Server ready at {url}")
            return True
        if attempt < max_attempts - 1:  # Don't sleep on last attempt
            logger.debug(f"Waiting for server at {url} (attempt {attempt + 1}/{max_attempts})")
            time.sleep(delay)
    return False


def start_servers():
    """Start both frontend and backend servers using Makefile."""
    logger.info("Starting servers...")
    
    # Check if servers are already running
    if check_server_running(FRONTEND_URL, timeout=0.5) and check_server_running(API_ENDPOINT, timeout=0.5):
        logger.info("Servers already running")
        return True
    
    try:
        # Start servers using Makefile (suppress output for speed)
        result = subprocess.run(
            ["make", "start"],
            check=True,
            capture_output=True,
            text=True,
            timeout=10  # Fail fast if start hangs
        )
        logger.info("Started servers with 'make start'")
        
        # Wait for servers to be ready with shorter timeouts
        logger.info("Waiting for servers to be ready...")
        frontend_ready = wait_for_server(FRONTEND_URL, max_attempts=20, delay=0.5)
        backend_ready = wait_for_server(API_ENDPOINT, max_attempts=20, delay=0.5)
        
        if frontend_ready and backend_ready:
            logger.info("Both servers are ready!")
            return True
        else:
            logger.error("Servers failed to start or become ready")
            return False
            
    except subprocess.TimeoutExpired:
        logger.error("Server start timed out")
        return False
    except subprocess.CalledProcessError as e:
        logger.error(f"Error starting servers: {e}")
        logger.error(f"stdout: {e.stdout}")
        logger.error(f"stderr: {e.stderr}")
        return False


def stop_servers():
    """Stop both frontend and backend servers using Makefile."""
    logger.info("Stopping servers...")
    
    try:
        result = subprocess.run(
            ["make", "stop"],
            check=True,
            capture_output=True,
            text=True
        )
        logger.info("Stopped servers with 'make stop'")
        return True
    except subprocess.CalledProcessError as e:
        logger.warning(f"Error stopping servers (may already be stopped): {e}")
        return False


def get_server_status():
    """Get status of both servers."""
    frontend_status = "running" if check_server_running(FRONTEND_URL) else "stopped"
    backend_status = "running" if check_server_running(API_ENDPOINT) else "stopped"
    
    return {
        "frontend": frontend_status,
        "backend": backend_status
    }


def get_current_react_version():
    """Get current React version from package.json."""
    try:
        with open("package.json", "r") as f:
            package = json.load(f)
            return package.get("dependencies", {}).get("react", "unknown")
    except Exception:
        return "unknown"


def check_version_installed(version):
    """Check if React version is already installed by checking node_modules."""
    try:
        react_path = os.path.join("node_modules", "react", "package.json")
        if os.path.exists(react_path):
            with open(react_path, "r") as f:
                react_pkg = json.load(f)
                installed_version = react_pkg.get("version", "")
                # Handle version matching (e.g., "19.1.1" matches "19.1.1")
                return installed_version == version or installed_version.startswith(f"{version}.")
    except Exception:
        pass
    return False


def switch_react_version(version):
    """Switch React version using Makefile, skipping npm install if already installed."""
    import json
    
    # Check current version
    current_version = get_current_react_version()
    
    # If already on this version and installed, skip switch
    if current_version == version and check_version_installed(version):
        logger.info(f"React {version} already installed, skipping switch")
        return True
    
    logger.info(f"Switching to React {version}...")
    
    try:
        # Update package.json only if version differs
        if current_version != version:
            with open("package.json", "r") as f:
                package = json.load(f)
            package["dependencies"]["react"] = version
            package["dependencies"]["react-dom"] = version
            with open("package.json", "w") as f:
                json.dump(package, f, indent=2)
            logger.info(f"Updated package.json to React {version}")
        
        # Only run npm install if version not already installed
        if not check_version_installed(version):
            logger.info(f"Installing React {version}...")
            result = subprocess.run(
                ["npm", "install"],
                check=True,
                capture_output=True,
                text=True,
                timeout=120  # 2 minute timeout
            )
            logger.info(f"Installed React {version}")
        else:
            logger.info(f"React {version} already installed, skipping npm install")
        
        logger.info(f"Switched to React {version}")
        return True
    except subprocess.TimeoutExpired:
        logger.error(f"npm install timed out for React {version}")
        return False
    except subprocess.CalledProcessError as e:
        logger.error(f"Error switching React version: {e}")
        logger.error(f"stdout: {e.stdout}")
        logger.error(f"stderr: {e.stderr}")
        return False
    except Exception as e:
        logger.error(f"Unexpected error switching React version: {e}")
        return False
