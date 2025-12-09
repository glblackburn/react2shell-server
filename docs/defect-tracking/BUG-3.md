# BUG-3: Next.js Version Not Displayed in UI

**Status:** Fixed  
**Priority:** Medium  
**Severity:** Medium  
**Reported:** 2025-12-08  
**Fixed:** 2025-12-08

**Description:**
When running in Next.js mode, the version information display does not show the Next.js version, even though the API endpoint (`/api/version`) returns it in the response. The React version is displayed with vulnerability status indicators (⚠️ VULNERABLE or ✅ FIXED), but the Next.js version is missing from the UI.

**Expected Behavior:**
- Next.js version should be displayed in the version information card
- Next.js version should follow the same format as React version display
- Next.js version should show vulnerability status indicator if applicable (⚠️ VULNERABLE or ✅ FIXED)
- Format should be: "Next.js: 14.0.0 ⚠️ VULNERABLE" or "Next.js: 15.1.0 ✅ FIXED"

**Actual Behavior:**
- Next.js version is not displayed in the UI
- Only React, React-DOM, and Node.js versions are shown
- API returns `nextjs` field in JSON response, but frontend doesn't render it

**Screenshots:**
![Bug-3: Next.js version missing from UI](images/bug-3.png)
*Shows version information display without Next.js version*

**Steps to Reproduce:**
1. Switch to Next.js mode:
   ```bash
   make use-nextjs
   ```
2. Start the Next.js server:
   ```bash
   make start
   ```
3. Open browser to `http://localhost:3000`
4. Observe the version information card
5. Notice that Next.js version is not displayed

**Root Cause:**
The Next.js page component (`frameworks/nextjs/app/page.tsx`) did not include a version item for Next.js, even though the API response includes `nextjs` field.

**Environment:**
- Framework: Next.js mode
- Next.js Version: Any version (14.0.0, 15.0.0, 15.1.0, etc.)
- Browser: Any browser
- OS: Any OS

**Files Affected:**
- `frameworks/nextjs/app/page.tsx` - Missing Next.js version display in version-details section
- `frameworks/nextjs/app/api/version/route.ts` - API correctly returns nextjs field (no changes needed)

**Solution Implemented:**
1. ✅ Added Next.js version display to `frameworks/nextjs/app/page.tsx`
2. ✅ Created `isNextjsVulnerable()` helper function to determine vulnerability status
3. ✅ Added conditional rendering for Next.js version item (lines 71-79)
4. ✅ Applied same styling and format as React version display
5. ✅ Next.js version displays with vulnerability status indicators (⚠️ VULNERABLE or ✅ FIXED)
6. ✅ Version appears first in the version details list when present

**Files Modified:**
- `frameworks/nextjs/app/page.tsx` - Added Next.js version display with vulnerability status

**Verification:**
✅ Fix verified - Next.js version now displays correctly in the UI:
- Shows "Next.js: 14.0.0 ⚠️ VULNERABLE" for vulnerable versions
- Shows "Next.js: 15.1.0 ✅ FIXED" for fixed versions
- Matches React version display format
- Appears at the top of version details when in Next.js mode

**Additional Notes:**
- Next.js version is conditionally displayed only when `versionInfo.nextjs` is present
- Vulnerability status is determined by `isNextjsVulnerable()` function
- Format matches React version display for consistency
