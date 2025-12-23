#!/bin/bash
# Verify navigation paths from README.md to all markdown files
# 
# Purpose: Validate that all markdown files in the project are reachable
#          from README.md through direct or indirect links
#
# Usage: ./scripts/verify_navigation_links.sh

set -e

cd "$(dirname "$0")/.." || exit 1

# Get all markdown files (excluding node_modules, venv, .git, etc.)
find . -name "*.md" -type f \
    ! -path "./.git/*" \
    ! -path "./node_modules/*" \
    ! -path "./*/node_modules/*" \
    ! -path "./venv/*" \
    ! -path "./tests/.pytest_cache/*" \
    ! -path "./.pids/*" \
    ! -path "./.logs/*" \
    | sort > /tmp/all_md_files.txt

TOTAL_FILES=$(wc -l < /tmp/all_md_files.txt | tr -d ' ')

echo "=========================================="
echo "Navigation Link Validation"
echo "=========================================="
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
    if grep -q "$file" README.md 2>/dev/null; then
        echo "✅ $description - Linked in README.md"
        return 0
    else
        echo "❌ $description - NOT linked in README.md"
        MISSING=$((MISSING + 1))
        return 1
    fi
}

check_link "README-AI-CODING-STANDARDS.md" "README-AI-CODING-STANDARDS.md"
check_link "PROJECT_REVIEW_SUMMARY.md" "PROJECT_REVIEW_SUMMARY.md"
check_link "DOCUMENTATION_AND_MAKEFILE_ANALYSIS.md" "DOCUMENTATION_AND_MAKEFILE_ANALYSIS.md"
check_link "docs/README.md" "docs/README.md"
check_link "scripts/README.md" "scripts/README.md"

echo ""
echo "=== Checking docs/README.md links ==="

check_docs_link() {
    local file=$1
    local description=$2
    if grep -q "$file" docs/README.md 2>/dev/null; then
        echo "✅ $description - Linked in docs/README.md"
        return 0
    else
        echo "❌ $description - NOT linked in docs/README.md"
        MISSING=$((MISSING + 1))
        return 1
    fi
}

check_docs_link "DOCUMENTATION_REVIEW_2025-12-23.md" "docs/DOCUMENTATION_REVIEW_2025-12-23.md"
check_docs_link "REORGANIZATION_RECOMMENDATION.md" "docs/REORGANIZATION_RECOMMENDATION.md"
check_docs_link "REORGANIZATION_SUMMARY.md" "docs/REORGANIZATION_SUMMARY.md"
check_docs_link "DESIGN_PROPOSAL_TEST_NEXTJS_STARTUP.md" "docs/DESIGN_PROPOSAL_TEST_NEXTJS_STARTUP.md"

echo ""
echo "=========================================="
if [ $MISSING -eq 0 ]; then
    echo "✅ VALIDATION PASSED: All key files are linked"
    echo "   Total files: $TOTAL_FILES"
    echo "   Missing links: 0"
    exit 0
else
    echo "❌ VALIDATION FAILED: $MISSING file(s) not linked"
    echo "   Total files: $TOTAL_FILES"
    echo "   Missing links: $MISSING"
    exit 1
fi
