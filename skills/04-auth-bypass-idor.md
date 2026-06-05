# Authentication Bypass & IDOR Methodology

Primary methodology for finding mid-tier bounties ($500-$5000). Auth bypass and IDOR are the most common high-severity findings in bug bounty programs.

## Phase 1: Map the Auth Architecture

### Step 1: Identify the Auth Framework
```
grep -rn "passport|jwt|oauth|session|auth|middleware" --include="*.py" --include="*.js" --include="*.java" --include="*.go" --include="*.rb" --include="*.yaml" --include="*.json"
```

Classify:
- Session-based — server-side sessions with cookies
- JWT-based — stateless tokens (check signing algorithm!)
- OAuth/OIDC — delegated auth (check state parameter, redirect validation)
- API key — static keys (check scope, rotation, per-endpoint enforcement)
- Custom — roll-your-own (highest bug probability)

### Step 2: Map Auth Middleware
Find the auth middleware/decorator and understand enforcement:
```
# Python/Flask
grep -rn "@login_required|@auth_required|@requires_auth|before_request"

# Python/Django
grep -rn "LoginRequiredMixin|PermissionRequiredMixin|@permission_required|IsAuthenticated"

# Express/Node
grep -rn "isAuthenticated|requireAuth|authMiddleware|passport.authenticate"

# Spring/Java
grep -rn "@PreAuthorize|@Secured|@RolesAllowed|SecurityConfig|WebSecurityConfigurerAdapter"

# Go
grep -rn "AuthMiddleware|RequireAuth|JWTMiddleware|CheckPermission"
```

### Step 3: Map Role Hierarchy
```
grep -rn "role|permission|is_admin|is_staff|ROLE_|hasRole|checkRole|canAccess"
```
Document: What roles exist? What can each do? Where are role checks performed?

## Phase 2: Hunt for Auth Bypass

### Test 1: Unauthenticated Access to Protected Routes
1. List ALL route definitions
2. For each route, check if auth middleware is applied
3. Flag any route handling sensitive data/actions without auth

Common patterns that leak:
- Webhook endpoints — often unauthenticated, expose internal data
- Health check endpoints (/health, /status, /metrics)
- API documentation endpoints (/swagger, /api-docs, /graphql playground)
- File upload/download endpoints missing auth
- Password reset flows with logic bypass
- Registration endpoints that allow admin role assignment

### Test 2: JWT Vulnerabilities
1. Algorithm confusion — Can alg be changed to "none" or HS256 when RS256 expected?
   Red flag: algorithms=["HS256", "RS256"] or missing algorithm restriction
2. Secret strength — Is HMAC secret weak/guessable?
3. Missing expiration — Tokens without exp claim
4. Missing signature verification — verify=False or equivalent
5. Key confusion — Using public key as HMAC secret

### Test 3: Session Management Bypass
1. Session fixation — Can attacker set session ID before auth?
2. Session doesn't invalidate on logout/password change
3. Predictable session IDs — sequential, timestamp-based
4. Cookie flags — missing Secure, HttpOnly, SameSite

### Test 4: OAuth/SSO Bypass
1. Missing state parameter (CSRF -> account takeover)
2. Open redirect in callback URL — token theft
3. Email verification bypass — OAuth returns unverified email
4. Account linking flaws — link attacker's OAuth to victim's account

### Test 5: Password Reset Bypass
1. Predictable reset tokens — UUID v1 (timestamp), sequential, short tokens
2. Token not invalidated after use — replay
3. No expiration on reset tokens
4. Host header injection — reset link to attacker domain
5. Race condition — multiple reset requests

## Phase 3: Hunt for IDOR

### Step 1: Find All Object References
```
# URL parameters
grep -rn "params\.|req\.params\.|request\.args\.|@PathVariable|path('<int:'|path('<str:'"

# Query parameters
grep -rn "query\.|request\.GET|getParameter|@RequestParam"

# Request body
grep -rn "body\.|request\.data|request\.json|@RequestBody"
```

### Step 2: Trace Authorization
For EACH object reference, trace:
```
User Input (ID) → Controller → Service → Database Query
```
At EACH layer: Is the authenticated user's ID compared to the object's owner? Is there a WHERE clause filtering by current user?

### Step 3: Classify the IDOR
- Horizontal IDOR — Access another user's resources at same privilege level (Medium-High)
- Vertical IDOR — Access resources at higher privilege level (High-Critical)
- Object-level — Access specific objects (most common)
- Function-level — Access functions restricted to other roles

### Step 4: Check ID Predictability
- Sequential integers — trivially enumerable
- UUIDs — harder but sometimes leaked in responses/URLs/logs
- Encoded IDs — base64/hex, decode and check if predictable
- Composite keys — sometimes only resource_id checked, not user_id

### Common IDOR Locations (High Hit Rate)
1. User profile endpoints — GET/PUT /api/users/{id}
2. File download/view — GET /api/files/{id}
3. Order/transaction details — GET /api/orders/{id}
4. Message/notification read — GET /api/messages/{id}
5. Invoice/billing — GET /api/invoices/{id}
6. API key management — GET/DELETE /api/keys/{id}
7. Settings/preferences — PUT /api/users/{id}/settings
8. Export/report generation — GET /api/reports/{id}
9. Admin panel actions — any /admin/ or /api/admin/ endpoint
10. GraphQL queries — node(id: "...") without auth checks

### IDOR in GraphQL
GraphQL is an IDOR goldmine:
- Can you query any node by global ID?
- Are nested relationships filtered by user?
- Are mutations checking ownership?

## Phase 4: Privilege Escalation

### Vertical Escalation Patterns
1. Role parameter in registration/profile update — Can user set their own role?
2. Mass assignment / over-posting — API accepts fields user shouldn't control
   ```
   grep -rn "update(|assign(|merge(|Object.assign|spread|**kwargs|**request"
   ```
3. Admin functionality without role check — Map all admin routes, verify each has role middleware
4. API versioning bypass — Old API version lacks auth checks

### Horizontal Escalation Patterns
1. Tenant isolation failures in multi-tenant apps
2. Shared resource access — org/team/group resources
3. Invitation/sharing bypass — access without accepting invite

## Severity Assessment

| Finding | Severity | Typical Bounty |
|---------|----------|----------------|
| Unauthenticated admin access | Critical | $2,000-$10,000 |
| Account takeover via auth bypass | Critical | $2,000-$10,000 |
| JWT algorithm confusion | Critical | $1,000-$5,000 |
| Vertical IDOR (admin data) | High | $1,000-$5,000 |
| Horizontal IDOR (PII exposure) | High | $500-$3,000 |
| Horizontal IDOR (non-sensitive) | Medium | $200-$1,000 |
| Missing auth on non-sensitive endpoint | Low | $100-$500 |

## Output Format
For each finding, document:
1. Vulnerable endpoint — exact route, method, parameters
2. Auth check present? — what check exists (if any)
3. What's missing — the specific authorization gap
4. Attack scenario — step-by-step exploitation
5. Impact — what data/actions an attacker gains
6. Affected code — file, line number, code snippet
7. Suggested fix — specific remediation code
