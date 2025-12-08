#!/usr/bin/env python3
"""
Run version switch tests with parallel execution within each version.

This script:
1. For each React version:
   - Switches to that version once
   - Collects all test items for that version using pytest
   - Runs those tests in parallel
   - Then moves to the next version

This allows parallel execution within a version while ensuring versions
are switched sequentially to avoid conflicts.
"""
import subprocess
import sys
import os
import json
from typing import List
import argparse
import time


# All React versions to test
ALL_VERSIONS = [
    "19.0", "19.1.0", "19.1.1", "19.2.0",  # Vulnerable
    "19.0.1", "19.1.2", "19.2.1",  # Fixed
]


def get_current_react_version(project_root: str = ".") -> str:
    """Get current React version from package.json."""
    try:
        package_json = os.path.join(project_root, "package.json")
        with open(package_json, "r") as f:
            package = json.load(f)
            return package.get("dependencies", {}).get("react", "unknown")
    except Exception:
        return "unknown"


def resolve_python_exec(python_exec: str, project_root: str, script_dir: str) -> str:
    """Resolve Python executable path to absolute path."""
    if python_exec is None:
        # Try to find venv Python
        venv_python = os.path.join(project_root, "venv", "bin", "python3")
        if os.path.exists(venv_python):
            return os.path.abspath(venv_python)
        return sys.executable
    
    if os.path.isabs(python_exec):
        if os.path.exists(python_exec):
            return python_exec
        # If absolute but doesn't exist, try to find it
        return sys.executable
    
    # Try relative to project root first (most common case)
    abs_path = os.path.join(project_root, python_exec)
    if os.path.exists(abs_path):
        return os.path.abspath(abs_path)
    
    # Try relative to script directory (for ../venv/bin/python3 from tests/)
    abs_path = os.path.join(script_dir, python_exec)
    if os.path.exists(abs_path):
        return os.path.abspath(abs_path)
    
    # Try relative to current working directory
    abs_path = os.path.join(os.getcwd(), python_exec)
    if os.path.exists(abs_path):
        return os.path.abspath(abs_path)
    
    # Try to find in PATH
    import shutil
    found = shutil.which(python_exec)
    if found:
        return found
    
    # Last resort: return as-is (might work if it's in PATH)
    return python_exec


def run_tests_for_version(version: str, workers: int = 10, test_dir: str = "tests", project_root: str = ".", python_exec: str = None) -> bool:
    """Switch to version and run all tests for that version in parallel."""
    print(f"\n🔄 React {version}...", end=" ", flush=True)
    
    # Import server_manager once
    sys.path.insert(0, os.path.join(project_root, test_dir))
    from utils.server_manager import (
        switch_react_version, stop_servers, start_servers, 
        wait_for_server, check_server_running, check_version_installed
    )
    
    frontend_url = "http://localhost:5173"
    api_url = "http://localhost:3000/api/hello"
    
    # Check if already on this version and installed
    current = get_current_react_version(project_root)
    already_installed = check_version_installed(version)
    
    if current == version and already_installed:
        # Just ensure servers are running
        if not check_server_running(frontend_url) or not check_server_running(api_url):
            original_cwd = os.getcwd()
            os.chdir(project_root)
            try:
                start_servers()
                wait_for_server(frontend_url, max_attempts=8, delay=0.3)
                wait_for_server(api_url, max_attempts=8, delay=0.3)
            finally:
                os.chdir(original_cwd)
    else:
        original_cwd = os.getcwd()
        os.chdir(project_root)
        try:
            # Stop servers before switching (only if needed)
            if check_server_running(frontend_url) or check_server_running(api_url):
                stop_servers()
            # Switch version (this skips npm install if already installed)
            if not switch_react_version(version):
                print(f"❌ Failed")
                return False
            # Restart servers
            start_servers()
            # Use shorter waits - servers should be ready quickly
            wait_for_server(frontend_url, max_attempts=8, delay=0.3)
            wait_for_server(api_url, max_attempts=8, delay=0.3)
        finally:
            os.chdir(original_cwd)
    
    # Resolve python_exec to absolute path
    script_dir = os.path.dirname(os.path.abspath(__file__))
    python_exec = resolve_python_exec(python_exec, project_root, script_dir)
    
    # Build pytest command - use -k filter to match tests with this version
    # Parametrized tests have format: test_name[19.1.1-VULNERABLE] or test_name[19.1.1-FIXED]
    # The -k filter matches against the full test name including parameters
    # Also include non-parameterized tests that check current version
    # Use simple string matching - pytest's -k does substring matching
    version_filter = f"{version}- or test_vulnerable_indicator_displayed or test_fixed_indicator_displayed or test_vulnerable_status_color or test_fixed_status_color or test_react_version_matches_status"
    
    # Run pytest from project root
    test_file = os.path.join(test_dir, "test_suites", "test_security_status.py")
    pytest_cmd = [
        python_exec, "-m", "pytest",
        test_file,
        "-m", "version_switch",
        "-k", version_filter,  # Filter tests containing this version
        "-n", str(workers),
        "--tb=line",  # Minimal tracebacks for faster output
        "-q",  # Quiet mode for less output
        "--maxfail=1",  # Stop on first failure for faster feedback
        "--disable-warnings"  # Disable warnings for faster output
    ]
    
    result = subprocess.run(pytest_cmd, cwd=project_root)
    
    if result.returncode != 0:
        print(f"❌ Failed")
        return False
    
    print(f"✓ Passed")
    return True


def main():
    parser = argparse.ArgumentParser(description="Run version switch tests with parallel execution within versions")
    parser.add_argument("--workers", "-n", type=int, default=6, help="Number of parallel workers (default: 6, optimized for ~6 tests per version)")
    parser.add_argument("--test-dir", default="tests", help="Test directory (default: tests)")
    parser.add_argument("--project-root", default="..", help="Project root directory (default: ..)")
    parser.add_argument("--python", default=None, help="Python executable to use (default: sys.executable)")
    parser.add_argument("--versions", nargs="+", help="Specific versions to test (default: all)")
    args = parser.parse_args()
    
    # Resolve project root to absolute path
    project_root = os.path.abspath(args.project_root)
    test_dir = args.test_dir
    
    versions_to_test = args.versions if args.versions else ALL_VERSIONS
    
    # Reduced output for speed
    print(f"Testing {len(versions_to_test)} React versions with {args.workers} workers per version...")
    
    # Change to project root for version switching
    original_cwd = os.getcwd()
    os.chdir(project_root)
    
    try:
        failed_versions = []
        
        # Resolve Python executable
        script_dir = os.path.dirname(os.path.abspath(__file__))
        python_exec = resolve_python_exec(args.python, project_root, script_dir)
        
        for version in versions_to_test:
            success = run_tests_for_version(version, args.workers, test_dir, project_root, python_exec)
            if not success:
                failed_versions.append(version)
    finally:
        os.chdir(original_cwd)
    
    if failed_versions:
        print(f"\n❌ Failed: {', '.join(failed_versions)}")
        sys.exit(1)
    else:
        print(f"\n✓ All {len(versions_to_test)} versions passed!")
        sys.exit(0)


if __name__ == "__main__":
    main()
