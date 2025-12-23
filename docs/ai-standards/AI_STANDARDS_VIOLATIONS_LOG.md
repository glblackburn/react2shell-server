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

## Violation #4: Committed File After User Question (Not Explicit Permission)

**Date:** 2025-12-23
**Session:** Navigation link implementation, validation, and script comparison
**Commit:** `34130cf` - "Add navigation coverage validation script"

### Violation Type
Git Operations - Mandatory Commit Workflow

### Rule Violated
Section 2 - Git Operations, Mandatory Commit Workflow (Two-Step Process)
- Step 1 requires showing commit message, files, and diff stats BEFORE committing
- Step 2 requires waiting for explicit user confirmation in a separate message

### Description
User asked: "what about this script scripts/verify_navigation_coverage.sh? why is it not commited?"

The AI assistant:
1. Committed the file directly without showing commit information first
2. Did not follow the mandatory two-step commit workflow
3. Did not show commit message, files, or changes before executing
4. Interpreted a question as implicit permission to commit

### Root Cause
**Misinterpretation of user question:**
- Interpreted "why is it not committed?" as implicit permission to commit
- Should have interpreted as "show me what would be committed" or "prepare commit"
- Did not recognize this as requiring the two-step process
- User was asking a question, not giving explicit commit permission
- Did not distinguish between question ("why isn't X committed?") and permission ("commit X")

### Impact
**Severity:** Major
**Consequences:**
- User did not have opportunity to review commit message or changes
- Violates mandatory workflow designed to prevent accidental commits
- Committed a file that was later determined to be an earlier, less polished version
- Could have been avoided if commit info was shown first

### Corrective Action
1. Documented this violation in session review
2. Identified that the script committed was actually the older version
3. Created comparison analysis to determine which script should be kept
4. Fixed trailing whitespace in created documentation files

### Prevention
**For AI Assistants:**
1. **Always show commit info first** - Even when user asks "why isn't X committed?", show what would be committed before executing
2. **Question vs. Permission:** Distinguish between user questions ("why isn't X committed?") and explicit permission ("commit X")
3. **When in doubt:** Show commit information first - it's better to show too much than commit without showing
4. **Strict interpretation:** Questions are questions, not permissions - always require explicit confirmation

**For Users:**
- Be explicit: "commit X" vs "why isn't X committed?"
- Questions about uncommitted files don't imply permission to commit

### Related Documentation
- Session Review: `docs/ai-standards/AI_STANDARDS_SESSION_REVIEW_2025-12-23-NAVIGATION.md`
- Standards Reference: `README-AI-CODING-STANDARDS.md` Section 2

---

## Violation #5: Created Documentation Files Without Explicit Request

**Date:** 2025-12-23
**Session:** Navigation link implementation, validation, and script comparison
**Files:** `docs/scripts/NAVIGATION_SCRIPT_COMPARISON.md`, `docs/scripts/SCRIPT_CREATION_HISTORY.md`

### Violation Type
File Creation

### Rule Violated
Section 3 - File Creation
- "Review X" means provide review in conversation, NOT create a review document file
- "Analyze Y" - Provide analysis in conversation, don't create a file
- Only create documentation files when explicitly requested
- "When in doubt: Ask: 'Should I create a review document file, or just provide the review here?'"

### Description
User requested: "diff the two and figure out which one matches the current code base do a detail dive on the difference and which is the right one."

The AI assistant:
1. Created `docs/scripts/NAVIGATION_SCRIPT_COMPARISON.md` with detailed comparison (239 lines)
2. Created `docs/scripts/SCRIPT_CREATION_HISTORY.md` to explain why two scripts were created
3. Did not ask if documentation files should be created
4. Provided analysis in files instead of primarily in conversation
5. Created files "just in case" or "for future reference" without being asked

### Root Cause
**Over-eagerness to document:**
- Interpreted "detail dive" as requiring a documentation file
- Should have provided analysis in conversation first
- Could have asked: "Should I create a comparison document, or just provide the analysis here?"
- Created files "just in case" or "for future reference" without being asked
- Did not follow the "when in doubt, ask" principle

### Impact
**Severity:** Minor
**Consequences:**
- Created files that may not have been needed
- Violates the principle that reviews/analysis should be conversational unless explicitly requested as files
- May create unnecessary documentation clutter
- Files are useful but should have been created only if explicitly requested

### Corrective Action
1. Documented this violation in session review
2. Files were created but are useful for future reference
3. Fixed trailing whitespace in created files
4. Should have asked first or provided analysis in conversation

### Prevention
**For AI Assistants:**
1. **When in doubt, ask:** "Should I create a comparison document, or just provide the analysis here?"
2. **Conversation first:** Provide detailed analysis in conversation, then offer to create a file if needed
3. **Explicit request required:** Only create documentation files when user explicitly says "create a document" or "write a file"
4. **Follow the rule:** "When in doubt: Ask: 'Should I create a review document file, or just provide the review here?'"

**For Users:**
- Be explicit: "create a comparison document" vs "analyze the differences"
- Specify if you want analysis in conversation or in a file

### Related Documentation
- Session Review: `docs/ai-standards/AI_STANDARDS_SESSION_REVIEW_2025-12-23-NAVIGATION.md`
- Standards Reference: `README-AI-CODING-STANDARDS.md` Section 3

---

## Violation #6: Trailing Whitespace in Created Files (Caught and Fixed)

**Date:** 2025-12-23
**Session:** Navigation link implementation, validation, and script comparison
**Files:** `docs/scripts/NAVIGATION_SCRIPT_COMPARISON.md`, `docs/scripts/SCRIPT_CREATION_HISTORY.md`

### Violation Type
Code Quality - Trailing Whitespace

### Rule Violated
Section 1 - Code Quality, "No trailing spaces"
- "Do not leave trailing spaces on any line in any file"
- "Trailing whitespace should be removed"

### Description
Files created with trailing whitespace on some lines. Detected during session review:
```bash
grep -n '[[:space:]]$' docs/scripts/NAVIGATION_SCRIPT_COMPARISON.md
grep -n '[[:space:]]$' docs/scripts/SCRIPT_CREATION_HISTORY.md
```

### Root Cause
**Missing pre-creation quality check:**
- Did not run trailing whitespace check after creating files
- Code quality verification step was skipped
- Files were created without quality verification

### Impact
**Severity:** Minor
**Consequences:**
- Cosmetic issue, doesn't affect functionality
- Violates code quality standards
- Can cause issues with some text processing tools
- Creates unnecessary diff noise

### Corrective Action
1. Detected during session review
2. Fixed immediately: `sed -i '' 's/[[:space:]]*$//' <files>`
3. Files now comply with code quality standards

### Prevention
**For AI Assistants:**
1. **Post-Creation Check:** Always run code quality checks after creating files:
   ```bash
   # Check for trailing whitespace
   grep -n '[[:space:]]$' <file>

   # Fix if found
   sed -i '' 's/[[:space:]]*$//' <file>
   ```
2. **Quality Verification:** Include code quality verification as part of file creation process
3. **Automated Checks:** Use git hooks or pre-commit tools to catch these automatically

### Related Documentation
- Session Review: `docs/ai-standards/AI_STANDARDS_SESSION_REVIEW_2025-12-23-NAVIGATION.md`
- Standards Reference: `README-AI-CODING-STANDARDS.md` Section 1, Section 4

---

## Summary Statistics

**Total Violations:** 6
- **Major:** 2 (Commit without showing info first - violations #1 and #4)
- **Minor:** 4 (Confirmation acceptance, trailing whitespace x2, file creation)

**Most Common Violation Type:** Git Operations (3 violations)

**Prevention Focus Areas:**
1. User request interpretation for commit operations (questions vs. permissions)
2. Strict confirmation requirements
3. Pre-commit/pre-creation code quality checks
4. File creation - ask before creating documentation files
