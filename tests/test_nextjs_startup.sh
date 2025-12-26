#!/usr/bin/env bash
set -euET -o pipefail

# Script metadata
SCRIPT_NAME=$(basename "$0")
# Get absolute path of script directory
SCRIPT_DIR=$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")
if [ "$SCRIPT_DIR" = "." ]; then
    SCRIPT_DIR=$(pwd)
elif [ ! -d "$SCRIPT_DIR" ]; then
    # Fallback: try to get directory from $0
    SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd || pwd)
fi
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || echo "$(dirname "$SCRIPT_DIR")")
REPORT_DIR="$SCRIPT_DIR/reports"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
OUTPUT_FILE="$REPORT_DIR/test_nextjs_startup_${TIMESTAMP}.txt"

# Test results tracking
PASSED=0
FAILED=0
FAILED_VERSIONS=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${YELLOW}$1${NC}"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v make >/dev/null 2>&1; then
        missing_deps+=("make")
    fi
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    # Check for jq in PATH or standard locations
    local jq_found=0
    if command -v jq >/dev/null 2>&1; then
        jq_found=1
    elif [ -f "/opt/homebrew/bin/jq" ] || [ -f "/usr/local/bin/jq" ]; then
        # Add jq to PATH if found in standard locations
        if [ -f "/opt/homebrew/bin/jq" ]; then
            export PATH="/opt/homebrew/bin:$PATH"
        elif [ -f "/usr/local/bin/jq" ]; then
            export PATH="/usr/local/bin:$PATH"
        fi
        jq_found=1
    fi
    
    if [ $jq_found -eq 0 ]; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "❌ Error: Missing required dependencies: ${missing_deps[*]}"
        print_error "   Please install missing dependencies and try again."
        exit 2
    fi
}

# Function to ensure Next.js mode is active
ensure_nextjs_mode() {
    if [ ! -f "$PROJECT_ROOT/.framework-mode" ]; then
        print_info "⚠️  Framework mode not set. Switching to Next.js mode..."
        (cd "$PROJECT_ROOT" && make use-nextjs >/dev/null 2>&1)
    elif ! grep -q '^nextjs' "$PROJECT_ROOT/.framework-mode" 2>/dev/null; then
        print_info "⚠️  Not in Next.js mode. Switching to Next.js mode..."
        (cd "$PROJECT_ROOT" && make use-nextjs >/dev/null 2>&1)
    fi
}

# Function to test a single version
test_version() {
    local version=$1
    local version_clean=$(echo "$version" | sed 's/nextjs-//')
    
    # Known Issues:
    # - Next.js 15.2.5 has a deploymentId bug that causes crashes
    # - Next.js 16.0.6 has the same deploymentId bug
    # When handling requests, they crash with: TypeError: Cannot read properties of undefined (reading 'deploymentId')
    # This is a known Next.js bug and may cause test failures in CI
    # See: docs/ci-cd/CI_TEST_FAILURE_ANALYSIS_2025-12-26.md for details
    # See: docs/ci-cd/CI_TEST_FAILURE_ANALYSIS_2025-12-26_070413.md for 16.0.6 details
    
    print_info "================================================================================="
    print_info "version=[${version_clean}]: switch"
    print_info "================================================================================="
    
    # Switch to version
    if ! (cd "$PROJECT_ROOT" && make "$version" >/dev/null 2>&1); then
        print_error "❌ Failed to switch to ${version_clean}"
        ((FAILED++))
        FAILED_VERSIONS+=("${version_clean}: switch failed")
        return 1
    fi
    
    print_info "================================================================================="
    print_info "version=[${version_clean}]: start"
    print_info "================================================================================="
    
    # Verify ports 3000-3010 are available before starting
    # Next.js can use any port from 3000-3010 if ports are in use
    local PORTS_IN_USE=""
    for port in 3000 3001 3002 3003 3004 3005 3006 3007 3008 3009 3010; do
        if lsof -ti:$port >/dev/null 2>&1; then
            PORTS_IN_USE="$PORTS_IN_USE $port"
        fi
    done
    
    if [ -n "$PORTS_IN_USE" ]; then
        print_error "❌ Ports in use before starting ${version_clean}:$PORTS_IN_USE"
        print_error "Attempting cleanup..."
        (cd "$PROJECT_ROOT" && make stop >/dev/null 2>&1) || true
        # Kill all processes on ports 3000-3010
        for port in 3000 3001 3002 3003 3004 3005 3006 3007 3008 3009 3010; do
            lsof -ti:$port 2>/dev/null | xargs kill -9 2>/dev/null || true
        done
        # Kill all Next.js/node processes
        pkill -f "next dev" 2>/dev/null || true
        pkill -f "next-server" 2>/dev/null || true
        pkill -f "node.*next" 2>/dev/null || true
        sleep 3
        # Verify cleanup
        local PORTS_STILL_IN_USE=""
        for port in 3000 3001 3002 3003 3004 3005; do
            if lsof -ti:$port >/dev/null 2>&1; then
                PORTS_STILL_IN_USE="$PORTS_STILL_IN_USE $port"
            fi
        done
        if [ -n "$PORTS_STILL_IN_USE" ]; then
            print_error "❌ Ports still in use after cleanup:$PORTS_STILL_IN_USE"
            ((FAILED++))
            FAILED_VERSIONS+=("${version_clean}: port conflict - ports in use")
            return 1
        fi
        print_info "✓ Ports cleaned up, proceeding with start"
    fi
    
    # Start server
    if ! (cd "$PROJECT_ROOT" && make start >/dev/null 2>&1); then
        print_error "❌ Failed to start server for ${version_clean}"
        ((FAILED++))
        FAILED_VERSIONS+=("${version_clean}: start failed")
        return 1
    fi
    
    # Detect which port the server actually started on
    # Next.js may start on 3000-3010 if ports are in use
    local DETECTED_PORT=""
    local http_check_timeout=30
    local http_check_attempt=0
    local http_check_interval=0.5
    local server_ready=0
    local start_time
    start_time=$(date +%s)
    
    print_info "Detecting which port server started on..."
    
    # Wait for server to start and detect the port
    while [ $http_check_attempt -lt $((http_check_timeout * 2)) ] && [ -z "$DETECTED_PORT" ]; do
        # Check ports 3000-3005 to find where server is listening
        for port in 3000 3001 3002 3003 3004 3005; do
            local http_code
            http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 http://localhost:$port/api/version 2>/dev/null || echo "000")
            
            if [ "$http_code" = "200" ]; then
                DETECTED_PORT=$port
                local elapsed_time
                elapsed_time=$(($(date +%s) - start_time))
                print_info "✓ Server detected on port $port (detection time: ${elapsed_time}s)"
                server_ready=1
                break
            fi
        done
        
        if [ -n "$DETECTED_PORT" ]; then
            break
        fi
        
        sleep $http_check_interval
        ((http_check_attempt++))
    done
    
    # If port not detected, continue with readiness check on detected port (or 3000 as fallback)
    if [ -z "$DETECTED_PORT" ]; then
        print_info "Server port not yet detected, continuing readiness check..."
        DETECTED_PORT="3000"  # Fallback to 3000 for backward compatibility
    fi
    
    # Verify server accepts HTTP requests on detected port with busy wait
    # Typical startup time is 5-15 seconds, so use 30 seconds (2x) as timeout
    if [ $server_ready -eq 0 ]; then
        print_info "Waiting for server to accept requests on port $DETECTED_PORT..."
        http_check_attempt=0
        
        while [ $http_check_attempt -lt $((http_check_timeout * 2)) ]; do
            # Try to curl the server - check if it responds with HTTP 200
            local http_code
            http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 http://localhost:$DETECTED_PORT/api/version 2>/dev/null || echo "000")
            
            if [ "$http_code" = "200" ]; then
                local elapsed_time
                elapsed_time=$(($(date +%s) - start_time))
                print_info "✓ Server accepting requests on port $DETECTED_PORT (startup time: ${elapsed_time}s)"
                server_ready=1
                break
            fi
        
            # Periodically check server logs to see what's happening (every 10 seconds)
            local elapsed_time
            elapsed_time=$(($(date +%s) - start_time))
            
            if [ $((http_check_attempt % 20)) -eq 0 ] && [ -f "$PROJECT_ROOT/.logs/server.log" ]; then
                local last_log_line
                last_log_line=$(tail -1 "$PROJECT_ROOT/.logs/server.log" 2>/dev/null || echo "")
                
                if echo "$last_log_line" | grep -q "Ready"; then
                    print_info "  [${elapsed_time}s] Server reports Ready (HTTP: $http_code)"
                elif echo "$last_log_line" | grep -q "Starting"; then
                    print_info "  [${elapsed_time}s] Server is Starting (HTTP: $http_code)"
                elif echo "$last_log_line" | grep -q "Compiling"; then
                    print_info "  [${elapsed_time}s] Server is Compiling (HTTP: $http_code)"
                elif echo "$last_log_line" | grep -qiE "Error|Failed"; then
                    print_info "  [${elapsed_time}s] ⚠️  Server has errors (HTTP: $http_code)"
                fi
            fi
            
            sleep $http_check_interval
            ((http_check_attempt++))
        done
    fi
    
    if [ $server_ready -eq 0 ]; then
        local elapsed_time
        elapsed_time=$(($(date +%s) - start_time))
        print_error "❌ Server did not accept requests on port $DETECTED_PORT for ${version_clean} within ${http_check_timeout} seconds (waited: ${elapsed_time}s)"
        print_error "Checking if server started on a different port..."
        local alt_ports=""
        for port in 3001 3002 3003 3004 3005 3006 3007 3008 3009 3010; do
            if lsof -ti:$port >/dev/null 2>&1; then
                alt_ports="$alt_ports $port"
            fi
        done
        if [ -n "$alt_ports" ]; then
            print_error "Server may have started on alternate port(s):$alt_ports"
        fi
        print_error "Capturing server logs..."
        if [ -f "$PROJECT_ROOT/.logs/server.log" ]; then
            print_error "--- Server Log (full log) ---"
            cat "$PROJECT_ROOT/.logs/server.log" | sed 's/^/  /' >&2
            print_error "--- End Server Log ---"
            print_error ""
            print_error "--- Server Log Analysis ---"
            local log_lines
            log_lines=$(wc -l < "$PROJECT_ROOT/.logs/server.log" 2>/dev/null || echo "0")
            print_error "Total log lines: $log_lines"
            if grep -q "Ready" "$PROJECT_ROOT/.logs/server.log" 2>/dev/null; then
                print_error "✓ Server reported 'Ready' in logs"
                local ready_line
                ready_line=$(grep -n "Ready" "$PROJECT_ROOT/.logs/server.log" 2>/dev/null | head -1 | cut -d: -f1 || echo "unknown")
                print_error "  First 'Ready' at line: $ready_line"
            else
                print_error "✗ Server never reported 'Ready' in logs"
            fi
            if grep -qiE "Error|error|Failed|failed" "$PROJECT_ROOT/.logs/server.log" 2>/dev/null; then
                print_error "⚠️  Errors found in server logs:"
                grep -iE "Error|error|Failed|failed" "$PROJECT_ROOT/.logs/server.log" 2>/dev/null | tail -5 | sed 's/^/    /' >&2
            fi
            print_error "--- End Analysis ---"
        else
            print_error "Server log file not found at $PROJECT_ROOT/.logs/server.log"
        fi
        print_error "Performing aggressive cleanup..."
        # Kill all processes on ports 3000-3010
        for port in 3000 3001 3002 3003 3004 3005 3006 3007 3008 3009 3010; do
            lsof -ti:$port 2>/dev/null | xargs kill -9 2>/dev/null || true
        done
        # Kill all Next.js/node processes
        pkill -f "next dev" 2>/dev/null || true
        pkill -f "next-server" 2>/dev/null || true
        pkill -f "node.*next" 2>/dev/null || true
        sleep 2
        # Also call make stop for good measure
        (cd "$PROJECT_ROOT" && make stop >/dev/null 2>&1) || true
        # Verify cleanup
        local ports_still_in_use=""
        for port in 3000 3001 3002 3003 3004 3005; do
            if lsof -ti:$port >/dev/null 2>&1; then
                ports_still_in_use="$ports_still_in_use $port"
            fi
        done
        if [ -n "$ports_still_in_use" ]; then
            print_error "⚠️  Warning: Ports still in use after cleanup:$ports_still_in_use"
        else
            print_info "✓ All ports cleaned up"
        fi
        ((FAILED++))
        FAILED_VERSIONS+=("${version_clean}: server not accepting requests on port $DETECTED_PORT")
        return 1
    fi
    
    # Server is already verified to be accepting requests from the HTTP check above
    # No need for additional readiness check
    
    print_info "================================================================================="
    print_info "version=[${version_clean}]: curl"
    print_info "================================================================================="
    
    # Test API using detected port
    local response
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$DETECTED_PORT/api/version 2>/dev/null || echo "000")
    response=$(curl -s http://localhost:$DETECTED_PORT/api/version 2>&1)
    
    if [ "$http_code" != "200" ]; then
        print_error "❌ API call failed for ${version_clean} (HTTP ${http_code})"
        print_error "Response: $response"
        print_error "Capturing server logs..."
        if [ -f "$PROJECT_ROOT/.logs/server.log" ]; then
            print_error "--- Server Log (last 50 lines) ---"
            tail -50 "$PROJECT_ROOT/.logs/server.log" | sed 's/^/  /' >&2
            print_error "--- End Server Log ---"
        else
            print_error "Server log not found at $PROJECT_ROOT/.logs/server.log"
        fi
        (cd "$PROJECT_ROOT" && make stop >/dev/null 2>&1)
        ((FAILED++))
        FAILED_VERSIONS+=("${version_clean}: API call failed (HTTP ${http_code})")
        return 1
    fi
    
    if ! echo "$response" | jq . >/dev/null 2>&1; then
        print_error "❌ Invalid JSON response for ${version_clean}"
        print_error "Response: $response"
        print_error "Capturing server logs..."
        if [ -f "$PROJECT_ROOT/.logs/server.log" ]; then
            print_error "--- Server Log (last 50 lines) ---"
            tail -50 "$PROJECT_ROOT/.logs/server.log" | sed 's/^/  /' >&2
            print_error "--- End Server Log ---"
        else
            print_error "Server log not found at $PROJECT_ROOT/.logs/server.log"
        fi
        (cd "$PROJECT_ROOT" && make stop >/dev/null 2>&1)
        ((FAILED++))
        FAILED_VERSIONS+=("${version_clean}: invalid JSON")
        return 1
    fi
    
    # Display formatted JSON
    echo "$response" | jq .
    
    # Verify nextjs version matches
    local api_version
    api_version=$(echo "$response" | jq -r '.nextjs // empty')
    if [ -z "$api_version" ]; then
        print_error "❌ API response missing 'nextjs' field for ${version_clean}"
        (cd "$PROJECT_ROOT" && make stop >/dev/null 2>&1)
        ((FAILED++))
        FAILED_VERSIONS+=("${version_clean}: missing nextjs field")
        return 1
    fi
    
    if [ "$api_version" != "$version_clean" ]; then
        print_error "❌ Version mismatch for ${version_clean}: expected ${version_clean}, got ${api_version}"
        (cd "$PROJECT_ROOT" && make stop >/dev/null 2>&1)
        ((FAILED++))
        FAILED_VERSIONS+=("${version_clean}: version mismatch (expected ${version_clean}, got ${api_version})")
        return 1
    fi
    
    print_info "================================================================================="
    print_info "version=[${version_clean}]: stop"
    print_info "================================================================================="
    
    # Stop server
    (cd "$PROJECT_ROOT" && make stop >/dev/null 2>&1)
    
    # Wait for port to be released and verify cleanup
    print_info "Verifying port 3000 is released..."
    local port_wait_attempts=10
    local port_wait_attempt=0
    while [ $port_wait_attempt -lt $port_wait_attempts ]; do
        if ! lsof -ti:3000 >/dev/null 2>&1; then
            print_info "✓ Port 3000 is free"
            break
        fi
        sleep 1
        ((port_wait_attempt++))
    done
    
    # Force cleanup if port is still in use - kill all ports and processes
    if lsof -ti:3000 >/dev/null 2>&1; then
        print_info "⚠️  Port 3000 still in use, performing aggressive cleanup..."
        # Kill all processes on ports 3000-3010
        for port in 3000 3001 3002 3003 3004 3005 3006 3007 3008 3009 3010; do
            lsof -ti:$port 2>/dev/null | xargs kill -9 2>/dev/null || true
        done
        # Kill all Next.js/node processes
        pkill -f "next dev" 2>/dev/null || true
        pkill -f "next-server" 2>/dev/null || true
        pkill -f "node.*next" 2>/dev/null || true
        sleep 2
        # Verify cleanup succeeded
        local ports_still_in_use=""
        for port in 3000 3001 3002 3003 3004 3005; do
            if lsof -ti:$port >/dev/null 2>&1; then
                ports_still_in_use="$ports_still_in_use $port"
            fi
        done
        if [ -n "$ports_still_in_use" ]; then
            print_error "❌ Warning: Ports still in use after cleanup:$ports_still_in_use"
        else
            print_info "✓ All ports cleaned up"
        fi
    fi
    
    ((PASSED++))
    print_success "✓ ${version_clean} passed"
    return 0
}

# Function to print summary
print_summary() {
    echo ""
    print_info "================================================================================="
    print_info "Summary"
    print_info "================================================================================="
    echo ""
    print_success "✓ Passed: $PASSED"
    if [ $FAILED -gt 0 ]; then
        print_error "❌ Failed: $FAILED"
        echo ""
        print_error "Failed versions:"
        for failed_version in "${FAILED_VERSIONS[@]}"; do
            print_error "  - $failed_version"
        done
    else
        print_success "✓ All versions passed!"
    fi
    echo ""
    
    if [ -f "$OUTPUT_FILE" ]; then
        print_info "Full output saved to: $OUTPUT_FILE"
    fi
}

# Main execution
main() {
    # Check dependencies
    check_dependencies
    
    # Ensure Next.js mode
    ensure_nextjs_mode
    
    # Create reports directory
    mkdir -p "$REPORT_DIR"
    
    # Stop any running servers
    print_info "================================================================================="
    print_info "check that the server is not running"
    print_info "================================================================================="
    (cd "$PROJECT_ROOT" && make stop >/dev/null 2>&1) || true
    
    # Get all Next.js versions from Makefile
    local versions
    versions=$(cd "$PROJECT_ROOT" && make | grep 'nextjs-' | grep 'Switch' | awk '{print $2}')
    
    if [ -z "$versions" ]; then
        print_error "❌ Error: Could not find Next.js versions in Makefile"
        exit 1
    fi
    
    # Test each version
    while IFS= read -r version; do
        if [ -n "$version" ]; then
            test_version "$version" || true
        fi
    done <<< "$versions"
    
    # Print summary
    print_summary
    
    # Exit with appropriate code
    if [ $FAILED -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"
