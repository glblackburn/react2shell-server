"""
Utility functions for managing server lifecycle in tests.
"""
import subprocess
import time
import requests
import logging


logger = logging.getLogger(__name__)


FRONTEND_URL = "http://localhost:5173"
BACKEND_URL = "http://localhost:3000"
API_ENDPOINT = f"{BACKEND_URL}/api/hello"


def check_server_running(url, timeout=2):
    """Check if a server is running at the given URL."""
    try:
        response = requests.get(url, timeout=timeout)
        return response.status_code == 200
    except requests.exceptions.RequestException:
        return False


def wait_for_server(url, max_attempts=30, delay=1):
    """Wait for server to be ready."""
    for attempt in range(max_attempts):
        if check_server_running(url):
            logger.info(f"Server ready at {url}")
            return True
        logger.debug(f"Waiting for server at {url} (attempt {attempt + 1}/{max_attempts})")
        time.sleep(delay)
    return False


def start_servers():
    """Start both frontend and backend servers using Makefile."""
    logger.info("Starting servers...")
    
    # Check if servers are already running
    if check_server_running(FRONTEND_URL) and check_server_running(API_ENDPOINT):
        logger.info("Servers already running")
        return True
    
    try:
        # Start servers using Makefile
        result = subprocess.run(
            ["make", "start"],
            check=True,
            capture_output=True,
            text=True
        )
        logger.info("Started servers with 'make start'")
        
        # Wait for servers to be ready
        logger.info("Waiting for servers to be ready...")
        frontend_ready = wait_for_server(FRONTEND_URL)
        backend_ready = wait_for_server(API_ENDPOINT)
        
        if frontend_ready and backend_ready:
            logger.info("Both servers are ready!")
            return True
        else:
            logger.error("Servers failed to start or become ready")
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


def switch_react_version(version):
    """Switch React version using Makefile."""
    logger.info(f"Switching to React {version}...")
    
    try:
        result = subprocess.run(
            ["make", f"react-{version}"],
            check=True,
            capture_output=True,
            text=True
        )
        logger.info(f"Switched to React {version}")
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Error switching React version: {e}")
        logger.error(f"stdout: {e.stdout}")
        logger.error(f"stderr: {e.stderr}")
        return False
