#!/usr/bin/env bash
# Validate GitHub Branch Protection Enforcement
#
# This script validates that branch protection is properly configured and enforced
# to prevent commits that bypass CI/CD automation. It checks:
# 1. Branch protection configuration exists
# 2. Required settings are enabled
# 3. Status checks are required
# 4. Administrators are included (no bypass)
# 5. Optional: Test enforcement by attempting operations
#
# Usage:
#   export GITHUB_TOKEN="ghp_..."
#   export GITHUB_REPOSITORY_OWNER="your-org"
#   export GITHUB_REPOSITORY_NAME="react2shell-server"
#   ./scripts/validate_branch_protection_enforcement.sh [--test-enforcement]

set -euET -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
REPO_OWNER="${GITHUB_REPOSITORY_OWNER:-}"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-}"
BRANCH="${BRANCH:-main}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
TEST_ENFORCEMENT="${TEST_ENFORCEMENT:-false}"

# Colors
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --test-enforcement)
            TEST_ENFORCEMENT=true
            shift
            ;;
        --branch)
            BRANCH="$2"
            shift 2
            ;;
        -h|--help)
            cat << EOF
Usage: $0 [OPTIONS]

Validate GitHub branch protection is configured and enforced.

Options:
  --test-enforcement    Test actual enforcement (creates test branch/PR)
  --branch BRANCH       Branch to check (default: main)
  -h, --help            Show this help message

Environment Variables:
  GITHUB_TOKEN              GitHub personal access token (required)
  GITHUB_REPOSITORY_OWNER   Repository owner (required)
  GITHUB_REPOSITORY_NAME    Repository name (required)
  BRANCH                    Branch to check (default: main)

Examples:
  # Basic validation (configuration check only)
  export GITHUB_TOKEN="ghp_..."
  export GITHUB_REPOSITORY_OWNER="myorg"
  export GITHUB_REPOSITORY_NAME="myrepo"
  ./scripts/validate_branch_protection_enforcement.sh

  # Full validation with enforcement testing
  ./scripts/validate_branch_protection_enforcement.sh --test-enforcement
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Validate required environment variables
if [ -z "$GITHUB_TOKEN" ]; then
    echo "${RED}❌ Error: GITHUB_TOKEN environment variable required${RESET}" >&2
    echo "   Set it with: export GITHUB_TOKEN=\"ghp_...\"" >&2
    exit 1
fi

if [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
    echo "${RED}❌ Error: Repository owner and name required${RESET}" >&2
    echo "   Set with: export GITHUB_REPOSITORY_OWNER=\"your-org\"" >&2
    echo "            export GITHUB_REPOSITORY_NAME=\"repo-name\"" >&2
    exit 1
fi

# Check dependencies
if ! command -v jq >/dev/null 2>&1; then
    echo "${RED}❌ Error: jq is required but not installed${RESET}" >&2
    echo "   Install with: brew install jq (macOS) or apt-get install jq (Linux)" >&2
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "${RED}❌ Error: curl is required but not installed${RESET}" >&2
    exit 1
fi

# API configuration
API_BASE="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}"
API_URL="${API_BASE}/branches/${BRANCH}/protection"
HEADERS=(
    -H "Authorization: token ${GITHUB_TOKEN}"
    -H "Accept: application/vnd.github.v3+json"
)

# Track validation results
VALIDATION_PASSED=true
ERRORS=()
WARNINGS=()
INFO=()

echo "${BOLD}${CYAN}========================================${RESET}"
echo "${BOLD}${CYAN}Branch Protection Enforcement Validation${RESET}"
echo "${BOLD}${CYAN}========================================${RESET}"
echo ""
echo "Repository: ${REPO_OWNER}/${REPO_NAME}"
echo "Branch: ${BRANCH}"
echo "Test Enforcement: ${TEST_ENFORCEMENT}"
echo ""

# ============================================================================
# Step 1: Check if branch protection exists
# ============================================================================

echo "${CYAN}[1/6]${RESET} Checking if branch protection is configured..."

response=$(curl -s -w "\n%{http_code}" "${HEADERS[@]}" "$API_URL" 2>/dev/null)
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "404" ]; then
    echo "${RED}❌ FAIL: Branch protection not configured for ${BRANCH}${RESET}"
    echo ""
    echo "   Branch protection must be configured to enforce CI/CD requirements."
    echo "   Configure it at:"
    echo "   https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/branches"
    echo ""
    ERRORS+=("Branch protection not configured")
    VALIDATION_PASSED=false
    exit 1
fi

if [ "$http_code" != "200" ]; then
    echo "${RED}❌ FAIL: API request failed (HTTP ${http_code})${RESET}"
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
    ERRORS+=("API request failed: HTTP ${http_code}")
    VALIDATION_PASSED=false
    exit 1
fi

echo "${GREEN}✓ Branch protection is configured${RESET}"
echo ""

# Parse protection data
PROTECTION_DATA=$(echo "$body" | jq '.')

# ============================================================================
# Step 2: Validate Required Pull Request Reviews
# ============================================================================

echo "${CYAN}[2/6]${RESET} Validating required pull request reviews..."

required_pr=$(echo "$PROTECTION_DATA" | jq -r '.required_pull_request_reviews // empty')

if [ -z "$required_pr" ] || [ "$required_pr" = "null" ]; then
    echo "${RED}❌ FAIL: Required pull request reviews not enabled${RESET}"
    echo "   This allows direct pushes to ${BRANCH}, bypassing CI/CD"
    ERRORS+=("Required PR reviews not enabled")
    VALIDATION_PASSED=false
else
    required_approvals=$(echo "$required_pr" | jq -r '.required_approving_review_count // 0')
    dismiss_stale=$(echo "$required_pr" | jq -r '.dismiss_stale_reviews // false')
    
    echo "${GREEN}✓ Required PR reviews enabled${RESET}"
    echo "   - Required approvals: ${required_approvals}"
    echo "   - Dismiss stale reviews: ${dismiss_stale}"
    
    if [ "$required_approvals" -eq 0 ]; then
        WARNINGS+=("Required approvals is 0 (allows PRs without reviews)")
    fi
fi
echo ""

# ============================================================================
# Step 3: Validate Required Status Checks
# ============================================================================

echo "${CYAN}[3/6]${RESET} Validating required status checks..."

required_status_checks=$(echo "$PROTECTION_DATA" | jq -r '.required_status_checks // empty')

if [ -z "$required_status_checks" ] || [ "$required_status_checks" = "null" ]; then
    echo "${RED}❌ FAIL: Required status checks not configured${RESET}"
    echo "   This allows PRs to be merged without CI/CD passing"
    ERRORS+=("Required status checks not configured")
    VALIDATION_PASSED=false
else
    strict=$(echo "$required_status_checks" | jq -r '.strict // false')
    contexts=$(echo "$required_status_checks" | jq -r '.contexts[]? // empty')
    
    if [ -z "$contexts" ]; then
        echo "${RED}❌ FAIL: No status checks are required${RESET}"
        echo "   This allows PRs to be merged without any CI/CD checks"
        ERRORS+=("No status checks configured")
        VALIDATION_PASSED=false
    else
        echo "${GREEN}✓ Required status checks configured${RESET}"
        echo "   - Require up-to-date branches: ${strict}"
        echo "   - Required checks:"
        echo "$contexts" | while read -r check; do
            echo "     • ${check}"
        done
        
        if [ "$strict" != "true" ]; then
            WARNINGS+=("Branches don't need to be up-to-date (strict=false)")
        fi
        
        # Check for expected CI/CD checks
        expected_checks=("lint" "test-vite" "test-nextjs" "validate-versions")
        missing_checks=()
        
        for expected in "${expected_checks[@]}"; do
            if ! echo "$contexts" | grep -q "^${expected}$"; then
                missing_checks+=("$expected")
            fi
        done
        
        if [ ${#missing_checks[@]} -gt 0 ]; then
            echo "${YELLOW}⚠️  WARNING: Expected CI/CD checks not found:${RESET}"
            for check in "${missing_checks[@]}"; do
                echo "     - ${check}"
            done
            WARNINGS+=("Missing expected CI/CD checks: ${missing_checks[*]}")
        fi
    fi
fi
echo ""

# ============================================================================
# Step 4: Validate Administrator Enforcement
# ============================================================================

echo "${CYAN}[4/6]${RESET} Validating administrator enforcement..."

enforce_admins=$(echo "$PROTECTION_DATA" | jq -r '.enforce_admins.enabled // false')

if [ "$enforce_admins" != "true" ]; then
    echo "${RED}❌ FAIL: Administrators are NOT included in protection${RESET}"
    echo "   This allows admins to bypass branch protection and push directly to ${BRANCH}"
    echo "   This is a CRITICAL security issue - admins can bypass CI/CD"
    ERRORS+=("Administrators not included in protection (CRITICAL)")
    VALIDATION_PASSED=false
else
    echo "${GREEN}✓ Administrators are included in protection${RESET}"
    echo "   Admins cannot bypass branch protection"
fi
echo ""

# ============================================================================
# Step 5: Validate Force Push and Deletion Restrictions
# ============================================================================

echo "${CYAN}[5/6]${RESET} Validating force push and deletion restrictions..."

allow_force_pushes=$(echo "$PROTECTION_DATA" | jq -r '.allow_force_pushes // false')
allow_deletions=$(echo "$PROTECTION_DATA" | jq -r '.allow_deletions // false')

if [ "$allow_force_pushes" = "true" ]; then
    echo "${RED}❌ FAIL: Force pushes are allowed${RESET}"
    echo "   This allows rewriting history and bypassing protection"
    ERRORS+=("Force pushes are allowed")
    VALIDATION_PASSED=false
else
    echo "${GREEN}✓ Force pushes are disabled${RESET}"
fi

if [ "$allow_deletions" = "true" ]; then
    echo "${RED}❌ FAIL: Branch deletion is allowed${RESET}"
    echo "   This is a security risk"
    ERRORS+=("Branch deletion is allowed")
    VALIDATION_PASSED=false
else
    echo "${GREEN}✓ Branch deletion is disabled${RESET}"
fi
echo ""

# ============================================================================
# Step 6: Test Enforcement (Optional)
# ============================================================================

if [ "$TEST_ENFORCEMENT" = "true" ]; then
    echo "${CYAN}[6/6]${RESET} Testing enforcement (creating test branch/PR)..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "${YELLOW}⚠️  WARNING: Not in a git repository, skipping enforcement test${RESET}"
        WARNINGS+=("Enforcement test skipped (not in git repo)")
    else
        # Get current branch
        current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
        
        # Create test branch name
        test_branch="test-branch-protection-$(date +%s)"
        
        echo "   Creating test branch: ${test_branch}"
        
        # Create test branch
        if git checkout -b "$test_branch" > /dev/null 2>&1; then
            # Create a test commit
            echo "# Test commit for branch protection validation" > "${PROJECT_ROOT}/.branch-protection-test-${test_branch}.md"
            git add ".branch-protection-test-${test_branch}.md" > /dev/null 2>&1
            git commit -m "Test: Branch protection validation" > /dev/null 2>&1
            
            # Try to push to main (should fail)
            echo "   Testing: Attempting to push directly to ${BRANCH} (should fail)..."
            
            # Switch to main temporarily
            git checkout "$BRANCH" > /dev/null 2>&1 || {
                echo "${YELLOW}⚠️  WARNING: Could not checkout ${BRANCH}, skipping direct push test${RESET}"
                WARNINGS+=("Could not test direct push (not on ${BRANCH})")
            }
            
            # Try to merge test branch into main (should fail if protection works)
            if git merge "$test_branch" --no-ff --no-commit > /dev/null 2>&1; then
                git merge --abort > /dev/null 2>&1
                echo "   ${YELLOW}⚠️  WARNING: Local merge succeeded (expected if protection only blocks remote)${RESET}"
                INFO+=("Local merge test completed (protection blocks remote pushes, not local)")
            fi
            
            # Try to push test branch
            echo "   Testing: Pushing test branch (should succeed)..."
            if git push -u origin "$test_branch" > /dev/null 2>&1; then
                echo "   ${GREEN}✓ Test branch pushed successfully${RESET}"
                
                # Try to create PR (this will show if CI is required)
                echo "   Testing: Creating test PR..."
                
                # Use GitHub CLI if available, otherwise use API
                if command -v gh >/dev/null 2>&1; then
                    pr_url=$(gh pr create --base "$BRANCH" --head "$test_branch" \
                        --title "Test: Branch Protection Validation" \
                        --body "Automated test PR for branch protection validation. This PR should be blocked from merging until CI passes." \
                        --draft 2>/dev/null)
                    
                    if [ -n "$pr_url" ]; then
                        echo "   ${GREEN}✓ Test PR created: ${pr_url}${RESET}"
                        INFO+=("Test PR created: ${pr_url}")
                        
                        # Check if PR can be merged (should be blocked)
                        sleep 2  # Wait for GitHub to process
                        pr_data=$(gh pr view "$test_branch" --json mergeable,mergeStateStatus 2>/dev/null)
                        
                        if [ -n "$pr_data" ]; then
                            mergeable=$(echo "$pr_data" | jq -r '.mergeable // "UNKNOWN"')
                            merge_state=$(echo "$pr_data" | jq -r '.mergeStateStatus // "UNKNOWN"')
                            
                            echo "   PR merge status: ${mergeable} (${merge_state})"
                            
                            if [ "$mergeable" = "false" ] || [ "$merge_state" != "CLEAN" ]; then
                                echo "   ${GREEN}✓ PR is correctly blocked from merging${RESET}"
                                INFO+=("PR correctly blocked (mergeable: ${mergeable})")
                            else
                                echo "   ${YELLOW}⚠️  WARNING: PR appears mergeable (may need CI to run first)${RESET}"
                                WARNINGS+=("Test PR appears mergeable (verify CI is required)")
                            fi
                        fi
                    else
                        echo "   ${YELLOW}⚠️  WARNING: Could not create PR (may need manual creation)${RESET}"
                        WARNINGS+=("Could not create test PR automatically")
                    fi
                else
                    echo "   ${YELLOW}⚠️  INFO: GitHub CLI not available, skipping PR creation${RESET}"
                    echo "   Create PR manually to test: https://github.com/${REPO_OWNER}/${REPO_NAME}/compare/${BRANCH}...${test_branch}"
                    INFO+=("Test branch created: ${test_branch} (create PR manually to test)")
                fi
                
                # Cleanup: delete test branch (optional)
                echo ""
                echo "   ${CYAN}Note:${RESET} Test branch '${test_branch}' was created."
                echo "   Clean it up with: git push origin --delete ${test_branch}"
            else
                echo "   ${RED}❌ FAIL: Could not push test branch${RESET}"
                ERRORS+=("Could not push test branch")
                VALIDATION_PASSED=false
            fi
            
            # Return to original branch
            if [ -n "$current_branch" ] && [ "$current_branch" != "$BRANCH" ]; then
                git checkout "$current_branch" > /dev/null 2>&1 || true
            fi
        else
            echo "   ${YELLOW}⚠️  WARNING: Could not create test branch${RESET}"
            WARNINGS+=("Could not create test branch")
        fi
    fi
else
    echo "${CYAN}[6/6]${RESET} Enforcement testing skipped (use --test-enforcement to enable)"
    INFO+=("Enforcement testing skipped (use --test-enforcement for full validation)")
fi
echo ""

# ============================================================================
# Summary
# ============================================================================

echo "${BOLD}${CYAN}========================================${RESET}"
echo "${BOLD}${CYAN}Validation Summary${RESET}"
echo "${BOLD}${CYAN}========================================${RESET}"
echo ""

# Show errors
if [ ${#ERRORS[@]} -gt 0 ]; then
    echo "${RED}${BOLD}❌ ERRORS (Must Fix):${RESET}"
    for error in "${ERRORS[@]}"; do
        echo "  ${RED}• ${error}${RESET}"
    done
    echo ""
    VALIDATION_PASSED=false
fi

# Show warnings
if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo "${YELLOW}${BOLD}⚠️  WARNINGS:${RESET}"
    for warning in "${WARNINGS[@]}"; do
        echo "  ${YELLOW}• ${warning}${RESET}"
    done
    echo ""
fi

# Show info
if [ ${#INFO[@]} -gt 0 ]; then
    echo "${CYAN}${BOLD}ℹ️  INFO:${RESET}"
    for info in "${INFO[@]}"; do
        echo "  ${CYAN}• ${info}${RESET}"
    done
    echo ""
fi

# Final result
if [ "$VALIDATION_PASSED" = "true" ]; then
    echo "${GREEN}${BOLD}✅ PASS: Branch protection is properly configured and enforced${RESET}"
    echo ""
    echo "Branch protection will:"
    echo "  ✓ Prevent direct pushes to ${BRANCH}"
    echo "  ✓ Require pull requests for all changes"
    echo "  ✓ Require CI/CD status checks to pass"
    echo "  ✓ Apply to administrators (no bypass)"
    echo "  ✓ Prevent force pushes and deletions"
    echo ""
    exit 0
else
    echo "${RED}${BOLD}❌ FAIL: Branch protection validation failed${RESET}"
    echo ""
    echo "Fix the errors above to ensure CI/CD is properly enforced."
    echo ""
    echo "Configure branch protection at:"
    echo "  https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/branches"
    echo ""
    exit 1
fi
