# Branch Protection Setup Guide

**Last Updated:** 2025-12-23  
**Status:** ✅ Active

This guide provides step-by-step instructions for configuring GitHub branch protection to enforce CI/CD requirements and prevent commits that bypass automation.

**Important:** GitHub offers two branch protection systems:
- **Branch Rulesets** (newer system) - Do NOT use this
- **Classic Branch Protection Rules** (older system) - **Use this one** ✅

This guide and the validation script use **Classic Branch Protection Rules**. When you see both options, always choose "Add classic branch protection rule".

## Quick Start

1. **Navigate to branch protection settings:**
   - **Direct link:** [https://github.com/{owner}/{repo}/settings/branches](https://github.com/{owner}/{repo}/settings/branches)
   - (The script will automatically populate this URL when you run it)
   - You should see the "Branch protection rules" page
   - If you see **"Classic branch protections have not been configured"**, you're in the right place

2. **Choose "Add classic branch protection rule":**
   - You'll see TWO buttons on the page:
     - **"Add branch ruleset"** (newer system - do NOT use this)
     - **"Add classic branch protection rule"** (use this one ✅)
   - **Click "Add classic branch protection rule"** - this is what the validation script checks

3. **Enter branch name pattern:**
   - Enter `main` to protect your main branch
   - Or enter a pattern like `*` to protect all branches

4. **Configure required settings** (see detailed instructions below):
   - ✅ **Require a pull request before merging** (set to 1+ approvals)
   - ✅ **Require status checks to pass** (search and add your CI/CD check names in the "Search for status checks" section)
   - ✅ **Require branches to be up to date** (separate checkbox)
   - ✅ **Do not allow bypassing the above settings** (CRITICAL - in "Rules applied to everyone including administrators" section at the bottom)
   - ❌ **Do NOT check** "Allow force pushes" (in "Rules applied to everyone" section)
   - ❌ **Do NOT check** "Allow deletions" (in "Rules applied to everyone" section)

5. **Save the rule:**
   - Click **"Create"** or **"Save changes"** button at the bottom

## Required Settings - Detailed Instructions

**Note:** This section explains what you'll see in the GitHub form. The GitHub UI shows checkboxes and form fields, not these section headings. Use this as a guide to find and configure each setting.

After clicking "Add classic branch protection rule" and entering your branch name, you'll see a form with various checkboxes and options. This section explains each setting you need to configure:

### 1. Pull Request Requirements (Required)

**Check "Require a pull request before merging"**
- **Required number of approvals before merging:** Set to at least `1` (recommended: 1-2)
- ✅ **Check "Dismiss stale pull request approvals when new commits are pushed"**
- ✅ **Check "Require review from Code Owners"** (if you use CODEOWNERS file)

**Why this is critical:**
- Prevents direct pushes to protected branch
- Ensures all changes go through pull request process
- Allows CI/CD to run before merge

### 2. Status Checks (Required)

**Check "Require status checks to pass before merging"**
- ✅ **Check "Require branches to be up to date before merging"** (CRITICAL - this is usually a separate checkbox)
- In the **"Search for status checks"** section at the top of the form:
  - Use the search bar to find your CI/CD job names
  - Select each check to add it to the required list:
    - `lint`
    - `test-vite`
    - `test-nextjs`
    - `validate-versions`
  - (Note: You may need to run workflows first for status checks to appear)

**Why this is critical:**
- Ensures CI/CD must pass before merge
- Prevents merging broken code
- "Require branches to be up to date" ensures latest CI results are used

### 3. Administrator Enforcement (CRITICAL - Most Important!)

**In the "Rules applied to everyone including administrators" section:**

**Check "Do not allow bypassing the above settings"**
- ✅ **MUST BE CHECKED** - This is the most critical setting
- This applies all protection rules to administrators
- Without this, admins can push directly and bypass CI/CD

**Why this is critical:**
- Without this setting, administrators can bypass all protection rules
- This defeats the purpose of branch protection
- All changes must go through CI/CD, even from admins

### 4. Additional Restrictions

**In the "Rules applied to everyone including administrators" section:**

**Force pushes:**
- ❌ **Do NOT check "Allow force pushes"** (leave unchecked)
- Force pushes can rewrite history and bypass protection

**Branch deletion:**
- ❌ **Do NOT check "Allow deletions"** (leave unchecked)
- Prevents accidental or malicious branch deletion

## Step-by-Step Configuration

### Via GitHub Web Interface

1. **Navigate to Branch Protection Settings:**
   - Go to: [https://github.com/{owner}/{repo}/settings/branches](https://github.com/{owner}/{repo}/settings/branches)
   - (The script automatically populates this URL when you run it)
   - You should see the "Branch protection rules" page
   - If you see **"Classic branch protections have not been configured"**, you're in the right place
   - This message indicates no branch protection rules exist yet - you need to create one

2. **Choose the Correct Button:**
   - You'll see TWO buttons on the page:
     - **"Add branch ruleset"** - This is the newer ruleset system (do NOT use this)
     - **"Add classic branch protection rule"** - This is what you need ✅
   - **IMPORTANT:** Click **"Add classic branch protection rule"** (the secondary button)
   - **Why classic?** The validation script checks classic branch protection via the GitHub API
   - Rulesets use a different API endpoint and won't be detected by the validation script

3. **Enter Branch Name Pattern:**
   - You'll be prompted to enter a branch name pattern
   - Enter `main` to protect your main branch
   - Or enter `*` to protect all branches
   - After entering the branch name, the page will show configuration options

3. **Configure Required Settings:**

   **Pull Request Requirements:**
   - ✅ Check the box for **"Require a pull request before merging"** or **"Require pull request reviews before merging"**
     - Set **"Required number of approvals before merging"** to at least `1`
     - ✅ Check **"Dismiss stale pull request approvals when new commits are pushed"**
     - ✅ Check **"Require review from Code Owners"** (if you use CODEOWNERS file)

   **Status Checks:**
   - ✅ Check the box for **"Require status checks to pass before merging"**
     - ✅ Check **"Require branches to be up to date before merging"** (CRITICAL - usually a separate checkbox)
     - In the **"Status checks that are required"** or **"Required status checks"** section:
       - Search for or type your CI/CD job names
       - Add each required check:
         - `lint`
         - `test-vite`
         - `test-nextjs`
         - `validate-versions`
       - (Note: You may need to run workflows first for status checks to appear in the list)

   **Rules Applied to Everyone Including Administrators (CRITICAL - Most Important!):**
   - This section is at the bottom of the form
   - ✅ **Check "Do not allow bypassing the above settings"**
     - This is the MOST IMPORTANT setting - it applies all rules to administrators
     - Without this, admins can bypass all protection rules and push directly
   - ❌ **Do NOT check "Allow force pushes"** (leave unchecked)
   - ❌ **Do NOT check "Allow deletions"** (leave unchecked)

4. **Save the Rule:**
   - Scroll to the bottom of the form
   - Click **"Create"**, **"Save changes"**, or **"Create branch protection rule"** button
   - You should see a confirmation that the rule was created

### Verification

After configuring, verify the settings:

1. **Test Direct Push (Should Fail):**
   ```bash
   git checkout main
   git commit --allow-empty -m "Test: Direct push"
   git push origin main
   # Should fail with: "remote: error: GH006: Protected branch update failed"
   ```

2. **Test Pull Request (Should Work):**
   ```bash
   git checkout -b test-branch
   git commit --allow-empty -m "Test: PR"
   git push origin test-branch
   # Create PR via GitHub web interface
   # PR should be created successfully
   # PR should show required status checks
   # PR should not be mergeable until checks pass
   ```

3. **Use Validation Script:**
   ```bash
   ./scripts/validate_branch_protection_enforcement.sh
   ```

## Common Issues

### Issue: "Administrators can still push directly"

**Solution:** Ensure "Do not allow bypassing the above settings" is checked in the "Rules applied to everyone including administrators" section. This is the most common mistake.

### Issue: "PRs can be merged without CI passing"

**Solution:** 
- Check that "Require status checks to pass before merging" is enabled
- Verify required status checks are listed
- Ensure "Require branches to be up to date" is enabled

### Issue: "Status checks not showing in PR"

**Solution:**
- Ensure workflows are running and creating status checks
- Check that status check names match exactly (case-sensitive)
- Wait a few minutes for GitHub to update

### Issue: "Can't merge PR even though checks passed"

**Solution:**
- Check "Require branches to be up to date" - PR branch may need to be updated
- Verify all required status checks are listed and passing
- Check if there are other restrictions (conversation resolution, etc.)

## Required Status Checks

For this project, the following status checks should be required:

- `lint` - Code linting and validation
- `test-vite` - Vite framework tests
- `test-nextjs` - Next.js framework tests
- `validate-versions` - Version validation

**Note:** Status check names must match exactly what appears in GitHub Actions. Check your workflow files for the exact job names.

## Security Best Practices

1. **Always check "Do not allow bypassing the above settings"** - This is non-negotiable
2. **Require at least 1 approval** - Prevents single-person merges
3. **Require branches to be up to date** - Ensures latest CI results
4. **Disable force pushes** - Prevents history rewriting
5. **Disable branch deletion** - Prevents accidental deletion
6. **Use "Do not allow bypassing"** - Additional security layer

## Related Documentation

- **GitHub Permissions Guide:** `docs/scripts/GITHUB_PERMISSIONS_REQUIRED.md`
- **CI/CD Setup Plan:** `docs/planning/CI_CD_COMPLETE_PLAN.md` (complete CI/CD setup)
- **Validation Script:** `scripts/validate_branch_protection_enforcement.sh`

## Quick Reference Checklist

- [ ] Navigate to: `https://github.com/{owner}/{repo}/settings/branches`
- [ ] Click **"Add classic branch protection rule"** button (NOT "Add branch ruleset")
- [ ] Enter branch name pattern (e.g., `main`)
- [ ] **Check "Require a pull request before merging"**
  - [ ] Set required approvals to at least `1`
  - [ ] Check "Dismiss stale pull request approvals"
- [ ] **Check "Require status checks to pass before merging"**
  - [ ] Check "Require branches to be up to date before merging"
  - [ ] In "Search for status checks" section, search and add: `lint`, `test-vite`, `test-nextjs`, `validate-versions`
- [ ] **In "Rules applied to everyone including administrators" section:**
  - [ ] **Check "Do not allow bypassing the above settings" (CRITICAL - Most Important!)**
- [ ] **Do NOT check** "Allow force pushes" (leave unchecked)
- [ ] **Do NOT check** "Allow deletions" (leave unchecked)
- [ ] Click "Create" or "Save changes" button
- [ ] Test with validation script: `./scripts/validate_branch_protection_enforcement.sh`
- [ ] Verify direct push fails
- [ ] Verify PR requires checks to pass
