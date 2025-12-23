# GitHub Permissions Required for validate_branch_protection_enforcement.sh

**Last Updated:** 2025-12-23  
**Status:** ✅ Active

## Overview

The `validate_branch_protection_enforcement.sh` script requires GitHub API access to validate branch protection configuration. This document specifies the **minimum fine-grained permissions** needed following the principle of least privilege.

**⚠️ Important Note:** Fine-grained personal access tokens have limitations accessing branch protection rules. If you encounter 403 errors even with `Contents: Read`, you may need to:
1. Use a classic personal access token with `repo` scope, OR
2. Ensure the token has access to the specific repository (not just "all repositories")
3. Wait a few minutes after updating permissions for them to propagate

## Script Operations

### Basic Validation (Default Mode)

The script performs read-only operations:
- **GET** `/repos/{owner}/{repo}/branches/{branch}/protection` - Reads branch protection settings

### Full Validation (with `--test-enforcement`)

Additional operations when testing enforcement:
- **Git push** - Creates and pushes a test branch
- **Create PR** - Creates a pull request via GitHub CLI (`gh pr create`)
- **View PR** - Reads PR status via GitHub CLI (`gh pr view`)

## Required Permissions

### For Basic Validation (Default)

**Repository Permissions:**
- **Contents**: `Read` ✅
  - Required to read branch protection configuration via API
  - The branch protection endpoint requires repository read access
  - This is the **minimum** permission needed for basic validation

**Account Permissions:**
- None required

### For Full Validation (with `--test-enforcement`)

**Repository Permissions:**
- **Metadata**: `Read` ✅
  - Required to read branch protection configuration
- **Contents**: `Write` ✅
  - Required to push test branch to repository
- **Pull requests**: `Write` ✅
  - Required to create test pull requests
- **Pull requests**: `Read` ✅
  - Required to view PR merge status

**Account Permissions:**
- None required

## GitHub Token Configuration

**⚠️ Important:** Fine-grained personal access tokens have known limitations accessing branch protection rules. If you encounter 403 errors with a fine-grained token, use a classic token (Option 2) instead.

### Option 1: Fine-Grained Personal Access Token (May Have Limitations)

**For Basic Validation:**
1. Go to: https://github.com/settings/tokens?type=beta
2. Click "Generate new token" → "Generate new token (fine-grained)"
3. Configure:
   - **Token name**: `react2shell-branch-protection-readonly`
   - **Expiration**: Set appropriate expiration
   - **Repository access**: Select "Only select repositories" → Choose your repository
   - **Repository permissions**:
     - **Contents**: `Read` ✅
       - Required to read branch protection configuration
4. Generate token and save securely

**For Full Validation (with `--test-enforcement`):**
1. Go to: https://github.com/settings/tokens?type=beta
2. Click "Generate new token" → "Generate new token (fine-grained)"
3. Configure:
   - **Token name**: `react2shell-branch-protection-full`
   - **Expiration**: Set appropriate expiration
   - **Repository access**: Select "Only select repositories" → Choose your repository
   - **Repository permissions**:
     - **Contents**: `Write` ✅
       - Required to read branch protection and push test branch
     - **Pull requests**: `Read` ✅
       - Required to view PR merge status
     - **Pull requests**: `Write` ✅
       - Required to create test pull requests
4. Generate token and save securely

### Option 2: Classic Personal Access Token (Recommended - Works Reliably)

**Why Classic Token is Recommended:**
- Fine-grained tokens have known limitations accessing branch protection API endpoints
- Classic tokens with `repo` scope have proven, reliable access to branch protection rules
- Branch protection is considered an administrative API that may require broader permissions

**For Basic Validation:**
1. Go to: https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Configure:
   - **Token name**: `react2shell-branch-protection-readonly`
   - **Expiration**: Set appropriate expiration (recommended: 90 days or less)
   - **Scopes**: Select `repo` 
     - This grants read/write access to repositories
     - For public repos only, you can use `public_repo` scope (read-only)
     - Note: `repo` scope is broader than needed but required for branch protection API
4. Generate token and save securely

**For Full Validation (with `--test-enforcement`):**
1. Use the same classic token with `repo` scope (already includes write permissions)
2. Or create a separate token: `react2shell-branch-protection-full` with `repo` scope

### Option 3: GitHub Actions Workflow Token

When running in GitHub Actions, use the built-in `GITHUB_TOKEN`:

```yaml
permissions:
  contents: read      # Required for basic validation (branch protection API)
  # Add write permissions only if using --test-enforcement:
  # contents: write
  # pull-requests: read
  # pull-requests: write
```

**Note:** `GITHUB_TOKEN` in workflows has limited permissions by default. For `--test-enforcement`, you may need to use a Personal Access Token stored as a secret.

## Usage in GitHub Actions Workflow

### Basic Validation Workflow

```yaml
name: Validate Setup

on:
  workflow_dispatch:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday

permissions:
  contents: read  # Required to read branch protection configuration

jobs:
  validate:
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
          ./scripts/validate_branch_protection_enforcement.sh
```

### Full Validation with Enforcement Testing

```yaml
name: Validate Setup (Full)

on:
  workflow_dispatch:

permissions:
  contents: write      # Required for reading branch protection and pushing test branch
  pull-requests: read  # Required for viewing PR merge status
  pull-requests: write # Required for creating test PR

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}  # Or use PAT with write permissions
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq curl gh
      
      - name: Configure Git
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
      
      - name: Validate branch protection with enforcement test
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITHUB_REPOSITORY_OWNER: ${{ github.repository_owner }}
          GITHUB_REPOSITORY_NAME: ${{ github.event.repository.name }}
        run: |
          ./scripts/validate_branch_protection_enforcement.sh --test-enforcement
```

**Important:** The default `GITHUB_TOKEN` may not have sufficient permissions for `--test-enforcement`. You may need to:
1. Use a Personal Access Token stored as a repository secret, OR
2. Configure workflow permissions in repository settings to grant additional permissions

## Security Best Practices

1. **Use Classic Tokens for Branch Protection**: Due to fine-grained token limitations with branch protection API, classic tokens with `repo` scope are recommended for this use case
2. **Minimal Permissions**: Grant only the permissions needed for the specific use case
3. **Repository Scoping**: Limit token access to only the specific repository
4. **Token Expiration**: Set appropriate expiration dates
5. **Secure Storage**: Store tokens in secure credential files (`~/.secure/`) with `chmod 400`
6. **Rotate Regularly**: Rotate tokens periodically
7. **Separate Tokens**: Use different tokens for read-only vs. write operations

## Summary

| Operation | Contents | Pull Requests |
|-----------|----------|---------------|
| **Basic validation** | Read ✅ | - |
| **Full validation** | Write ✅ | Read ✅, Write ✅ |

**Minimum permissions for basic validation:** `Contents: Read` only.

**Minimum permissions for full validation:** `Contents: Write`, `Pull requests: Read`, `Pull requests: Write`.

**Note:** The branch protection API endpoint requires `Contents: Read` permission, not just `Metadata: Read`. This is because branch protection is part of the repository contents API.
