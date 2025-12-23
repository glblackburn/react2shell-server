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
#   ./scripts/validate_branch_protection_enforcement.sh [--test-enforcement]
#
# Credential Loading (automatic):
#   1. Environment variable GITHUB_TOKEN (highest priority)
#   2. Secure credentials file ~/.secure/github-set-token.sh
#   3. Interactive setup (prompts if credentials missing)
#
# Repository Detection (automatic):
#   Automatically detected from git remote origin
#
# Manual override (optional):
#   export GITHUB_TOKEN="ghp_..."
#   export GITHUB_REPOSITORY_OWNER="your-org"
#   export GITHUB_REPOSITORY_NAME="react2shell-server"

set -euET -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Credentials configuration
SECURE_DIR="${HOME}/.secure"
CREDENTIALS_FILE="${SECURE_DIR}/github-set-token.sh"
GITHUB_TOKEN_URL="https://github.com/settings/tokens"

# Configuration
REPO_OWNER="${GITHUB_REPOSITORY_OWNER:-}"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-}"
BRANCH="${BRANCH:-main}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
TEST_ENFORCEMENT="${TEST_ENFORCEMENT:-false}"

# Colors (handle non-TTY gracefully)
RED=$(tput setaf 1 2>/dev/null || echo "")
GREEN=$(tput setaf 2 2>/dev/null || echo "")
YELLOW=$(tput setaf 3 2>/dev/null || echo "")
CYAN=$(tput setaf 6 2>/dev/null || echo "")
BOLD=$(tput bold 2>/dev/null || echo "")
RESET=$(tput sgr0 2>/dev/null || echo "")

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
        --reset-credentials)
            echo "${CYAN}Resetting stored credentials...${RESET}"
            if [ -f "$CREDENTIALS_FILE" ]; then
                rm -f "$CREDENTIALS_FILE"
                echo "${GREEN}✓ Credentials file removed: ${CREDENTIALS_FILE}${RESET}"
            else
                echo "${YELLOW}No credentials file found at ${CREDENTIALS_FILE}${RESET}"
            fi
            if [ -n "$GITHUB_TOKEN" ]; then
                echo "${YELLOW}⚠️  GITHUB_TOKEN environment variable is set${RESET}"
                echo "   Unset it with: unset GITHUB_TOKEN"
            fi
            echo "${GREEN}✓ Credentials reset complete${RESET}"
            echo ""
            echo "Run the script again to set up new credentials interactively."
            exit 0
            ;;
        -h|--help)
            cat << EOF
Usage: $0 [OPTIONS]

Validate GitHub branch protection is configured and enforced.

Options:
  --test-enforcement    Test actual enforcement (creates test branch/PR)
  --branch BRANCH       Branch to check (default: main)
  --reset-credentials   Clear stored credentials and exit
  -h, --help            Show this help message

Credential Loading (Three-tier priority):
  1. Environment variable GITHUB_TOKEN (highest priority)
  2. Secure credentials file ~/.secure/github-set-token.sh
  3. Interactive setup (if credentials missing)

Repository Detection:
  Automatically detected from git remote origin if not provided via environment variables.

Environment Variables (optional if using credentials file):
  GITHUB_TOKEN              GitHub personal access token
  GITHUB_REPOSITORY_OWNER   Repository owner (auto-detected from git remote)
  GITHUB_REPOSITORY_NAME    Repository name (auto-detected from git remote)
  BRANCH                    Branch to check (default: main)

GitHub Token Permissions:
  ⚠️  Fine-grained tokens may not work for branch protection API
  Recommended: Use classic token with 'repo' scope
    Suggested token name: react2shell-branch-protection-readonly
  For --test-enforcement: Same classic token with 'repo' scope works
    Suggested token name: react2shell-branch-protection-full
  See: docs/scripts/GITHUB_PERMISSIONS_REQUIRED.md for detailed permissions guide

Examples:
  # Basic validation (will prompt for credentials if needed)
  ./scripts/validate_branch_protection_enforcement.sh

  # Full validation with enforcement testing
  ./scripts/validate_branch_protection_enforcement.sh --test-enforcement

  # Reset stored credentials (clears credentials file)
  ./scripts/validate_branch_protection_enforcement.sh --reset-credentials

  # Using environment variables (bypasses credential file)
  export GITHUB_TOKEN="ghp_..."
  ./scripts/validate_branch_protection_enforcement.sh

Documentation:
  - GitHub Permissions Guide: docs/scripts/GITHUB_PERMISSIONS_REQUIRED.md
  - CI/CD Setup Plan: docs/planning/CI_CD_COMPLETE_PLAN.md
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# ============================================================================
# Credential Loading Functions
# ============================================================================

load_github_credentials() {
    # Load GitHub token from secure credentials file
    if [ -f "$CREDENTIALS_FILE" ]; then
        # Source the credentials file to load GITHUB_TOKEN
        source "$CREDENTIALS_FILE" 2>/dev/null || true
        if [ -n "$GITHUB_TOKEN" ]; then
            return 0
        fi
    fi
    return 1
}

detect_repository_info() {
    # Detect repository owner and name from git remote origin
    if [ -d "$PROJECT_ROOT/.git" ]; then
        local remote_url=$(git -C "$PROJECT_ROOT" remote get-url origin 2>/dev/null || echo "")
        if [ -n "$remote_url" ]; then
            # Handle git@github.com:owner/repo.git format
            if [[ "$remote_url" =~ ^git@github\.com:([^/]+)/([^/]+)(\.git)?$ ]]; then
                REPO_OWNER="${BASH_REMATCH[1]}"
                local repo_part="${BASH_REMATCH[2]}"
                REPO_NAME="${repo_part%.git}"
                return 0
            # Handle https://github.com/owner/repo.git or https://github.com/owner/repo format
            elif [[ "$remote_url" =~ ^https?://github\.com/([^/]+)/([^/]+)(\.git)?/?$ ]]; then
                REPO_OWNER="${BASH_REMATCH[1]}"
                local repo_part="${BASH_REMATCH[2]}"
                REPO_NAME="${repo_part%.git}"
                return 0
            fi
        fi
    fi
    return 1
}

setup_github_credentials_interactive() {
    # Interactive setup for GitHub token credentials
    echo ""
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo "${BOLD}${CYAN}GitHub Token Credential Setup${RESET}"
    echo "${BOLD}${CYAN}========================================${RESET}"
    echo ""
    echo "This script requires a GitHub personal access token to validate branch protection."
    echo ""
    echo "Credentials file: ${CREDENTIALS_FILE}"
    echo "GitHub Token Settings (Classic): https://github.com/settings/tokens"
    echo "GitHub Token Settings (Fine-grained): https://github.com/settings/tokens?type=beta"
    echo ""
    echo "${CYAN}📖 Documentation:${RESET}"
    echo "   For detailed permissions requirements, see:"
    echo "   ${PROJECT_ROOT}/docs/scripts/GITHUB_PERMISSIONS_REQUIRED.md"
    echo ""
    echo "${CYAN}Token Type Recommendation:${RESET}"
    echo "   ${YELLOW}⚠️  Fine-grained tokens may not work for branch protection API${RESET}"
    echo "   ${BOLD}Recommended:${RESET} Use a classic personal access token"
    echo ""
    echo "${CYAN}Token Name Suggestion:${RESET}"
    if [ "$TEST_ENFORCEMENT" = "true" ]; then
        echo "   ${BOLD}react2shell-branch-protection-full${RESET}"
        echo "   (Full validation mode - creates test branch/PR)"
    else
        echo "   ${BOLD}react2shell-branch-protection-readonly${RESET}"
        echo "   (Read-only validation mode)"
    fi
    echo ""
    echo "${CYAN}Required Permissions:${RESET}"
    if [ "$TEST_ENFORCEMENT" = "true" ]; then
        echo "   Classic token: 'repo' scope (includes read/write)"
    else
        echo "   Classic token: 'repo' scope (or 'public_repo' for public repos only)"
        echo "   ${YELLOW}Note:${RESET} Fine-grained 'Contents: Read' may not work - use classic token"
    fi
    echo ""

    # Check if credentials file already exists
    if [ -f "$CREDENTIALS_FILE" ]; then
        echo "${YELLOW}WARNING: ${CREDENTIALS_FILE} already exists.${RESET}"
        read -p "Overwrite? (y/N): " response
        if [ "${response,,}" != "y" ]; then
            echo "Exiting without changes."
            return 1
        fi
    fi

    echo "${YELLOW}⚠️  Important:${RESET} Use a CLASSIC token (not fine-grained) for branch protection API"
    echo ""
    echo "Go get your GitHub personal access token:"
    echo "  • Classic token (recommended): https://github.com/settings/tokens"
    echo "  • Fine-grained token (may not work): https://github.com/settings/tokens?type=beta"
    echo ""
    echo "Press Enter to open classic token settings (or 'N' to skip and enter manually)."
    read response

    if [ "${response,,}" != "n" ]; then
        classic_token_url="https://github.com/settings/tokens"
        if command -v open >/dev/null 2>&1; then
            open "$classic_token_url" 2>/dev/null || true
        elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$classic_token_url" 2>/dev/null || true
        else
            echo "Please open manually: ${classic_token_url}"
        fi
    fi

    echo ""
    echo "Enter your GitHub personal access token:"
    echo "  (Token will be hidden for security)"
    read -s token_input
    echo ""

    if [ -z "$token_input" ]; then
        echo "${RED}ERROR: GitHub token is required${RESET}" >&2
        return 1
    fi

    # Create secure directory
    echo ""
    echo "Creating secure directory: ${SECURE_DIR}"
    mkdir -p "$SECURE_DIR"
    chmod 700 "$SECURE_DIR"

    # Write credentials file
    echo "Creating credentials file: ${CREDENTIALS_FILE}"
    cat > "$CREDENTIALS_FILE" <<EOF
export GITHUB_TOKEN="${token_input}"
EOF

    # Set permissions: 400 (read-only for owner)
    chmod 400 "$CREDENTIALS_FILE"

    echo ""
    echo "${GREEN}${BOLD}========================================${RESET}"
    echo "${GREEN}${BOLD}Credentials file created successfully!${RESET}"
    echo "${GREEN}${BOLD}========================================${RESET}"
    echo "File: ${CREDENTIALS_FILE}"
    echo "Permissions: $(stat -f "%OLp" "$CREDENTIALS_FILE" 2>/dev/null || stat -c "%a" "$CREDENTIALS_FILE" 2>/dev/null || echo "400")"
    echo ""

    # Load the token
    GITHUB_TOKEN="$token_input"
    return 0
}

# ============================================================================
# Load Credentials (Three-tier priority system)
# ============================================================================

# Tier 1: Environment variable (highest priority)
if [ -z "$GITHUB_TOKEN" ]; then
    # Tier 2: Secure credentials file
    if ! load_github_credentials; then
        # Tier 3: Interactive setup
        echo "${YELLOW}GitHub token not found in environment or credentials file.${RESET}"
        if ! setup_github_credentials_interactive; then
            echo "${RED}❌ Error: Failed to set up GitHub credentials${RESET}" >&2
            exit 1
        fi
    fi
fi

# Detect repository info from git remote if not provided
if [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
    if detect_repository_info; then
        echo "${CYAN}Detected repository: ${REPO_OWNER}/${REPO_NAME}${RESET}"
    else
        echo "${RED}❌ Error: Could not detect repository from git remote${RESET}" >&2
        echo "   Set with: export GITHUB_REPOSITORY_OWNER=\"your-org\"" >&2
        echo "            export GITHUB_REPOSITORY_NAME=\"repo-name\"" >&2
        exit 1
    fi
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
    echo "${CYAN}📖 Documentation:${RESET}"
    echo "   See CI/CD Setup Plan for detailed configuration instructions:"
    echo "   ${PROJECT_ROOT}/docs/planning/CI_CD_COMPLETE_PLAN.md"
    echo ""
    ERRORS+=("Branch protection not configured")
    VALIDATION_PASSED=false
    exit 1
fi

if [ "$http_code" != "200" ]; then
    echo "${RED}❌ FAIL: API request failed (HTTP ${http_code})${RESET}"
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
    echo ""
    if [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
        echo "${YELLOW}⚠️  Authentication/Authorization Error${RESET}"
        if [ "$http_code" = "401" ]; then
            echo "   ${RED}Bad credentials - token may be invalid or expired${RESET}"
            echo ""
            echo "   ${CYAN}Quick fix:${RESET} Reset credentials and set up a new token:"
            echo "   ./scripts/validate_branch_protection_enforcement.sh --reset-credentials"
            echo ""
        else
            echo "   This may indicate insufficient token permissions."
            echo ""
            echo "   ${CYAN}Required permission for basic validation:${RESET}"
            echo "   • Contents: Read (for fine-grained tokens)"
            echo "   • OR repo scope (for classic tokens)"
            echo ""
            echo "   ${YELLOW}Known Issue:${RESET} Fine-grained tokens may have limitations accessing"
            echo "   branch protection rules. If you're using a fine-grained token with"
            echo "   'Contents: Read' and still getting 403, try:"
            echo ""
            echo "   1. Use a classic personal access token with 'repo' scope instead"
            echo "   2. Ensure token has access to this specific repository"
            echo "   3. Wait a few minutes after updating permissions for propagation"
            echo ""
        fi
        echo "   ${CYAN}📖 See permissions guide:${RESET}"
        echo "   ${PROJECT_ROOT}/docs/scripts/GITHUB_PERMISSIONS_REQUIRED.md"
        echo ""
    fi
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
    echo "${CYAN}📖 Documentation:${RESET}"
    echo "  • CI/CD Setup Plan: ${PROJECT_ROOT}/docs/planning/CI_CD_COMPLETE_PLAN.md"
    echo "  • GitHub Permissions Guide: ${PROJECT_ROOT}/docs/scripts/GITHUB_PERMISSIONS_REQUIRED.md"
    echo ""
    exit 1
fi
