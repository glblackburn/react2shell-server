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
    get_frontend_url,
    get_backend_url,
    get_api_endpoint
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
    """Start servers using Makefile (framework-aware)."""
    from .framework_detector import get_framework_mode
    
    framework = get_framework_mode()
    logger.info(f"Starting servers (Framework: {framework})...")
    
    # Check if servers are already running
    frontend_url = get_frontend_url()
    if framework == "nextjs":
        # Next.js: only check port 3000
        if check_server_running(frontend_url, timeout=0.5):
            logger.info("Next.js server already running")
            return True
    else:
        # Vite: check both ports
        api_endpoint = get_api_endpoint()
        if check_server_running(frontend_url, timeout=0.5) and check_server_running(api_endpoint, timeout=0.5):
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
        
        # Wait for servers to be ready with adequate timeouts
        logger.info("Waiting for servers to be ready...")
        frontend_url = get_frontend_url()
        if framework == "nextjs":
            # Next.js: only wait for port 3000, with longer timeout for initial startup
            server_ready = wait_for_server(frontend_url, max_attempts=60, delay=1)
            if server_ready:
                logger.info("Next.js server is ready!")
                return True
            else:
                logger.error("Next.js server failed to start or become ready")
                return False
        else:
            # Vite: wait for both ports
            api_endpoint = get_api_endpoint()
            frontend_ready = wait_for_server(frontend_url, max_attempts=60, delay=1)
            backend_ready = wait_for_server(api_endpoint, max_attempts=60, delay=1)
            
            if frontend_ready and backend_ready:
                logger.info("Both servers are ready!")
                return True
            else:
                logger.error("Servers failed to start or become ready")
                return False
            
    except subprocess.TimeoutExpired:
        logger.error("Server start command timed out, but checking if server is running...")
        # Even if make start timed out, the server might still be starting
        # Give it a bit more time and check if it's actually running
        import time
        time.sleep(2)
        frontend_url = get_frontend_url()
        if framework == "nextjs":
            if check_server_running(frontend_url, timeout=1):
                logger.info("Next.js server is actually running despite timeout")
                return True
        else:
            api_endpoint = get_api_endpoint()
            if check_server_running(frontend_url, timeout=1) and check_server_running(api_endpoint, timeout=1):
                logger.info("Servers are actually running despite timeout")
                return True
        logger.error("Server start timed out and server is not running")
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
    frontend_url = get_frontend_url()
    api_endpoint = get_api_endpoint()
    frontend_status = "running" if check_server_running(frontend_url) else "stopped"
    backend_status = "running" if check_server_running(api_endpoint) else "stopped"
    
    return {
        "frontend": frontend_status,
        "backend": backend_status
    }


def get_current_react_version():
    """Get current React version from package.json (framework-aware)."""
    from .framework_detector import get_framework_mode
    
    framework = get_framework_mode()
    try:
        if framework == "nextjs":
            package_path = "frameworks/nextjs/package.json"
        else:
            package_path = "frameworks/vite-react/package.json"
        
        with open(package_path, "r") as f:
            package = json.load(f)
            return package.get("dependencies", {}).get("react", "unknown")
    except Exception:
        return "unknown"


def check_version_installed(version):
    """Check if React version is already installed by checking node_modules (framework-aware)."""
    from .framework_detector import get_framework_mode
    
    framework = get_framework_mode()
    if framework == "nextjs":
        node_modules_path = "frameworks/nextjs/node_modules"
    else:
        node_modules_path = "frameworks/vite-react/node_modules"
    
    try:
        react_path = os.path.join(node_modules_path, "react", "package.json")
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
    """Switch React version using Makefile (framework-aware)."""
    from .framework_detector import get_framework_mode
    
    framework = get_framework_mode()
    logger.info(f"Switching to React {version} (Framework: {framework})...")
    
    # Check current version
    current_version = get_current_react_version()
    
    # If already on this version and installed, skip switch
    if framework == "nextjs":
        package_path = "frameworks/nextjs/package.json"
        node_modules_path = "frameworks/nextjs/node_modules"
    else:
        package_path = "frameworks/vite-react/package.json"
        node_modules_path = "frameworks/vite-react/node_modules"
    
    # Check if version is already installed
    react_path = os.path.join(node_modules_path, "react", "package.json")
    if os.path.exists(react_path):
        try:
            with open(react_path, "r") as f:
                react_pkg = json.load(f)
                installed_version = react_pkg.get("version", "")
                if installed_version == version or installed_version.startswith(f"{version}."):
                    if current_version == version:
                        logger.info(f"React {version} already installed, skipping switch")
                        return True
        except Exception:
            pass
    
    # Use Makefile to switch version (it handles framework detection)
    try:
        result = subprocess.run(
            ["make", f"react-{version}"],
            check=True,
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout (npm install can take time)
        )
        logger.info(f"Switched to React {version}")
        return True
    except subprocess.TimeoutExpired:
        logger.error(f"Version switch timed out for React {version} after 5 minutes")
        logger.error("This may indicate npm install is taking too long or hanging")
        return False
    except subprocess.CalledProcessError as e:
        logger.error(f"Error switching React version: {e}")
        logger.error(f"stdout: {e.stdout}")
        logger.error(f"stderr: {e.stderr}")
        return False
    except Exception as e:
        logger.error(f"Unexpected error switching React version: {e}")
        return False
