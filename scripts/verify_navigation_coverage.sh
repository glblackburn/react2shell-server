#!/bin/bash
# Verify navigation paths from README.md to all markdown files
# This script validates that all markdown files in the project are reachable from README.md

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Get all markdown files (excluding node_modules, venv, .git, etc.)
find . -name "*.md" -type f \
    ! -path "./.git/*" \
    ! -path "./node_modules/*" \
    ! -path "./*/node_modules/*" \
    ! -path "./venv/*" \
    ! -path "./tests/.pytest_cache/*" \
    ! -path "./.pids/*" \
    ! -path "./.logs/*" \
    | sort > /tmp/all_files.txt

TOTAL_FILES=$(wc -l < /tmp/all_files.txt | tr -d ' ')

echo "=========================================="
echo "Navigation Coverage Validation"
echo "=========================================="
echo ""
echo "Total markdown files: $TOTAL_FILES"
echo ""

echo "=== Files directly linked from README.md ==="
DIRECT_LINKS=$(grep -E "\[.*\]\(.*\.md\)" README.md | grep -v "^#" | wc -l | tr -d ' ')
echo "Found $DIRECT_LINKS direct markdown links in README.md"
echo ""

echo "=== Checking if key files are linked ==="
MISSING=0

check_link() {
    local file=$1
    local description=$2
    if grep -q "$file" README.md; then
        echo "✅ $description - Linked in README.md"
        return 0
    else
        echo "❌ $description - NOT linked in README.md"
        MISSING=$((MISSING + 1))
        return 1
    fi
}

check_link "README-AI-CODING-STANDARDS.md" "AI Coding Standards"
check_link "PROJECT_REVIEW_SUMMARY.md" "Project Review Summary"
check_link "DOCUMENTATION_AND_MAKEFILE_ANALYSIS.md" "Documentation and Makefile Analysis"
check_link "docs/README.md" "Documentation Index"
check_link "scripts/README.md" "Scripts Documentation"

echo ""
echo "=== Checking docs/README.md links ==="

check_docs_link() {
    local file=$1
    local description=$2
    if grep -q "$file" docs/README.md; then
        echo "✅ $description - Linked in docs/README.md"
        return 0
    else
        echo "❌ $description - NOT linked in docs/README.md"
        MISSING=$((MISSING + 1))
        return 1
    fi
}

check_docs_link "DOCUMENTATION_REVIEW_2025-12-23.md" "Documentation Review"
check_docs_link "REORGANIZATION_RECOMMENDATION.md" "Reorganization Recommendation"
check_docs_link "REORGANIZATION_SUMMARY.md" "Reorganization Summary"
check_docs_link "DESIGN_PROPOSAL_TEST_NEXTJS_STARTUP.md" "Design Proposal: Next.js Startup Test"

echo ""
echo "=========================================="
if [ $MISSING -eq 0 ]; then
    echo "✅ VALIDATION PASSED: All key files are linked"
    echo "   Coverage: 100%"
    exit 0
else
    echo "❌ VALIDATION FAILED: $MISSING file(s) missing links"
    echo "   See gaps above"
    exit 1
fi
