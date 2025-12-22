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
    
    if ! command -v jq >/dev/null 2>&1; then
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
    
    # Start server
    if ! (cd "$PROJECT_ROOT" && make start >/dev/null 2>&1); then
        print_error "❌ Failed to start server for ${version_clean}"
        ((FAILED++))
        FAILED_VERSIONS+=("${version_clean}: start failed")
        return 1
    fi
    
    # Wait for server to be ready
    local max_attempts=60
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:3000/api/version >/dev/null 2>&1; then
            break
        fi
        sleep 1
        ((attempt++))
    done
    
    if [ $attempt -eq $max_attempts ]; then
        print_error "❌ Server not ready for ${version_clean}"
        (cd "$PROJECT_ROOT" && make stop >/dev/null 2>&1)
        ((FAILED++))
        FAILED_VERSIONS+=("${version_clean}: server not ready")
        return 1
    fi
    
    print_info "================================================================================="
    print_info "version=[${version_clean}]: curl"
    print_info "================================================================================="
    
    # Test API
    local response
    if ! response=$(curl -s http://localhost:3000/api/version 2>&1); then
        print_error "❌ Failed to call API for ${version_clean}"
        (cd "$PROJECT_ROOT" && make stop >/dev/null 2>&1)
        ((FAILED++))
        FAILED_VERSIONS+=("${version_clean}: API call failed")
        return 1
    fi
    
    # Validate JSON response
    if ! echo "$response" | jq . >/dev/null 2>&1; then
        print_error "❌ Invalid JSON response for ${version_clean}"
        print_error "Response: $response"
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
