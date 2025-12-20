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
import socket
import threading
from urllib.parse import urlparse
from .server_constants import (
    get_frontend_url,
    get_backend_url,
    get_api_endpoint
)


logger = logging.getLogger(__name__)


def _check_server_running_impl(url, timeout):
    """Internal implementation of server check with timeout protection."""
    # Parse URL to get host and port
    parsed = urlparse(url)
    host = parsed.hostname or 'localhost'
    port = parsed.port
    if port is None:
        # Default ports based on scheme
        port = 443 if parsed.scheme == 'https' else 80
    
    # Step 1: Quick socket check to see if port is open (non-blocking)
    # This prevents hanging on connection attempts
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(0.5)  # Very short timeout for socket check
    try:
        result = sock.connect_ex((host, port))
        if result != 0:
            # Port is not open, server is definitely not running
            return False
    except (socket.timeout, socket.error, OSError):
        return False
    finally:
        # Always close the socket
        try:
            sock.close()
        except Exception:
            pass
    
    # Step 2: Port is open, make HTTP request with explicit timeouts
    # For Next.js, initial requests can be slow (compilation), so use more generous timeouts
    # Use tuple for (connect_timeout, read_timeout) to be more explicit
    # Give more time for read since Next.js may need to compile on first request
    connect_timeout = min(timeout * 0.2, 0.5)  # 20% of timeout or max 0.5s for connect
    read_timeout = max(timeout - connect_timeout, 2.0)  # Rest for read, min 2.0s for Next.js compilation
    
    try:
        response = requests.get(
            url,
            timeout=(connect_timeout, read_timeout),
            allow_redirects=True
        )
        # Accept any 2xx or 3xx status code as "running"
        return 200 <= response.status_code < 400
    except requests.exceptions.Timeout as e:
        # Log timeout details for debugging
        logger.debug(f"HTTP request timeout for {url}: connect_timeout={connect_timeout}, read_timeout={read_timeout}, error={e}")
        return False
    except requests.exceptions.RequestException as e:
        # Log other request errors for debugging
        logger.debug(f"HTTP request error for {url}: {e}")
        return False


def check_server_running(url, timeout=2):
    """
    Check if a server is running at the given URL.
    
    Uses a two-step approach:
    1. First checks if the port is open using socket (fast, non-blocking)
    2. Then makes HTTP request with explicit connect/read timeouts
    
    This prevents hanging on connection attempts that don't respond.
    Uses a thread-based timeout wrapper to ensure it never blocks indefinitely.
    
    Note: For Next.js servers, timeout should be at least 3-5 seconds to allow
    for initial compilation on first request.
    """
    result_container = {'value': None, 'exception': None}
    
    def run_check():
        try:
            result_container['value'] = _check_server_running_impl(url, timeout)
        except Exception as e:
            result_container['exception'] = e
    
    # Run the check in a thread with a hard timeout
    # Give it more time than the HTTP timeout to account for thread overhead
    thread_timeout = max(timeout + 2.0, 5.0)  # At least 5s for Next.js compilation
    thread = threading.Thread(target=run_check, daemon=True)
    thread.start()
    thread.join(timeout=thread_timeout)
    
    if thread.is_alive():
        # Thread is still running - it hung, return False
        logger.debug(f"check_server_running thread timed out for {url} after {thread_timeout}s")
        return False
    
    # Check if an exception was raised
    if result_container['exception']:
        exc = result_container['exception']
        if isinstance(exc, KeyboardInterrupt):
            # Re-raise keyboard interrupts
            raise exc
        # Log other exceptions for debugging
        logger.debug(f"check_server_running exception for {url}: {exc}")
        # For other exceptions, return False
        return False
    
    # Return the result
    return result_container['value'] if result_container['value'] is not None else False


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


def wait_for_server(url, max_attempts=60, initial_delay=0.2, max_delay=2.0, max_wait_seconds=60):
    """
    Wait for server to be ready with fast polling.
    
    Uses short initial delay (0.2s) to detect readiness quickly, with exponential
    backoff up to max_delay (2.0s) to reduce CPU usage for long waits.
    Exits immediately when server is ready (no unnecessary waiting).
    
    Args:
        url: Server URL to check
        max_attempts: Maximum number of checks (default 60)
        initial_delay: Initial delay between checks in seconds (default 0.2)
        max_delay: Maximum delay between checks in seconds (default 2.0)
        max_wait_seconds: Hard time limit in seconds (default 60). If exceeded, returns False immediately.
    
    Returns:
        True if server is ready, False if timeout reached
    """
    delay = initial_delay
    start_time = time.time()
    logger.info(f"Waiting for server at {url} (max {max_wait_seconds}s, {max_attempts} attempts)")
    
    for attempt in range(max_attempts):
        # Hard time limit check - fail fast if we exceed max_wait_seconds
        elapsed = time.time() - start_time
        if elapsed >= max_wait_seconds:
            logger.error(f"Server not ready after {elapsed:.1f}s (hard limit: {max_wait_seconds}s) - FAILING FAST")
            return False
        
        # Check if server is ready
        # Use longer timeout (5s) for Next.js which may need to compile on first request
        check_start = time.time()
        is_ready = check_server_running(url, timeout=5)
        check_elapsed = time.time() - check_start
        
        if is_ready:
            elapsed = time.time() - start_time
            logger.info(f"Server ready at {url} (detected in {elapsed:.2f}s after {attempt + 1} checks)")
            return True
        
        # Don't sleep on last attempt
        if attempt < max_attempts - 1:
            # Log progress every 5 seconds of elapsed time
            elapsed = time.time() - start_time
            if attempt == 0 or attempt % 25 == 0:  # First attempt and every ~5 seconds (25 * 0.2s)
                logger.info(f"Waiting for server at {url} ({elapsed:.1f}s/{max_wait_seconds}s elapsed, attempt {attempt + 1}/{max_attempts}, check took {check_elapsed:.2f}s)")
            
            time.sleep(delay)
            
            # Exponential backoff: increase delay gradually, but cap at max_delay
            # This reduces CPU usage for long waits while still checking frequently initially
            delay = min(delay * 1.1, max_delay)
    
    elapsed = time.time() - start_time
    logger.error(f"Server not ready after {max_attempts} attempts ({elapsed:.1f}s elapsed, limit: {max_wait_seconds}s)")
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
    
    # Check if servers are already running (use longer timeout to be sure)
    frontend_url = get_frontend_url()
    if framework == "nextjs":
        # Next.js: only check port 3000
        if check_server_running(frontend_url, timeout=2):
            logger.info("Next.js server already running and responding")
            # Update PID file if needed
            pid_dir = os.path.join(project_root, ".pids")
            os.makedirs(pid_dir, exist_ok=True)
            vite_pid_file = os.path.join(pid_dir, "nextjs.pid")
            if not os.path.exists(vite_pid_file):
                try:
                    result = subprocess.run(
                        ["lsof", "-ti", ":3000"],
                        capture_output=True,
                        text=True,
                        timeout=2
                    )
                    if result.returncode == 0:
                        actual_pid = result.stdout.strip().split('\n')[0]
                        with open(vite_pid_file, "w") as f:
                            f.write(actual_pid)
                        logger.info("Created PID file with actual PID: {}".format(actual_pid))
                except Exception:
                    pass
            return True
    else:
        # Vite: check both ports
        api_endpoint = get_api_endpoint()
        if check_server_running(frontend_url, timeout=2) and check_server_running(api_endpoint, timeout=2):
            logger.info("Servers already running and responding")
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
            
            # First check if server is already responding (regardless of PID file)
            if check_server_running(frontend_url, timeout=1):
                logger.info("Next.js server already running and responding")
                # Update PID file if it exists and is valid, or create it if missing
                if os.path.exists(vite_pid_file):
                    try:
                        with open(vite_pid_file, "r") as f:
                            pid = int(f.read().strip())
                        # Check if process is running
                        os.kill(pid, 0)
                        logger.info("PID file valid (PID: {})".format(pid))
                    except (OSError, ValueError):
                        # PID file is stale, but server is running - find the actual PID
                        logger.warning("PID file is stale, but server is running. Finding actual PID...")
                        try:
                            result = subprocess.run(
                                ["lsof", "-ti", ":3000"],
                                capture_output=True,
                                text=True,
                                timeout=2
                            )
                            if result.returncode == 0:
                                actual_pid = result.stdout.strip().split('\n')[0]
                                with open(vite_pid_file, "w") as f:
                                    f.write(actual_pid)
                                logger.info("Updated PID file with actual PID: {}".format(actual_pid))
                        except Exception:
                            pass
                else:
                    # No PID file, but server is running - create it
                    try:
                        result = subprocess.run(
                            ["lsof", "-ti", ":3000"],
                            capture_output=True,
                            text=True,
                            timeout=2
                        )
                        if result.returncode == 0:
                            actual_pid = result.stdout.strip().split('\n')[0]
                            with open(vite_pid_file, "w") as f:
                                f.write(actual_pid)
                            logger.info("Created PID file with actual PID: {}".format(actual_pid))
                    except Exception:
                        pass
                return True
            
            # Server is not responding - clean up and start fresh
            logger.debug("Cleaning up port 3000...")
            _cleanup_port(3000)
            
            # Clean up Next.js lock files (prevents "Unable to acquire lock" errors)
            nextjs_dir = os.path.join(project_root, "frameworks", "nextjs")
            lock_file = os.path.join(nextjs_dir, ".next", "dev", "lock")
            if os.path.exists(lock_file):
                logger.debug("Removing Next.js lock file...")
                os.remove(lock_file)
            
            # Remove stale PID file if it exists
            if os.path.exists(vite_pid_file):
                logger.debug("Removing stale PID file...")
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
            
            # Wait for server to be ready (fast polling, exits as soon as ready, max 60s)
            server_ready = wait_for_server(frontend_url, max_attempts=60, initial_delay=0.2, max_delay=2.0, max_wait_seconds=60)
            if server_ready:
                logger.info("Next.js server is ready!")
                return True
            else:
                logger.error("Next.js server failed to start or become ready within 60 seconds")
                logger.error(f"Framework mode: {framework}")
                logger.error(f"Expected port: 3000")
                
                # Check if process is still running
                try:
                    if os.path.exists(vite_pid_file):
                        with open(vite_pid_file, "r") as f:
                            pid = int(f.read().strip())
                        try:
                            os.kill(pid, 0)  # Check if process exists
                            logger.error(f"Server process (PID: {pid}) is still running but not responding")
                        except (OSError, ProcessLookupError):
                            logger.error(f"Server process (PID: {pid}) from PID file is not running")
                except Exception as e:
                    logger.warning(f"Could not check PID file: {e}")
                
                # Check port status
                try:
                    port_check = subprocess.run(
                        ["lsof", "-ti", ":3000"],
                        capture_output=True,
                        text=True,
                        timeout=2
                    )
                    if port_check.returncode == 0:
                        pids = port_check.stdout.strip().split('\n')
                        logger.error(f"Port 3000 is in use by PIDs: {', '.join(pids)}")
                    else:
                        logger.error("Port 3000 is not in use - server may have crashed")
                except Exception:
                    logger.error("Could not check port 3000 status")
                
                # Read last 30 lines of server log for diagnostics
                if os.path.exists(server_log):
                    try:
                        with open(server_log, "r") as f:
                            lines = f.readlines()
                            if lines:
                                logger.error("Last 30 lines of server log:")
                                for line in lines[-30:]:
                                    logger.error(f"  {line.rstrip()}")
                            else:
                                logger.error("Server log file exists but is empty - server may not have started")
                    except Exception as e:
                        logger.warning(f"Could not read server log: {e}")
                else:
                    logger.error(f"Server log file not found at {server_log} - server may not have started")
                
                return False
        else:
            # Vite mode: start both Vite and Express servers
            logger.info("Starting Vite and Express servers...")
            vite_pid_file = os.path.join(pid_dir, "vite.pid")
            server_pid_file = os.path.join(pid_dir, "server.pid")
            vite_log = os.path.join(log_dir, "vite.log")
            server_log = os.path.join(log_dir, "server.log")
            
            # First check if servers are already responding (regardless of PID files)
            frontend_responding = check_server_running(frontend_url, timeout=1)
            backend_responding = check_server_running(api_endpoint, timeout=1)
            
            if frontend_responding and backend_responding:
                logger.info("Vite and Express servers already running and responding")
                # Update PID files if needed
                if os.path.exists(vite_pid_file):
                    try:
                        with open(vite_pid_file, "r") as f:
                            pid = int(f.read().strip())
                        os.kill(pid, 0)
                    except (OSError, ValueError):
                        # Stale PID file, but server is running - update it
                        try:
                            result = subprocess.run(
                                ["lsof", "-ti", ":5173"],
                                capture_output=True,
                                text=True,
                                timeout=2
                            )
                            if result.returncode == 0:
                                actual_pid = result.stdout.strip().split('\n')[0]
                                with open(vite_pid_file, "w") as f:
                                    f.write(actual_pid)
                        except Exception:
                            pass
                if os.path.exists(server_pid_file):
                    try:
                        with open(server_pid_file, "r") as f:
                            pid = int(f.read().strip())
                        os.kill(pid, 0)
                    except (OSError, ValueError):
                        # Stale PID file, but server is running - update it
                        try:
                            result = subprocess.run(
                                ["lsof", "-ti", ":3000"],
                                capture_output=True,
                                text=True,
                                timeout=2
                            )
                            if result.returncode == 0:
                                actual_pid = result.stdout.strip().split('\n')[0]
                                with open(server_pid_file, "w") as f:
                                    f.write(actual_pid)
                        except Exception:
                            pass
                return True
            
            # Servers are not responding - clean up and start fresh
            logger.debug("Cleaning up ports 5173 and 3000...")
            _cleanup_port(5173)
            _cleanup_port(3000)
            
            # Remove stale PID files if they exist
            if os.path.exists(vite_pid_file):
                logger.debug("Removing stale Vite PID file...")
                os.remove(vite_pid_file)
            if os.path.exists(server_pid_file):
                logger.debug("Removing stale Express PID file...")
                os.remove(server_pid_file)
            
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
            
            # Wait for both servers to be ready (fast polling, exits as soon as ready, max 60s each)
            api_endpoint = get_api_endpoint()
            frontend_ready = wait_for_server(frontend_url, max_attempts=60, initial_delay=0.2, max_delay=2.0, max_wait_seconds=60)
            backend_ready = wait_for_server(api_endpoint, max_attempts=60, initial_delay=0.2, max_delay=2.0, max_wait_seconds=60)
            
            if frontend_ready and backend_ready:
                logger.info("Both servers are ready!")
                return True
            else:
                logger.error("Servers failed to start or become ready")
                logger.error(f"Framework mode: {framework}")
                logger.error(f"Expected ports: 5173 (Vite), 3000 (Express)")
                
                # Check port status
                for port in [5173, 3000]:
                    try:
                        port_check = subprocess.run(
                            ["lsof", "-ti", f":{port}"],
                            capture_output=True,
                            text=True,
                            timeout=2
                        )
                        if port_check.returncode == 0:
                            pids = port_check.stdout.strip().split('\n')
                            logger.error(f"Port {port} is in use by PIDs: {', '.join(pids)}")
                        else:
                            logger.error(f"Port {port} is not in use")
                    except Exception:
                        logger.error(f"Could not check port {port} status")
                
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
            text=True,
            timeout=30  # 30 second timeout to prevent hanging
        )
        logger.info("Stopped servers with 'make stop'")
        return True
    except subprocess.TimeoutExpired:
        logger.warning("Timeout stopping servers with 'make stop' (30s), forcing cleanup...")
        # Force cleanup of ports
        _cleanup_port(3000)
        _cleanup_port(5173)
        return False
    except subprocess.CalledProcessError as e:
        logger.warning(f"Error stopping servers (may already be stopped): {e}")
        # Still try to clean up ports
        try:
            _cleanup_port(3000)
            _cleanup_port(5173)
        except Exception:
            pass
        return False
    except Exception as e:
        logger.warning(f"Unexpected error stopping servers: {e}")
        # Still try to clean up ports
        try:
            _cleanup_port(3000)
            _cleanup_port(5173)
        except Exception:
            pass
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
