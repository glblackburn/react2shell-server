# npm ENOTEMPTY Error Analysis and Fix

**Date:** 2025-12-21  
**Error:** `npm error code ENOTEMPTY` during Next.js version switching

---

## Error Explanation

### What Happened

```
npm error code ENOTEMPTY
npm error syscall rename
npm error path /Users/lblackb/data/lblackb/git/react2shell-server/frameworks/nextjs/node_modules/next
npm error dest /Users/lblackb/data/lblackb/git/react2shell-server/frameworks/nextjs/node_modules/.next-clYGb5d5
npm error errno -66
npm error ENOTEMPTY: directory not empty, rename '/Users/lblackb/data/lblackb/git/react2shell-server/frameworks/nextjs/node_modules/next' -> '/Users/lblackb/data/lblackb/git/react2shell-server/frameworks/nextjs/node_modules/.next-clYGb5d5'
```

### Root Cause

This error occurs when npm tries to rename the `node_modules/next` directory during installation, but the rename operation fails because:

1. **File Locks:** Files in the directory are locked by other processes (commonly `mdworker` on macOS for Spotlight indexing)
2. **Leftover Temp Files:** npm creates temporary directories (`.next-*`, `.react-*`, etc.) that may not be cleaned up properly
3. **Directory in Use:** The directory is still being accessed by another process
4. **Rapid Switching:** When switching versions quickly, npm may not have finished cleaning up from the previous operation

### Why It Happens

During `npm install`, npm:
1. Creates a temporary directory (e.g., `.next-clYGb5d5`)
2. Installs the new package into the temp directory
3. Renames the old directory to a backup
4. Renames the temp directory to the final name

If step 3 or 4 fails due to file locks or incomplete cleanup, you get `ENOTEMPTY`.

---

## Recommended Fix

### Solution: Add Cleanup and Retry Logic

1. **Clean npm temporary directories** before running `npm install`
2. **Add retry logic** for `ENOTEMPTY` errors with exponential backoff
3. **Add small delay** after cleanup to allow file locks to clear

### Implementation

Add a cleanup function and wrap npm install with retry logic:

```makefile
# Function to clean npm temporary directories
# Removes .next-*, .react-*, .scheduler-* temporary directories
define cleanup_npm_temp_files
	@cd frameworks/nextjs && \
	find node_modules -maxdepth 1 -type d \( \
		-name '.next-*' -o \
		-name '.react-*' -o \
		-name '.scheduler-*' \
	\) -exec rm -rf {} + 2>/dev/null || true
endef

# Function to run npm install with retry logic for ENOTEMPTY errors
define npm_install_with_retry
	@MAX_RETRIES=3; \
	RETRY_COUNT=0; \
	DELAY=2; \
	while [ $$RETRY_COUNT -lt $$MAX_RETRIES ]; do \
		if cd frameworks/nextjs && npm install --legacy-peer-deps; then \
			break; \
		else \
			EXIT_CODE=$$?; \
			if [ $$EXIT_CODE -eq 190 ] || [ $$EXIT_CODE -eq 1 ]; then \
				RETRY_COUNT=$$((RETRY_COUNT + 1)); \
				if [ $$RETRY_COUNT -lt $$MAX_RETRIES ]; then \
					echo "⚠️  npm install failed (ENOTEMPTY), retrying in $$DELAY seconds... (attempt $$RETRY_COUNT/$$MAX_RETRIES)"; \
					$(call cleanup_npm_temp_files); \
					sleep $$DELAY; \
					DELAY=$$((DELAY * 2)); \
				else \
					echo "❌ npm install failed after $$MAX_RETRIES attempts"; \
					exit 1; \
				fi; \
			else \
				exit $$EXIT_CODE; \
			fi; \
		fi; \
	done
endef
```

### Usage in switch_nextjs_version

Replace direct `npm install` calls with the retry function:

```makefile
14.0.0) \
	echo "Switching to Next.js $(1) (VULNERABLE - for security testing)..."; \
	echo "Note: Next.js 14.x requires React 18, using React 18.3.0 (compatible) for testing..."; \
	$(call cleanup_npm_temp_files); \
	cd frameworks/nextjs && node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.next='$(1)';pkg.dependencies.react='18.3.0';pkg.dependencies['react-dom']='18.3.0';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));" && \
	$(call npm_install_with_retry) && \
	echo "✓ Switched to Next.js $(1) (VULNERABLE)" ;;
```

---

## Alternative Simpler Fix

If the retry logic is too complex, a simpler approach:

1. **Clean temp files before each npm install**
2. **Add a small delay after cleanup**
3. **Use `npm ci` instead of `npm install`** (cleaner, but requires package-lock.json)

```makefile
# Simple cleanup before npm install
define cleanup_before_npm
	@cd frameworks/nextjs && \
	rm -rf node_modules/.next-* node_modules/.react-* node_modules/.scheduler-* 2>/dev/null || true; \
	sleep 1
endef
```

---

## Prevention Strategies

1. **Stop servers before switching versions** (already done in simple-run-check.sh)
2. **Clean temp files between switches**
3. **Add delays to allow file locks to clear**
4. **Use retry logic for transient errors**

---

## Testing

After implementing the fix, test with:

```bash
./simple-run-check.sh
```

The script should complete without ENOTEMPTY errors.

---

**Status:** Fix recommended, ready for implementation
