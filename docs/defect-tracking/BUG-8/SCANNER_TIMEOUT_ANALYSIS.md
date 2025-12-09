# Scanner Timeout Analysis for Next.js 14.x

## Summary

The scanner times out when sending RCE PoC payloads to Next.js 14.0.0 and 14.1.0 because Next.js 14.x **hangs during request processing** due to a bug in error handling. The server process remains running (can still serve GET requests to browsers), but **that specific POST request never completes** and never sends an HTTP response, causing the scanner to wait until timeout.

## Request Flow

### Scanner Request (from JSON output)
```
POST http://localhost:3000/
Headers:
  Next-Action: x
  X-Nextjs-Request-Id: b5dce965
  X-Nextjs-Html-Request-Id: SSTMXm7OJ_g0Ncx6jpQt9
  Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryx8jO2oVc6SWP3Sad
  Content-Length: 703

Body: Multipart form data with RCE PoC payload
  - Contains execSync('echo $((41*271))') command
  - Uses Next.js RSC protocol format
```

### What Happens in Next.js 14.x

1. **Request Received:** Next.js 14.x receives the POST request with `Next-Action: x` header
2. **Server Action Lookup:** Next.js tries to find a server action named "x"
   - Result: `Failed to find Server Action "x"` (expected - "x" is a placeholder)
3. **Origin Header Check:** Next.js 14.x requires `origin` header for Server Actions
   - Result: `Missing 'origin' header from a forwarded Server Actions request`
4. **Error Handling Bug:** Next.js 14.x error handling code tries to access `.message` property on a null error object
   - Code location: `app-page.runtime.dev.js:37:979`
   - Error: `TypeError: Cannot read properties of null (reading 'message')`
5. **Unhandled Rejection:** The null reference error causes an unhandled promise rejection
   - Multiple `unhandledRejection` errors in logs
   - **This specific request's processing hangs** - the request handler never completes
   - **Server process remains alive** - can still handle other requests (GET requests work fine)
6. **No HTTP Response for This Request:** Because the error handling crashes for this specific request, Next.js never sends an HTTP response for the POST request
   - No status code (200, 404, 500, etc.)
   - No response headers
   - No response body
   - **The request handler is stuck in an error state**
7. **Scanner Timeout:** Scanner waits 30 seconds for a response, then times out
   - Error: `HTTPConnectionPool(host='localhost', port=3000): Read timed out.`
   - **Server is still running** - browser can still load pages (GET requests work)

## Why Safe-Check Works

The `--safe-check` flag uses a different payload structure:
- Simpler payload that doesn't trigger the same error path
- Returns status 200 with `NOT VULNERABLE` result
- Doesn't cause the null reference error

## Why Next.js 15.x Works

Next.js 15.x has improved error handling:
- Better handling of missing server actions
- Doesn't crash on null error objects
- Properly sends HTTP responses even when errors occur
- Correctly detects vulnerability (returns status 303 with `X-Action-Redirect` header)

## Root Cause

**Next.js 14.x + React 19 Compatibility Bug:**
- Next.js 14.x was designed for React 18, not React 19
- Error handling code has a bug where it assumes error objects are never null
- When processing the RCE PoC payload with missing server action and missing origin header, the error object becomes null
- The code tries to read `.message` from null, causing a crash
- The unhandled rejection prevents the HTTP response from being sent
- Scanner times out waiting for a response that never comes

## Evidence

**Server Logs Show:**
```
Missing `origin` header from a forwarded Server Actions request.
Failed to find Server Action "x". This request might be from an older or newer deployment.
TypeError: Cannot read properties of null (reading 'message')
unhandledRejection: TypeError: Cannot read properties of null (reading 'message')
```

**Scanner Request (from JSON):**
- Request is properly formatted
- Headers are correct
- Payload is valid RCE PoC format
- Connection is established (not a connection timeout)
- Server never sends response (read timeout)

**Behavior:**
- `curl GET` works - server responds normally
- `--safe-check` works - different payload path
- RCE PoC times out - triggers error handling bug
- Next.js 15.x works - better error handling

## Conclusion

The timeout is caused by a **Next.js 14.x error handling bug** when processing RCE PoC payloads. The **specific POST request handler hangs** during request processing due to a null reference error in the error handling code, preventing any HTTP response from being sent for that request.

**Important:** The server process itself does not crash - it remains running and can handle other requests:
- ✅ GET requests work fine (browser can load pages)
- ✅ Other POST requests may work
- ❌ POST requests with RCE PoC payload hang indefinitely

This is a compatibility issue between Next.js 14.x and React 19, not a problem with our code blocking the scanner. The scanner is working correctly - it's waiting for a response that Next.js 14.x never sends because that specific request handler hangs in an error state.
