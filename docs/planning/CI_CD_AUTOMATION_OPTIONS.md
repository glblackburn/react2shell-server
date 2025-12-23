# CI/CD Automation Options: Branch Protection and Pipeline Creation

**Date:** 2025-12-23  
**Status:** Planning  
**Purpose:** Document automation options for branch protection and CI/CD pipeline setup

---

## Table of Contents

1. [Branch Protection Automation](#branch-protection-automation)
2. [CI/CD Pipeline Creation Options](#cicd-pipeline-creation-options)
3. [Infrastructure as Code Approaches](#infrastructure-as-code-approaches)
4. [Validation and Verification Scripts](#validation-and-verification-scripts)
5. [Recommended Approach](#recommended-approach)

---

## Branch Protection Automation

### Option 1: GitHub API Script (Recommended for Validation)

**Use Case:** Validate branch protection is configured correctly

**Tools:**
- GitHub REST API
- `curl` or `jq` for API calls
- Shell script or Python script

**Pros:**
- Simple to implement
- Good for validation/verification
- No additional dependencies
- Can be run in CI/CD

**Cons:**
- Manual configuration still required
- Not ideal for initial setup

**Example Script:** `scripts/validate_branch_protection.sh`

```bash
#!/usr/bin/env bash
# Validate branch protection configuration via GitHub API

set -euET -o pipefail

REPO_OWNER="${GITHUB_REPOSITORY_OWNER:-}"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-}"
BRANCH="main"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable required" >&2
    exit 1
fi

if [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
    echo "Error: Repository owner and name required" >&2
    echo "Set GITHUB_REPOSITORY_OWNER and GITHUB_REPOSITORY_NAME" >&2
    exit 1
fi

API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/branches/${BRANCH}/protection"

echo "Checking branch protection for ${REPO_OWNER}/${REPO_NAME}:${BRANCH}..."

# Check if branch protection exists
response=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    "$API_URL")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "404" ]; then
    echo "❌ FAIL: Branch protection not configured for ${BRANCH}"
    exit 1
fi

if [ "$http_code" != "200" ]; then
    echo "❌ FAIL: API request failed (HTTP ${http_code})"
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
    exit 1
fi

# Validate required settings
echo "Validating branch protection settings..."

# Check required pull request reviews
required_pr=$(echo "$body" | jq -r '.required_pull_request_reviews // empty')
if [ -z "$required_pr" ] || [ "$required_pr" = "null" ]; then
    echo "❌ FAIL: Required pull request reviews not enabled"
    exit 1
fi

# Check required status checks
required_status_checks=$(echo "$body" | jq -r '.required_status_checks // empty')
if [ -z "$required_status_checks" ] || [ "$required_status_checks" = "null" ]; then
    echo "❌ FAIL: Required status checks not configured"
    exit 1
fi

# Check if administrators are included
enforce_admins=$(echo "$body" | jq -r '.enforce_admins.enabled // false')
if [ "$enforce_admins" != "true" ]; then
    echo "⚠️  WARNING: Administrators not included in protection (not enforced)"
fi

# Check if allow force pushes is disabled
allow_force_pushes=$(echo "$body" | jq -r '.allow_force_pushes // false')
if [ "$allow_force_pushes" = "true" ]; then
    echo "⚠️  WARNING: Force pushes are allowed (not recommended)"
fi

# Check if allow deletions is disabled
allow_deletions=$(echo "$body" | jq -r '.allow_deletions // false')
if [ "$allow_deletions" = "true" ]; then
    echo "⚠️  WARNING: Branch deletion is allowed (not recommended)"
fi

echo "✅ PASS: Branch protection is configured correctly"
echo ""
echo "Summary:"
echo "  - Required PR reviews: ✅"
echo "  - Required status checks: ✅"
echo "  - Enforce admins: $([ "$enforce_admins" = "true" ] && echo "✅" || echo "⚠️")"
echo "  - Force pushes: $([ "$allow_force_pushes" = "true" ] && echo "⚠️" || echo "✅")"
echo "  - Deletions: $([ "$allow_deletions" = "true" ] && echo "⚠️" || echo "✅")"

exit 0
```

**Usage:**
```bash
export GITHUB_TOKEN="ghp_..."
export GITHUB_REPOSITORY_OWNER="your-org"
export GITHUB_REPOSITORY_NAME="react2shell-server"
./scripts/validate_branch_protection.sh
```

### Option 2: Terraform (Recommended for Configuration)

**Use Case:** Configure branch protection as Infrastructure as Code

**Tools:**
- Terraform
- `terraform-provider-github`

**Pros:**
- Infrastructure as Code
- Version controlled
- Reproducible
- Can manage multiple repositories
- Can be applied via CI/CD

**Cons:**
- Requires Terraform setup
- Additional learning curve
- Need to manage Terraform state

**Example:** `terraform/branch-protection.tf`

```hcl
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub organization or username"
  type        = string
}

variable "repository_name" {
  description = "Repository name"
  type        = string
  default     = "react2shell-server"
}

# Branch protection for main branch
resource "github_branch_protection" "main" {
  repository_id = var.repository_name
  pattern       = "main"

  # Require pull request reviews
  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = false
  }

  # Require status checks
  required_status_checks {
    strict   = true  # Require branches to be up to date
    contexts = [
      "lint",
      "test-vite",
      "test-nextjs",
      "test-python / vite",
      "test-python / nextjs",
      "validate-versions"
    ]
  }

  # Enforce for administrators
  enforce_admins = true

  # Prevent force pushes
  allows_force_pushes = false

  # Prevent deletions
  allows_deletions = false

  # Require conversation resolution
  require_conversation_resolution = true
}

# Output for validation
output "branch_protection_id" {
  value       = github_branch_protection.main.id
  description = "Branch protection rule ID"
}
```

**Usage:**
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Option 3: GitHub CLI (gh)

**Use Case:** Quick configuration and validation via command line

**Tools:**
- GitHub CLI (`gh`)

**Pros:**
- Simple command-line interface
- Good for quick setup
- Can be scripted

**Cons:**
- Not version controlled (unless scripted)
- Manual process
- Less suitable for automation

**Example Commands:**

```bash
# Check branch protection
gh api repos/:owner/:repo/branches/main/protection

# Configure via API (complex, better to use UI or Terraform)
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_pull_request_reviews[required_approving_review_count]=1 \
  --field enforce_admins=true
```

### Option 4: Python Script (GitHub API)

**Use Case:** More complex validation or configuration logic

**Example:** `scripts/validate_branch_protection.py`

```python
#!/usr/bin/env python3
"""Validate branch protection configuration."""

import os
import sys
import requests
import json

GITHUB_TOKEN = os.environ.get('GITHUB_TOKEN')
REPO_OWNER = os.environ.get('GITHUB_REPOSITORY_OWNER')
REPO_NAME = os.environ.get('GITHUB_REPOSITORY_NAME')
BRANCH = 'main'

if not all([GITHUB_TOKEN, REPO_OWNER, REPO_NAME]):
    print("Error: GITHUB_TOKEN, GITHUB_REPOSITORY_OWNER, and GITHUB_REPOSITORY_NAME required")
    sys.exit(1)

headers = {
    'Authorization': f'token {GITHUB_TOKEN}',
    'Accept': 'application/vnd.github.v3+json'
}

url = f'https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/branches/{BRANCH}/protection'

response = requests.get(url, headers=headers)

if response.status_code == 404:
    print(f"❌ FAIL: Branch protection not configured for {BRANCH}")
    sys.exit(1)

if response.status_code != 200:
    print(f"❌ FAIL: API request failed (HTTP {response.status_code})")
    print(response.text)
    sys.exit(1)

data = response.json()

# Validate settings
errors = []
warnings = []

if not data.get('required_pull_request_reviews'):
    errors.append("Required pull request reviews not enabled")

if not data.get('required_status_checks'):
    errors.append("Required status checks not configured")

if not data.get('enforce_admins', {}).get('enabled'):
    warnings.append("Administrators not included in protection")

if data.get('allow_force_pushes'):
    warnings.append("Force pushes are allowed")

if data.get('allow_deletions'):
    warnings.append("Branch deletion is allowed")

if errors:
    print("❌ FAIL: Branch protection validation failed")
    for error in errors:
        print(f"  - {error}")
    sys.exit(1)

if warnings:
    print("⚠️  WARNINGS:")
    for warning in warnings:
        print(f"  - {warning}")

print("✅ PASS: Branch protection is configured correctly")
sys.exit(0)
```

---

## CI/CD Pipeline Creation Options

### Option 1: Manual YAML Files (Current Plan)

**Use Case:** Standard approach, full control

**How it works:**
- Create `.github/workflows/*.yml` files manually
- Commit to repository
- GitHub automatically recognizes and runs workflows

**Pros:**
- Simple and straightforward
- Full control over workflow content
- Easy to understand and modify
- No additional tools required
- Version controlled in repository

**Cons:**
- Manual creation
- No validation before commit
- Can't easily manage multiple repositories

**Implementation:**
```bash
# Create workflow files
mkdir -p .github/workflows
cat > .github/workflows/ci.yml << 'EOF'
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: make test
EOF

git add .github/workflows/ci.yml
git commit -m "Add CI workflow"
```

### Option 2: Terraform GitHub Provider

**Use Case:** Manage workflows as Infrastructure as Code

**Tools:**
- Terraform
- `terraform-provider-github`

**Pros:**
- Infrastructure as Code
- Version controlled
- Can manage multiple repositories
- Can be applied via CI/CD
- Reproducible

**Cons:**
- Requires Terraform setup
- YAML content in HCL (can be verbose)
- Need to manage Terraform state
- Less intuitive than YAML

**Example:** `terraform/workflows.tf`

```hcl
resource "github_repository_file" "ci_workflow" {
  repository          = var.repository_name
  branch              = "main"
  file                = ".github/workflows/ci.yml"
  content             = file("${path.module}/workflows/ci.yml")
  commit_message      = "Add CI workflow"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}
```

**Workflow file:** `terraform/workflows/ci.yml` (standard YAML)

### Option 3: GitHub Actions Templates / Generators

**Use Case:** Generate workflows from templates

**Tools:**
- GitHub Actions templates
- Custom generators
- Workflow generators (e.g., `action-docs`)

**Pros:**
- Consistent workflow structure
- Can generate from templates
- Less manual work

**Cons:**
- Still need to customize
- Limited flexibility
- Additional tooling

**Example:** Using a template generator script

```bash
#!/bin/bash
# generate_workflow.sh

cat > .github/workflows/ci.yml << EOF
name: CI
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Lint
        run: make lint

  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - name: Test
        run: make test
EOF
```

### Option 4: GitHub API / CLI Scripts

**Use Case:** Programmatic workflow creation

**Tools:**
- GitHub API
- GitHub CLI (`gh`)
- Custom scripts

**Pros:**
- Can be automated
- Can manage multiple repos
- Scriptable

**Cons:**
- Complex API calls
- Need to handle YAML encoding
- Less intuitive

**Example:** Using GitHub CLI

```bash
# Create workflow file via API
gh api repos/:owner/:repo/contents/.github/workflows/ci.yml \
  --method PUT \
  --field message="Add CI workflow" \
  --field content="$(base64 -i ci.yml)"
```

### Option 5: Workflow Management Tools

**Use Case:** Enterprise workflow management

**Tools:**
- GitHub Actions Importer
- Third-party CI/CD tools
- Custom workflow management platforms

**Pros:**
- Enterprise features
- Advanced management
- Migration tools

**Cons:**
- Additional cost/complexity
- Vendor lock-in
- Overkill for small projects

---

## Infrastructure as Code Approaches

### Approach 1: Terraform (Recommended for Multi-Repo)

**Structure:**
```
terraform/
├── main.tf
├── variables.tf
├── branch-protection.tf
├── workflows.tf
└── workflows/
    ├── ci.yml
    ├── version-validation.yml
    └── performance-check.yml
```

**Benefits:**
- Single source of truth
- Version controlled
- Reproducible
- Can manage multiple repositories
- Can be applied via CI/CD

**Setup:**
```bash
# Initialize Terraform
cd terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### Approach 2: Ansible

**Use Case:** Configuration management

**Example:** `ansible/branch-protection.yml`

```yaml
- name: Configure branch protection
  hosts: localhost
  tasks:
    - name: Set branch protection
      github_branch_protection:
        repo: "{{ github_repo }}"
        branch: main
        required_pull_request_reviews:
          required_approving_review_count: 1
        required_status_checks:
          strict: true
          contexts:
            - lint
            - test-vite
```

### Approach 3: Pulumi

**Use Case:** Modern IaC with multiple languages

**Example:** `infrastructure/index.ts`

```typescript
import * as github from "@pulumi/github";

const repo = new github.Repository("react2shell-server", {
    name: "react2shell-server",
    // ... repo config
});

const branchProtection = new github.BranchProtection("main", {
    repositoryId: repo.id,
    pattern: "main",
    requiredPullRequestReviews: {
        requiredApprovingReviewCount: 1,
    },
    requiredStatusChecks: {
        strict: true,
        contexts: ["lint", "test-vite", "test-nextjs"],
    },
    enforceAdmins: true,
});
```

---

## Validation and Verification Scripts

### Comprehensive Validation Script

**File:** `scripts/validate_github_setup.sh`

```bash
#!/usr/bin/env bash
# Comprehensive validation of GitHub repository setup
# Validates branch protection, workflows, and required status checks

set -euET -o pipefail

REPO_OWNER="${GITHUB_REPOSITORY_OWNER:-}"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN required" >&2
    exit 1
fi

API_BASE="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}"

echo "Validating GitHub repository setup..."
echo "Repository: ${REPO_OWNER}/${REPO_NAME}"
echo ""

# Check branch protection
echo "1. Checking branch protection..."
./scripts/validate_branch_protection.sh
BRANCH_PROTECTION_STATUS=$?

# Check workflows exist
echo ""
echo "2. Checking GitHub Actions workflows..."
WORKFLOWS=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    "${API_BASE}/actions/workflows" | jq -r '.workflows[].name')

if [ -z "$WORKFLOWS" ]; then
    echo "❌ FAIL: No workflows found"
    WORKFLOW_STATUS=1
else
    echo "✅ Found workflows:"
    echo "$WORKFLOWS" | while read -r workflow; do
        echo "  - $workflow"
    done
    WORKFLOW_STATUS=0
fi

# Check required status checks
echo ""
echo "3. Checking required status checks..."
STATUS_CHECKS=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    "${API_BASE}/branches/main/protection/required_status_checks" | \
    jq -r '.contexts[]?')

if [ -z "$STATUS_CHECKS" ]; then
    echo "⚠️  WARNING: No required status checks configured"
    STATUS_CHECK_STATUS=1
else
    echo "✅ Required status checks:"
    echo "$STATUS_CHECKS" | while read -r check; do
        echo "  - $check"
    done
    STATUS_CHECK_STATUS=0
fi

# Summary
echo ""
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo "Branch Protection: $([ $BRANCH_PROTECTION_STATUS -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "Workflows: $([ $WORKFLOW_STATUS -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "Status Checks: $([ $STATUS_CHECK_STATUS -eq 0 ] && echo "✅ PASS" || echo "⚠️  WARN")"
echo ""

if [ $BRANCH_PROTECTION_STATUS -ne 0 ] || [ $WORKFLOW_STATUS -ne 0 ]; then
    echo "❌ Validation failed"
    exit 1
fi

echo "✅ All validations passed"
exit 0
```

### CI/CD Validation Workflow

**File:** `.github/workflows/validate-setup.yml`

```yaml
name: Validate GitHub Setup

on:
  workflow_dispatch:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday

jobs:
  validate:
    name: Validate Repository Setup
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq curl
      
      - name: Validate branch protection
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITHUB_REPOSITORY_OWNER: ${{ github.repository_owner }}
          GITHUB_REPOSITORY_NAME: ${{ github.event.repository.name }}
        run: |
          chmod +x scripts/validate_branch_protection.sh
          ./scripts/validate_branch_protection.sh
      
      - name: Validate workflows exist
        run: |
          if [ ! -f .github/workflows/ci.yml ]; then
            echo "❌ CI workflow not found"
            exit 1
          fi
          echo "✅ Workflows found"
```

---

## Recommended Approach

### For This Project

**Branch Protection:**
1. **Initial Setup:** Manual configuration via GitHub UI (fastest)
2. **Validation:** Automated script (`scripts/validate_branch_protection.sh`)
3. **Future:** Consider Terraform if managing multiple repositories

**CI/CD Pipeline:**
1. **Initial Setup:** Manual YAML files (current plan - simplest)
2. **Validation:** Check workflow files exist and are valid
3. **Future:** Consider Terraform if managing multiple repositories

**Validation:**
1. Create validation scripts (bash/Python)
2. Run validation in CI/CD workflow
3. Run validation on schedule (weekly)

### Implementation Steps

1. **Create validation scripts:**
   ```bash
   scripts/validate_branch_protection.sh
   scripts/validate_github_setup.sh
   ```

2. **Add validation to CI/CD:**
   - Create `.github/workflows/validate-setup.yml`
   - Run validation weekly or on demand

3. **Document automation options:**
   - This document serves as reference
   - Update main CI/CD plan with automation section

4. **Future enhancement:**
   - Consider Terraform if project scales
   - Add infrastructure as code for multi-repo management

---

## Next Steps

1. **Create validation scripts** (bash/Python)
2. **Add validation workflow** to CI/CD
3. **Test validation scripts** locally
4. **Document usage** in main CI/CD plan
5. **Consider Terraform** for future if needed

---

**End of Automation Options Document**
