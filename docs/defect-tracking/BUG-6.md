# BUG-6: verify_scanner.sh Fails Due to Port Mismatch

**Status:** Fixed  
**Priority:** High  
**Severity:** High  
**Reported:** 2025-12-09  
**Fixed:** 2025-12-09

**Description:**
The `scripts/verify_scanner.sh` script fails to start and verify the server because it hardcodes the frontend URL to port 5173 (Vite framework), but does not detect which framework mode is currently active. When the system is in Next.js mode, the server runs on port 3000, not 5173. The script waits for port 5173 which never becomes available, causing a timeout after 30 seconds.

**Expected Behavior:**
- Script should detect the current framework mode (Vite or Next.js)
- Script should check the correct port based on framework:
  - Vite mode: `http://localhost:5173`
  - Next.js mode: `http://localhost:3000`
- Script should successfully start and verify the server regardless of framework mode

**Actual Behavior:**
- Script always checks `http://localhost:5173` regardless of framework mode
- When in Next.js mode, server starts on port 3000 but script checks port 5173
- Script times out after 30 seconds with error: "Error: Server not ready after 30 seconds"
- Script fails with: "Error: Could not start server"

**Error Output:**
```
========================================
Scanner Verification Test
========================================
Log file: /tmp/verify_scanner_2025-12-09_033328_gyllR6.txt

Server not running. Starting servers...
Waiting for server to be ready...
Error: Server not ready after 30 seconds
Error: Could not start server
```

**Steps to Reproduce:**
1. Ensure system is in Next.js mode:
   ```bash
   make use-nextjs
   ```
2. Stop any running servers:
   ```bash
   make stop
   ```
3. Run the verification script:
   ```bash
   ./scripts/verify_scanner.sh
   ```
4. Observe script fails with timeout error
5. Verify server is actually running on port 3000:
   ```bash
   make status
   # Shows: Backend (Express): ✓ Running on port 3000
   # Shows: Frontend (Vite): ✗ Not running
   ```

**Root Cause:**
1. **No Framework Detection:** The script does not read `.framework-mode` file to determine active framework
2. **Hardcoded Port:** Line 27 of `scripts/verify_scanner.sh` hardcodes:
   ```bash
   FRONTEND_URL="http://localhost:5173"
   ```
3. **No Port Detection:** Script doesn't check which port is actually in use
4. **Mismatch with Makefile:** The Makefile is framework-aware (checks `.framework-mode`), but the script is not

**Evidence:**
- When `make start` is run manually, output shows:
  ```
  Starting servers (Framework: nextjs)...
  Application: http://localhost:3000
  ```
- `make status` confirms server is running on port 3000
- Script log shows it's checking port 5173 which never responds

**Environment:**
- Script: `scripts/verify_scanner.sh`
- Framework Mode: Next.js (detected via `.framework-mode` file)
- Expected Port: 3000 (Next.js)
- Script Checks: 5173 (Vite)
- Makefile: Framework-aware (correctly starts Next.js on port 3000)
- Test Date: 2025-12-09

**Files Affected:**
- `scripts/verify_scanner.sh` - Line 27: Hardcoded `FRONTEND_URL="http://localhost:5173"`
- `scripts/verify_scanner.sh` - Missing framework detection logic
- `.framework-mode` - File exists but script doesn't read it

**Impact:**
- **Functionality:** Script cannot verify scanner when system is in Next.js mode
- **Testing:** Cannot run automated scanner verification tests in Next.js framework mode
- **User Experience:** Confusing error messages that don't indicate the root cause
- **Maintenance:** Script needs manual modification to work with different frameworks

**Related Issues:**
- Makefile correctly handles framework switching and port selection
- Other test scripts may have similar issues if they hardcode ports

**Proposed Solution:**
1. **Add Framework Detection:**
   ```bash
   # Detect framework mode
   FRAMEWORK_MODE=$(cat "${PROJECT_ROOT}/.framework-mode" 2>/dev/null || echo "vite")
   
   # Set FRONTEND_URL based on framework
   if [ "${FRAMEWORK_MODE}" == "nextjs" ]; then
       FRONTEND_URL="http://localhost:3000"
   else
       FRONTEND_URL="http://localhost:5173"
   fi
   ```

2. **Alternative: Port Detection:**
   - Check which port is actually in use (3000 or 5173)
   - Use whichever port responds first
   - Or check both ports and use the active one

3. **Add Verbose Output:**
   - Display detected framework mode
   - Display which port is being checked
   - Provide clearer error messages when port mismatch occurs

**Solution Implemented:**
1. ✅ Added framework detection by reading `.framework-mode` file
2. ✅ Set `FRONTEND_URL` dynamically based on detected framework:
   - Next.js mode: `http://localhost:3000`
   - Vite mode: `http://localhost:5173` (default)
3. ✅ Added framework mode display (unless quiet mode)
4. ✅ Enhanced error messages to show which port/URL was being checked
5. ✅ Added troubleshooting hints in error messages
6. ✅ Included framework mode in verbose configuration output

**Files Modified:**
- `scripts/verify_scanner.sh` - Added framework detection and dynamic port selection

**Verification:**
✅ Fix verified - Script now correctly detects framework mode and uses the appropriate port:
- In Vite mode: checks port 5173
- In Next.js mode: checks port 3000
- Displays detected framework and port (unless quiet)
- Provides clear error messages with port information

**Additional Notes:**
- Framework detection reads `.framework-mode` file (same mechanism as Makefile)
- Defaults to Vite mode if `.framework-mode` file doesn't exist
- Error messages now include helpful troubleshooting hints
- Script works correctly in both framework modes without manual modification
