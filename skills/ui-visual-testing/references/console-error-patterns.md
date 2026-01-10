# Console Error Patterns Reference

<objective>
Comprehensive catalog of 50+ console error patterns with regex matching, severity classification, root cause analysis, and fix recommendations. Use for automated error classification and debugging guidance.
</objective>

<usage>
When analyzing console output:
1. Match error text against patterns using regex
2. Identify severity level
3. Follow debugging steps
4. Apply recommended fixes
</usage>

---

## CORS Errors (6 patterns)

### Pattern 1: Access-Control-Allow-Origin Blocked
**Regex**: `Access to (XMLHttpRequest|fetch).*blocked by CORS policy.*No 'Access-Control-Allow-Origin'`
**Severity**: CRITICAL
**Root Cause**: Backend not sending CORS headers; browser blocks cross-origin request
**Debugging**:
1. Check Network tab for the blocked request
2. Verify backend URL is correct
3. Check if server is running
4. Inspect response headers (should have Access-Control-Allow-Origin)
**Fixes**:
- Backend: Add CORS middleware (Flask-CORS, cors npm, etc.)
- Development: Use proxy in webpack/vite config
- Specific origin: Set Access-Control-Allow-Origin to exact frontend URL

### Pattern 2: Preflight Request Failed
**Regex**: `Response to preflight request doesn't pass access control check`
**Severity**: CRITICAL
**Root Cause**: OPTIONS request failing; server not handling preflight
**Debugging**:
1. Check for OPTIONS request in Network tab
2. Verify it returns 200/204
3. Check Access-Control-Allow-Methods header
**Fixes**:
- Server must respond to OPTIONS with 200/204
- Include Access-Control-Allow-Methods header
- Include Access-Control-Allow-Headers for custom headers

### Pattern 3: Credentials Not Supported
**Regex**: `The value of the 'Access-Control-Allow-Origin' header.*must not be the wildcard '\*'.*credentials mode is 'include'`
**Severity**: CRITICAL
**Root Cause**: Using credentials with wildcard origin
**Debugging**:
1. Check if fetch/XHR uses credentials: 'include'
2. Verify backend CORS configuration
**Fixes**:
- Backend: Set specific origin instead of '*'
- Backend: Set Access-Control-Allow-Credentials: true

### Pattern 4: Header Not Allowed
**Regex**: `Request header field (.*) is not allowed by Access-Control-Allow-Headers`
**Severity**: ERROR
**Root Cause**: Custom header not in allowed list
**Debugging**:
1. Identify the blocked header from error
2. Check Access-Control-Allow-Headers response
**Fixes**:
- Add header to Access-Control-Allow-Headers list
- Common headers to allow: Content-Type, Authorization, X-Requested-With

### Pattern 5: Method Not Allowed
**Regex**: `Method (PUT|DELETE|PATCH) is not allowed by Access-Control-Allow-Methods`
**Severity**: ERROR
**Root Cause**: HTTP method not in allowed list
**Debugging**:
1. Check request method
2. Check Access-Control-Allow-Methods header
**Fixes**:
- Add method to Access-Control-Allow-Methods

### Pattern 6: Origin Mismatch
**Regex**: `The 'Access-Control-Allow-Origin' header has a value '(.*)' that is not equal to the supplied origin`
**Severity**: CRITICAL
**Root Cause**: Response origin doesn't match request origin
**Debugging**:
1. Compare origins in error message
2. Check for protocol mismatch (http vs https)
3. Check for port mismatch
**Fixes**:
- Set correct origin in backend
- Use dynamic origin based on request

---

## Network Errors (8 patterns)

### Pattern 7: 404 Not Found
**Regex**: `(GET|POST|PUT|DELETE|PATCH).*404|Failed to load resource.*404`
**Severity**: ERROR (API) | WARNING (asset)
**Root Cause**: Endpoint/resource doesn't exist
**Debugging**:
1. Verify URL is correct
2. Check if route exists on server
3. Check for typos in path
4. Verify server is handling the route
**Fixes**:
- Correct the URL
- Add missing route on server
- Check dynamic route parameters

### Pattern 8: 500 Internal Server Error
**Regex**: `(GET|POST|PUT|DELETE|PATCH).*500|Failed to load resource.*500`
**Severity**: CRITICAL
**Root Cause**: Server-side error
**Debugging**:
1. Check server logs for stack trace
2. Check request payload for invalid data
3. Verify database connection
**Fixes**:
- Fix server-side bug
- Add better error handling on server
- Validate input before processing

### Pattern 9: 401 Unauthorized
**Regex**: `(GET|POST|PUT|DELETE|PATCH).*401|Failed to load resource.*401`
**Severity**: ERROR
**Root Cause**: Missing or invalid authentication
**Debugging**:
1. Check if auth token is being sent
2. Verify token is valid and not expired
3. Check Authorization header format
**Fixes**:
- Include auth token in request
- Refresh expired token
- Fix header format (Bearer token)

### Pattern 10: 403 Forbidden
**Regex**: `(GET|POST|PUT|DELETE|PATCH).*403|Failed to load resource.*403`
**Severity**: ERROR
**Root Cause**: Authenticated but not authorized
**Debugging**:
1. Check user permissions
2. Verify resource access rules
3. Check CSRF token if applicable
**Fixes**:
- Grant appropriate permissions
- Check role/permission logic
- Include CSRF token

### Pattern 11: Connection Refused
**Regex**: `net::ERR_CONNECTION_REFUSED|Failed to fetch.*ECONNREFUSED`
**Severity**: CRITICAL
**Root Cause**: Server not running or wrong port
**Debugging**:
1. Verify server is running
2. Check port number
3. Check firewall rules
**Fixes**:
- Start the server
- Correct the port
- Configure firewall

### Pattern 12: DNS Resolution Failed
**Regex**: `net::ERR_NAME_NOT_RESOLVED`
**Severity**: CRITICAL
**Root Cause**: Domain doesn't exist or DNS issue
**Debugging**:
1. Check URL spelling
2. Try ping/nslookup on domain
3. Check /etc/hosts for local overrides
**Fixes**:
- Correct domain name
- Wait for DNS propagation
- Use IP address temporarily

### Pattern 13: Timeout
**Regex**: `net::ERR_TIMED_OUT|TimeoutError|Request timed out`
**Severity**: ERROR
**Root Cause**: Server too slow or network issues
**Debugging**:
1. Check server response time
2. Test network connectivity
3. Check for slow queries/operations
**Fixes**:
- Optimize server response
- Increase timeout setting
- Add loading state for slow operations

### Pattern 14: SSL Certificate Error
**Regex**: `net::ERR_CERT_(AUTHORITY_INVALID|DATE_INVALID|COMMON_NAME_INVALID)`
**Severity**: CRITICAL
**Root Cause**: Invalid or expired SSL certificate
**Debugging**:
1. Check certificate expiration
2. Verify certificate chain
3. Check domain name matches certificate
**Fixes**:
- Renew certificate
- Fix certificate chain
- Use correct domain

---

## JavaScript Errors (12 patterns)

### Pattern 15: TypeError - Cannot Read Property of Undefined
**Regex**: `TypeError: Cannot read propert(y|ies).*of (undefined|null)`
**Severity**: CRITICAL
**Root Cause**: Accessing property on non-existent object
**Debugging**:
1. Identify the undefined variable from stack trace
2. Trace back to where it should be defined
3. Check for async timing issues
**Fixes**:
- Optional chaining: obj?.property
- Null check: if (obj && obj.property)
- Default value: obj?.property ?? defaultValue

### Pattern 16: TypeError - X is Not a Function
**Regex**: `TypeError: (.*) is not a function`
**Severity**: CRITICAL
**Root Cause**: Calling non-callable value
**Debugging**:
1. Check what type the variable actually is
2. Verify import/export is correct
3. Check for shadowed variable names
**Fixes**:
- Verify import statement
- Check for typos in function name
- Ensure module exports correctly

### Pattern 17: ReferenceError - X is Not Defined
**Regex**: `ReferenceError: (.*) is not defined`
**Severity**: CRITICAL
**Root Cause**: Using undefined variable
**Debugging**:
1. Check variable spelling
2. Verify import statement
3. Check variable scope
**Fixes**:
- Import the missing dependency
- Declare the variable
- Fix scope issues

### Pattern 18: SyntaxError
**Regex**: `SyntaxError: (Unexpected token|Invalid or unexpected token|Unexpected end of input)`
**Severity**: CRITICAL
**Root Cause**: Invalid JavaScript syntax
**Debugging**:
1. Check line number in error
2. Look for missing brackets/quotes
3. Check for invalid JSON in data
**Fixes**:
- Fix syntax error at indicated line
- Validate JSON data
- Check for encoding issues

### Pattern 19: RangeError - Maximum Call Stack
**Regex**: `RangeError: Maximum call stack size exceeded`
**Severity**: CRITICAL
**Root Cause**: Infinite recursion
**Debugging**:
1. Check for recursive function calls
2. Look for circular dependencies
3. Check useEffect/componentDidUpdate loops
**Fixes**:
- Add base case to recursion
- Break circular dependency
- Add proper deps to useEffect

### Pattern 20: RangeError - Invalid Array Length
**Regex**: `RangeError: Invalid array length`
**Severity**: ERROR
**Root Cause**: Creating array with invalid size
**Debugging**:
1. Check array initialization
2. Verify length calculation
**Fixes**:
- Validate array length before creation
- Use Math.max(0, length)

### Pattern 21: TypeError - Assignment to Constant
**Regex**: `TypeError: Assignment to constant variable`
**Severity**: ERROR
**Root Cause**: Trying to reassign const
**Debugging**:
1. Find the const declaration
2. Determine if mutation or reassignment
**Fixes**:
- Use let instead of const
- Use mutation methods for objects/arrays

### Pattern 22: TypeError - Cannot Set Property
**Regex**: `TypeError: Cannot set propert(y|ies).*of (undefined|null)`
**Severity**: CRITICAL
**Root Cause**: Setting property on null/undefined
**Debugging**:
1. Identify target object
2. Trace why it's null/undefined
**Fixes**:
- Initialize object before assignment
- Add null check

### Pattern 23: Unhandled Promise Rejection
**Regex**: `Unhandled promise rejection|UnhandledPromiseRejectionWarning`
**Severity**: ERROR
**Root Cause**: Promise rejected without catch handler
**Debugging**:
1. Find the async operation
2. Check what error is thrown
**Fixes**:
- Add .catch() handler
- Use try/catch with async/await
- Add global unhandledrejection handler

### Pattern 24: JSON Parse Error
**Regex**: `SyntaxError: (Unexpected token|JSON\.parse).*position \d+`
**Severity**: ERROR
**Root Cause**: Invalid JSON string
**Debugging**:
1. Log the string being parsed
2. Validate JSON syntax
3. Check for HTML error page in response
**Fixes**:
- Validate JSON before parsing
- Handle non-JSON responses
- Check API response content-type

### Pattern 25: TypeError - Illegal Invocation
**Regex**: `TypeError: Illegal invocation`
**Severity**: ERROR
**Root Cause**: DOM method called with wrong context
**Debugging**:
1. Check how method is being called
2. Verify 'this' context
**Fixes**:
- Use .bind(element) or arrow function
- Call method on correct object

### Pattern 26: DOMException - Blocked by Permissions Policy
**Regex**: `DOMException.*blocked by.*policy`
**Severity**: WARNING
**Root Cause**: Browser permission not granted
**Debugging**:
1. Check which API is blocked
2. Verify permissions policy headers
**Fixes**:
- Request permission from user
- Update Permissions-Policy header

---

## React-Specific Errors (10 patterns)

### Pattern 27: Key Prop Warning
**Regex**: `Warning: Each child in a list should have a unique "key" prop`
**Severity**: WARNING
**Root Cause**: Missing or non-unique keys in list
**Debugging**:
1. Find the list rendering component
2. Check key prop assignment
**Fixes**:
- Add unique key prop to list items
- Use stable ID instead of index

### Pattern 28: Hydration Mismatch
**Regex**: `(Hydration failed|Text content does not match|Expected server HTML to contain)`
**Severity**: CRITICAL
**Root Cause**: Server HTML differs from client render
**Debugging**:
1. Check for browser-only code in initial render
2. Look for date/time formatting differences
3. Check for randomized content
**Fixes**:
- Use useEffect for browser-only code
- Ensure deterministic initial render
- Use suppressHydrationWarning for expected differences

### Pattern 29: Invalid Hook Call
**Regex**: `Invalid hook call.*Hooks can only be called inside.*function component`
**Severity**: CRITICAL
**Root Cause**: Hook called outside component or in class
**Debugging**:
1. Verify hook is at top level of function component
2. Check for duplicate React versions
3. Ensure not calling hooks conditionally
**Fixes**:
- Move hook to top level
- Check node_modules for duplicate React
- Remove conditional hook calls

### Pattern 30: Can't Perform State Update on Unmounted Component
**Regex**: `Can't perform a React state update on an unmounted component`
**Severity**: WARNING
**Root Cause**: Async operation completing after unmount
**Debugging**:
1. Find the async operation
2. Check cleanup in useEffect
**Fixes**:
- Add cleanup function in useEffect
- Use AbortController for fetch
- Check mounted flag before setState

### Pattern 31: Too Many Re-renders
**Regex**: `Too many re-renders\. React limits the number of renders`
**Severity**: CRITICAL
**Root Cause**: Infinite render loop
**Debugging**:
1. Check for setState in render body
2. Look for incorrect useEffect deps
3. Check event handler calls
**Fixes**:
- Move setState to event handler
- Fix useEffect dependency array
- Use callback form: onClick={() => fn()} not onClick={fn()}

### Pattern 32: Objects Not Valid as React Child
**Regex**: `Objects are not valid as a React child`
**Severity**: ERROR
**Root Cause**: Rendering object instead of primitive/element
**Debugging**:
1. Find what's being rendered
2. Check the data type
**Fixes**:
- Convert object to string: JSON.stringify()
- Access specific property: obj.name
- Map object to elements

### Pattern 33: Component Definition Missing Display Name
**Regex**: `Component definition is missing display name`
**Severity**: WARNING
**Root Cause**: Anonymous component (affects DevTools)
**Debugging**:
1. Find anonymous component
**Fixes**:
- Add displayName property
- Use named function instead of arrow

### Pattern 34: React DevTools Warning - Detected Legacy Context
**Regex**: `Warning.*Legacy context API`
**Severity**: WARNING
**Root Cause**: Using deprecated context API
**Debugging**:
1. Find contextTypes usage
**Fixes**:
- Migrate to React.createContext

### Pattern 35: Cannot Update During Render
**Regex**: `Cannot update a component.*while rendering a different component`
**Severity**: CRITICAL
**Root Cause**: Calling setState from another component's render
**Debugging**:
1. Check component tree render order
2. Find setState trigger
**Fixes**:
- Move setState to useEffect
- Use callback or event handler

### Pattern 36: StrictMode Double Invoke Warning
**Regex**: `Function components cannot be given refs|Expected ref to be a function`
**Severity**: WARNING
**Root Cause**: Ref passed to function component without forwardRef
**Debugging**:
1. Find ref usage on function component
**Fixes**:
- Wrap component with React.forwardRef
- Use different prop name for callback

---

## Security Warnings (8 patterns)

### Pattern 37: Mixed Content
**Regex**: `Mixed Content.*loaded over HTTPS.*requested an insecure (image|script|stylesheet|resource)`
**Severity**: WARNING
**Root Cause**: HTTP resource on HTTPS page
**Debugging**:
1. Find the HTTP resource URL
2. Check if HTTPS version available
**Fixes**:
- Use HTTPS URLs
- Use protocol-relative URLs: //example.com
- Configure Content-Security-Policy upgrade-insecure-requests

### Pattern 38: CSP Violation
**Regex**: `Refused to (load|execute|connect to).*violates.*Content Security Policy`
**Severity**: WARNING
**Root Cause**: Resource blocked by CSP header
**Debugging**:
1. Check CSP header/meta tag
2. Identify blocked resource type
**Fixes**:
- Add domain to appropriate CSP directive
- Use nonce for inline scripts
- Review CSP policy

### Pattern 39: Cookie SameSite Warning
**Regex**: `cookie.*SameSite attribute.*None|cross-site request`
**Severity**: WARNING
**Root Cause**: Third-party cookie without SameSite=None
**Debugging**:
1. Check cookie settings
2. Verify Secure flag is set
**Fixes**:
- Add SameSite=None; Secure to cookie
- Use first-party cookie instead

### Pattern 40: Insecure Password Field
**Regex**: `Password field is not contained in a secure form`
**Severity**: WARNING
**Root Cause**: Password input on non-HTTPS page
**Debugging**:
1. Check page protocol
**Fixes**:
- Use HTTPS
- Add SSL certificate

### Pattern 41: X-Frame-Options Violation
**Regex**: `Refused to display.*in a frame.*X-Frame-Options`
**Severity**: WARNING
**Root Cause**: Page doesn't allow iframe embedding
**Debugging**:
1. Check X-Frame-Options header
**Fixes**:
- Adjust X-Frame-Options header
- Use frame-ancestors in CSP

### Pattern 42: HSTS Warning
**Regex**: `strict-transport-security|HSTS`
**Severity**: INFO
**Root Cause**: HSTS configuration issue
**Debugging**:
1. Check HSTS header
**Fixes**:
- Configure proper HSTS header

### Pattern 43: Deprecated API Security Warning
**Regex**: `(document\.domain|synchronous XMLHttpRequest).*deprecated.*security`
**Severity**: WARNING
**Root Cause**: Using deprecated insecure APIs
**Debugging**:
1. Find deprecated API usage
**Fixes**:
- Use modern alternatives
- Remove deprecated code

### Pattern 44: Subresource Integrity Error
**Regex**: `integrity attribute.*hash.*did not match`
**Severity**: ERROR
**Root Cause**: File content changed or wrong hash
**Debugging**:
1. Regenerate hash
2. Check if file was modified
**Fixes**:
- Update integrity hash
- Verify file source

---

## Performance Violations (6 patterns)

### Pattern 45: Long Task Warning
**Regex**: `\[Violation\].*took \d+ms`
**Severity**: WARNING
**Root Cause**: JavaScript blocking main thread too long
**Debugging**:
1. Profile with DevTools Performance tab
2. Find long-running code
**Fixes**:
- Break up long tasks
- Use Web Workers for heavy computation
- Defer non-critical work

### Pattern 46: Forced Reflow
**Regex**: `\[Violation\].*Forced reflow`
**Severity**: WARNING
**Root Cause**: Reading layout properties after writes
**Debugging**:
1. Find layout read after write
2. Check for offsetHeight/Width reads
**Fixes**:
- Batch reads and writes separately
- Use requestAnimationFrame

### Pattern 47: Event Handler Took Too Long
**Regex**: `\[Violation\].*handler took \d+ms`
**Severity**: WARNING
**Root Cause**: Slow event handler blocking UI
**Debugging**:
1. Profile event handler
2. Find slow operations
**Fixes**:
- Debounce/throttle handler
- Use requestIdleCallback
- Offload to worker

### Pattern 48: Large Layout Shift
**Regex**: `Layout shift.*CLS|Cumulative Layout Shift`
**Severity**: WARNING
**Root Cause**: Elements moving during page load
**Debugging**:
1. Use Layout Shift regions in DevTools
2. Find shifting elements
**Fixes**:
- Set explicit dimensions on images/videos
- Reserve space for dynamic content
- Use CSS containment

### Pattern 49: Large Contentful Paint
**Regex**: `LCP|Largest Contentful Paint.*slow`
**Severity**: WARNING
**Root Cause**: Main content loading slowly
**Debugging**:
1. Identify LCP element
2. Check resource loading time
**Fixes**:
- Preload critical resources
- Optimize images
- Remove render-blocking resources

### Pattern 50: First Input Delay
**Regex**: `FID|First Input Delay.*exceeded`
**Severity**: WARNING
**Root Cause**: Main thread busy when user interacts
**Debugging**:
1. Check for heavy JS execution at load
2. Profile initial page load
**Fixes**:
- Code split and lazy load
- Defer non-critical JS
- Reduce third-party impact

---

## Misc Patterns (4 patterns)

### Pattern 51: Source Map Warning
**Regex**: `DevTools failed to load.*source map`
**Severity**: INFO
**Root Cause**: Source map file not found
**Debugging**:
1. Check source map URL in bundle
2. Verify file exists
**Fixes**:
- Fix source map path
- Disable source maps in production
- Generate source maps correctly

### Pattern 52: WebSocket Connection Failed
**Regex**: `WebSocket connection to.*failed`
**Severity**: ERROR
**Root Cause**: WebSocket server unavailable
**Debugging**:
1. Check WebSocket server status
2. Verify URL and port
3. Check firewall/proxy settings
**Fixes**:
- Start WebSocket server
- Fix connection URL
- Configure proxy for WSS

### Pattern 53: Service Worker Registration Failed
**Regex**: `Service worker registration failed|ServiceWorker.*error`
**Severity**: WARNING
**Root Cause**: Service worker script error or HTTPS required
**Debugging**:
1. Check service worker script for errors
2. Verify HTTPS (required for SW)
**Fixes**:
- Fix service worker script
- Use HTTPS
- Check scope configuration

### Pattern 54: ResizeObserver Loop Error
**Regex**: `ResizeObserver loop (limit exceeded|completed with undelivered notifications)`
**Severity**: WARNING (usually safe to ignore)
**Root Cause**: Element size change triggers infinite loop
**Debugging**:
1. Usually caused by layout changes in resize callback
2. Check for element size modifications
**Fixes**:
- Use requestAnimationFrame in callback
- Add debounce to resize handler
- Often safe to suppress

---

## Severity Legend

| Level | Action | Example |
|-------|--------|---------|
| CRITICAL | Stop testing, investigate immediately | JS crash, API failure |
| ERROR | Fail test, document issue | 404 API, console error |
| WARNING | Log for review, continue testing | Deprecation, performance |
| INFO | Informational only | Debug logs, source maps |

## Usage in Test Code

```typescript
function classifyError(text: string): { pattern: string; severity: string; category: string } | null {
  const patterns = [
    { regex: /Access to.*blocked by CORS/, pattern: 'CORS Blocked', severity: 'CRITICAL', category: 'cors' },
    { regex: /TypeError: Cannot read propert/, pattern: 'Undefined Property', severity: 'CRITICAL', category: 'javascript' },
    { regex: /(GET|POST).*404/, pattern: '404 Not Found', severity: 'ERROR', category: 'network' },
    // ... add all patterns
  ];

  for (const p of patterns) {
    if (p.regex.test(text)) {
      return { pattern: p.pattern, severity: p.severity, category: p.category };
    }
  }
  return null;
}
```
