# AI Coding Standards Violations Log

This document tracks violations of AI coding standards to help prevent future occurrences.

## Format

Each violation entry includes:
- **Date:** When the violation occurred
- **Session:** Brief description of the session/work
- **Violation Type:** Category of violation
- **Rule Violated:** Specific rule from README-AI-CODING-STANDARDS.md
- **Description:** What happened
- **Root Cause:** Why it happened
- **Impact:** Severity and consequences
- **Corrective Action:** What was done to fix it
- **Prevention:** How to prevent in future

---

## Violation #1: Commit Without Showing Commit Information First

**Date:** 2025-12-23  
**Session:** Add setup workflow and improve branch protection validation script  
**Commit:** `69a3f22` - "Add test_token_scopes.sh utility script"

### Violation Type
Git Operations - Mandatory Commit Workflow

### Rule Violated
Section 2 - Git Operations, Mandatory Commit Workflow (Two-Step Process)
- Step 1 requires showing commit message, files, and diff stats BEFORE committing
- Step 2 requires waiting for explicit user confirmation in a separate message

### Description
User requested: "save test_token_scopes.sh with the other validation script"

The AI assistant:
1. Moved the file to scripts directory
2. Committed directly without showing commit information first
3. Did not follow the mandatory two-step commit workflow

### Root Cause
**Misinterpretation of user request:**
- Interpreted "save X with Y" as a direct commit instruction
- Should have interpreted as "prepare commit for saving X with Y"
- Did not recognize this as a commit-related request requiring the two-step process

### Impact
**Severity:** Major  
**Consequences:**
- User did not have opportunity to review commit message, files, or changes before commit
- Violates mandatory workflow designed to prevent accidental commits
- User lost ability to modify commit message or review changes before execution

### Corrective Action
1. Created session review document documenting the violation
2. Identified the root cause (misinterpretation of user request)
3. Documented prevention measures

### Prevention
**For AI Assistants:**
1. **Interpretation Rule:** When user says "save X", "add Y", "move Z", always interpret as "prepare commit for X/Y/Z", not "commit X/Y/Z immediately"
2. **Always Show First:** Even for simple operations, show commit information before executing
3. **When in Doubt:** Err on the side of showing commit info first - it's better to show too much than commit without showing

**For Users:**
- Be explicit: "prepare commit for X" vs "commit X"
- Review commit information when shown before confirming

### Related Documentation
- Session Review: `docs/ai-standards/AI_STANDARDS_SESSION_REVIEW_2025-12-23.md`
- Standards Reference: `README-AI-CODING-STANDARDS.md` Section 2

---

## Violation #2: Accepted "commit" as Confirmation

**Date:** 2025-12-23  
**Session:** Add setup workflow and improve branch protection validation script  
**Commits:** `0b5a6f5`, `7246bf4`

### Violation Type
Git Operations - Confirmation Requirements

### Rule Violated
Section 2 - Git Operations, "What Does NOT Count as Confirmation"
- "User saying 'commit' (this is the request, not confirmation)"
- "User saying 'commit [file]' (this is the request, not confirmation)"

### Description
In two separate commits:
1. Commit info was shown correctly (Step 1 completed)
2. User responded with "commit" again
3. AI assistant interpreted "commit" as confirmation and proceeded

### Root Cause
**Over-interpretation of user intent:**
- Commit info was shown first, so intent seemed clear
- Did not strictly follow the rule that "commit" is never confirmation
- Should have required explicit confirmation like "yes", "go ahead", "proceed"

### Impact
**Severity:** Minor  
**Consequences:**
- Low impact since commit info was shown first
- User had opportunity to review before commit
- Violates letter of the rule but not the spirit

### Corrective Action
1. Documented in session review
2. Identified need for stricter confirmation requirements

### Prevention
**For AI Assistants:**
1. **Strict Rule:** Never accept "commit" as confirmation, even after showing commit info
2. **Required Phrases:** Only accept explicit confirmations: "yes", "go ahead", "proceed", "commit with that message"
3. **Clarification:** If user says "commit" after seeing info, ask: "Do you want me to proceed with this commit? (Please confirm with 'yes' or 'go ahead')"

**For Users:**
- After seeing commit info, use explicit confirmation: "yes", "go ahead", "proceed"

### Related Documentation
- Session Review: `docs/ai-standards/AI_STANDARDS_SESSION_REVIEW_2025-12-23.md`
- Standards Reference: `README-AI-CODING-STANDARDS.md` Section 2

---

## Violation #3: Trailing Whitespace in Committed Files

**Date:** 2025-12-23  
**Session:** Add setup workflow and improve branch protection validation script  
**Files:** `scripts/validate_branch_protection_enforcement.sh`, `scripts/test_token_scopes.sh`

### Violation Type
Code Quality - Trailing Whitespace

### Rule Violated
Section 1 - Code Quality, "No trailing spaces"
- "Do not leave trailing spaces on any line in any file"
- "Trailing whitespace should be removed"

### Description
Files committed with trailing whitespace on some lines. Detected via:
```bash
grep -n '[[:space:]]$' scripts/validate_branch_protection_enforcement.sh
grep -n '[[:space:]]$' scripts/test_token_scopes.sh
```

### Root Cause
**Missing pre-commit quality check:**
- Did not run trailing whitespace check before committing
- Code quality verification step was skipped
- Files were committed without quality verification

### Impact
**Severity:** Minor  
**Consequences:**
- Cosmetic issue, doesn't affect functionality
- Violates code quality standards
- Can cause issues with some text processing tools
- Creates unnecessary diff noise

### Corrective Action
1. Identified files with trailing whitespace
2. Documented need for pre-commit quality checks
3. Provided fix command: `sed -i '' 's/[[:space:]]*$//' <file>`

### Prevention
**For AI Assistants:**
1. **Pre-Commit Check:** Always run code quality checks before committing:
   ```bash
   # Check for trailing whitespace
   grep -n '[[:space:]]$' <file>
   
   # Fix if found
   sed -i '' 's/[[:space:]]*$//' <file>
   ```
2. **Automated Checks:** Use git hooks or pre-commit tools to catch these automatically
3. **Quality Verification:** Include code quality verification as part of commit preparation

**For Users:**
- Enable git hooks that check for trailing whitespace
- Use editor settings to highlight/remove trailing whitespace

### Related Documentation
- Session Review: `docs/ai-standards/AI_STANDARDS_SESSION_REVIEW_2025-12-23.md`
- Standards Reference: `README-AI-CODING-STANDARDS.md` Section 1, Section 4

---

## Summary Statistics

**Total Violations:** 3
- **Major:** 1 (Commit without showing info first)
- **Minor:** 2 (Confirmation acceptance, trailing whitespace)

**Most Common Violation Type:** Git Operations (2 violations)

**Prevention Focus Areas:**
1. User request interpretation for commit operations
2. Strict confirmation requirements
3. Pre-commit code quality checks
