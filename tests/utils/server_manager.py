"""
Utility functions for managing server lifecycle in tests.
"""
import subprocess
import time
import requests
import logging
import json
import os
import signal
from .server_constants import (
    get_frontend_url,
    get_backend_url,
    get_api_endpoint
)


logger = logging.getLogger(__name__)


def check_server_running(url, timeout=2):
    """Check if a server is running at the given URL."""
    try:
        response = requests.get(url, timeout=timeout)
        # Accept any 2xx or 3xx status code as "running"
        return 200 <= response.status_code < 400
    except (requests.exceptions.RequestException, requests.exceptions.Timeout):
        return False


def _cleanup_port(port):
    """Kill any process using the specified port."""
    try:
        result = subprocess.run(
            ["lsof", "-ti", f":{port}"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            pids = result.stdout.strip().split('\n')
            for pid in pids:
                if pid:
                    try:
                        pid_int = int(pid)
                        os.kill(pid_int, signal.SIGTERM)
                        time.sleep(0.5)
                        # If still running, force kill
                        try:
                            os.kill(pid_int, 0)  # Check if still exists
                            os.kill(pid_int, signal.SIGKILL)
                        except (OSError, ProcessLookupError):
                            pass  # Process already dead
                    except (OSError, ValueError, ProcessLookupError):
                        pass
    except (subprocess.TimeoutExpired, FileNotFoundError):
        # lsof not available or timeout - continue anyway
        pass
    except Exception:
        # Any other error - continue anyway
        pass


def wait_for_server(url, max_attempts=300, initial_delay=0.2, max_delay=2.0):
    """
    Wait for server to be ready with fast polling.
    
    Uses short initial delay (0.2s) to detect readiness quickly, with exponential
    backoff up to max_delay (2.0s) to reduce CPU usage for long waits.
    Exits immediately when server is ready (no unnecessary waiting).
    
    Args:
        url: Server URL to check
        max_attempts: Maximum number of checks (default 300 = ~60 seconds worst case)
        initial_delay: Initial delay between checks in seconds (default 0.2)
        max_delay: Maximum delay between checks in seconds (default 2.0)
    
    Returns:
        True if server is ready, False if timeout reached
    """
    delay = initial_delay
    start_time = time.time()
    
    for attempt in range(max_attempts):
        # Check if server is ready (fast check with 1 second timeout)
        if check_server_running(url, timeout=1):
            elapsed = time.time() - start_time
            logger.info(f"Server ready at {url} (detected in {elapsed:.2f}s after {attempt + 1} checks)")
            return True
        
        # Don't sleep on last attempt
        if attempt < max_attempts - 1:
            # Log progress every 5 seconds of elapsed time
            elapsed = time.time() - start_time
            if attempt % 25 == 0 and attempt > 0:  # Every ~5 seconds (25 * 0.2s)
                logger.debug(f"Waiting for server at {url} ({elapsed:.1f}s elapsed, attempt {attempt + 1}/{max_attempts})")
            
            time.sleep(delay)
            
            # Exponential backoff: increase delay gradually, but cap at max_delay
            # This reduces CPU usage for long waits while still checking frequently initially
            delay = min(delay * 1.1, max_delay)
    
    elapsed = time.time() - start_time
    logger.warning(f"Server not ready after {max_attempts} attempts ({elapsed:.1f}s elapsed)")
    return False


def start_servers():
    """Start servers using Makefile (framework-aware)."""
    from .framework_detector import get_framework_mode
    import os
    
    # Get project root for framework mode file verification
    project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    framework_mode_file = os.path.join(project_root, ".framework-mode")
    
    # Verify framework mode file exists and is readable
    framework = get_framework_mode()
    if not os.path.exists(framework_mode_file):
        logger.warning(".framework-mode file not found, defaulting to vite")
        logger.info(f"Framework mode file: {framework_mode_file} (not found)")
        framework = "vite"
    else:
        try:
            with open(framework_mode_file, "r") as f:
                framework_from_file = f.read().strip() or "vite"
            if framework_from_file != framework:
                logger.warning(f"Framework mode mismatch: detector={framework}, file={framework_from_file}")
            framework = framework_from_file
            logger.info(f"Framework mode file: {framework_mode_file}")
            logger.info(f"Framework mode value: '{framework}'")
        except Exception as e:
            logger.warning(f"Could not read .framework-mode file: {e}, using detector result: {framework}")
            logger.info(f"Framework mode file: {framework_mode_file} (read error)")
    
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
    
    # Get project root (assume we're in tests/utils/, go up 2 levels)
    project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    pid_dir = os.path.join(project_root, ".pids")
    log_dir = os.path.join(project_root, ".logs")
    os.makedirs(pid_dir, exist_ok=True)
    os.makedirs(log_dir, exist_ok=True)
    
    # Ensure server dependencies are installed
    server_dir = os.path.join(project_root, "server")
    server_node_modules = os.path.join(server_dir, "node_modules")
    if not os.path.exists(server_node_modules):
        logger.info("Server dependencies not found, installing...")
        try:
            subprocess.run(
                ["npm", "install"],
                cwd=server_dir,
                check=True,
                capture_output=True,
                timeout=60
            )
            logger.info("Server dependencies installed")
        except Exception as e:
            logger.warning(f"Failed to install server dependencies: {e}")
            # Continue anyway - might work if dependencies are elsewhere
    
    try:
        if framework == "nextjs":
            # Start Next.js server
            logger.info("Starting Next.js server...")
            vite_pid_file = os.path.join(pid_dir, "nextjs.pid")
            server_log = os.path.join(log_dir, "server.log")
            
            # Clean up port 3000 before starting
            logger.debug("Cleaning up port 3000...")
            _cleanup_port(3000)
            
            # Clean up Next.js lock files (prevents "Unable to acquire lock" errors)
            nextjs_dir = os.path.join(project_root, "frameworks", "nextjs")
            lock_file = os.path.join(nextjs_dir, ".next", "dev", "lock")
            if os.path.exists(lock_file):
                logger.debug("Removing Next.js lock file...")
                os.remove(lock_file)
            
            # Check if already running - verify both PID file and actual server response
            if os.path.exists(vite_pid_file):
                try:
                    with open(vite_pid_file, "r") as f:
                        pid = int(f.read().strip())
                    # Check if process is running
                    os.kill(pid, 0)
                    # Also verify server is actually responding
                    if check_server_running(frontend_url, timeout=1):
                        logger.info("Next.js server already running (PID: {})".format(pid))
                        return True
                    else:
                        # PID exists but server not responding - stale PID file
                        logger.warning("PID file exists but server not responding, removing stale PID file")
                        os.remove(vite_pid_file)
                except (OSError, ValueError):
                    # PID file exists but process is dead - remove stale file
                    if os.path.exists(vite_pid_file):
                        os.remove(vite_pid_file)
            
            # Start Next.js server
            nextjs_dir = os.path.join(project_root, "frameworks", "nextjs")
            process = subprocess.Popen(
                ["npx", "next", "dev"],
                cwd=nextjs_dir,
                stdout=open(server_log, "a"),
                stderr=subprocess.STDOUT,
                preexec_fn=os.setsid  # Create new process group
            )
            with open(vite_pid_file, "w") as f:
                f.write(str(process.pid))
            logger.info("Started Next.js server (PID: {})".format(process.pid))
            
            # Wait for server to be ready (fast polling, exits as soon as ready)
            server_ready = wait_for_server(frontend_url, max_attempts=300, initial_delay=0.2, max_delay=2.0)
            if server_ready:
                logger.info("Next.js server is ready!")
                return True
            else:
                logger.error("Next.js server failed to start or become ready")
                # Read last 20 lines of server log for diagnostics
                if os.path.exists(server_log):
                    try:
                        with open(server_log, "r") as f:
                            lines = f.readlines()
                            if lines:
                                logger.error("Last 20 lines of server log:")
                                for line in lines[-20:]:
                                    logger.error(f"  {line.rstrip()}")
                    except Exception as e:
                        logger.warning(f"Could not read server log: {e}")
                return False
        else:
            # Vite mode: start both Vite and Express servers
            logger.info("Starting Vite and Express servers...")
            vite_pid_file = os.path.join(pid_dir, "vite.pid")
            server_pid_file = os.path.join(pid_dir, "server.pid")
            vite_log = os.path.join(log_dir, "vite.log")
            server_log = os.path.join(log_dir, "server.log")
            
            # Clean up ports before starting
            logger.debug("Cleaning up ports 5173 and 3000...")
            _cleanup_port(5173)
            _cleanup_port(3000)
            
            # Start Vite server
            vite_dir = os.path.join(project_root, "frameworks", "vite-react")
            if not os.path.exists(vite_pid_file) or not _check_pid_file(vite_pid_file):
                vite_process = subprocess.Popen(
                    ["npm", "run", "dev"],
                    cwd=vite_dir,
                    stdout=open(vite_log, "a"),
                    stderr=subprocess.STDOUT,
                    preexec_fn=os.setsid
                )
                with open(vite_pid_file, "w") as f:
                    f.write(str(vite_process.pid))
                logger.info("Started Vite server (PID: {})".format(vite_process.pid))
            else:
                logger.info("Vite server already running")
            
            # Start Express server
            server_dir = os.path.join(project_root, "server")
            if not os.path.exists(server_pid_file) or not _check_pid_file(server_pid_file):
                # Ensure log file exists and is writable
                with open(server_log, "a") as log_file:
                    log_file.write("")  # Ensure file exists
                
                server_process = subprocess.Popen(
                    ["node", "server.js"],
                    cwd=server_dir,
                    stdout=open(server_log, "a"),
                    stderr=subprocess.STDOUT,
                    preexec_fn=os.setsid if hasattr(os, 'setsid') else None
                )
                with open(server_pid_file, "w") as f:
                    f.write(str(server_process.pid))
                logger.info("Started Express server (PID: {})".format(server_process.pid))
                # Give server a moment to start
                time.sleep(2)
            else:
                logger.info("Express server already running")
            
            # Wait for both servers to be ready (fast polling, exits as soon as ready)
            api_endpoint = get_api_endpoint()
            frontend_ready = wait_for_server(frontend_url, max_attempts=300, initial_delay=0.2, max_delay=2.0)
            backend_ready = wait_for_server(api_endpoint, max_attempts=300, initial_delay=0.2, max_delay=2.0)
            
            if frontend_ready and backend_ready:
                logger.info("Both servers are ready!")
                return True
            else:
                logger.error("Servers failed to start or become ready")
                if frontend_ready:
                    logger.error("Frontend ready but backend not ready")
                elif backend_ready:
                    logger.error("Backend ready but frontend not ready")
                else:
                    logger.error("Neither server is ready")
                
                # Read server logs for diagnostics
                if os.path.exists(vite_log):
                    try:
                        with open(vite_log, "r") as f:
                            lines = f.readlines()
                            if lines:
                                logger.error("Last 20 lines of Vite server log:")
                                for line in lines[-20:]:
                                    logger.error(f"  {line.rstrip()}")
                    except Exception as e:
                        logger.warning(f"Could not read Vite log: {e}")
                
                if os.path.exists(server_log):
                    try:
                        with open(server_log, "r") as f:
                            lines = f.readlines()
                            if lines:
                                logger.error("Last 20 lines of Express server log:")
                                for line in lines[-20:]:
                                    logger.error(f"  {line.rstrip()}")
                    except Exception as e:
                        logger.warning(f"Could not read Express server log: {e}")
                
                return False
            
    except Exception as e:
        logger.error(f"Error starting servers: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False


def _check_pid_file(pid_file):
    """Check if PID file exists and process is running."""
    try:
        if os.path.exists(pid_file):
            with open(pid_file, "r") as f:
                pid = int(f.read().strip())
            # Check if process is running (signal 0 doesn't kill, just checks)
            os.kill(pid, 0)
            return True
    except (OSError, ValueError):
        pass
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
