# OWASP Top 10 Detection Patterns

Use this skill when performing source code analysis. For each vulnerability class, follow the detection patterns to find candidates, then verify exploitability.

## A01: Broken Access Control

### Detection Patterns
1. Missing auth middleware — Search for route definitions without auth decorators/middleware
2. Direct object references — User-supplied IDs used to fetch resources without ownership checks:
   ```
   grep -rn "findById|find_by_id|objects.get|.get(id" --include="*.py" --include="*.js" --include="*.java"
   ```
3. Horizontal privilege escalation: API endpoints accepting user_id/account_id as parameter, missing WHERE user_id = current_user.id
4. Path traversal in file operations:
   ```
   grep -rn "open(|readFile|createReadStream|file_get_contents|include(|require(" | grep -v node_modules
   ```

### Verification
Trace from route handler -> service layer -> data access layer. Confirm auth user's identity is checked at EACH layer.

## A02: Cryptographic Failures

### Detection Patterns
1. Weak algorithms:
   ```
   grep -rni "md5|sha1|des|rc4|ecb|pkcs1v15" --include="*.py" --include="*.js" --include="*.java" --include="*.go"
   ```
2. Hardcoded secrets:
   ```
   grep -rni "password\s*=\s*[\"']|secret\s*=\s*[\"']|api_key\s*=\s*[\"']" --include="*.py" --include="*.js" --include="*.env"
   ```
3. Plaintext storage — password models without hashing
4. Missing TLS enforcement — http:// URLs, verify=False, rejectUnauthorized: false, missing HSTS

## A03: Injection

### Detection Patterns
1. SQL Injection — String concatenation/formatting in queries:
   ```
   grep -rn "execute(|query(|raw(|rawQuery|cursor\." | grep -E "(%s|%d|\+\s*|f\"|.format|concat|\$\{)"
   ```
2. Command Injection:
   ```
   grep -rn "exec(|spawn(|system(|popen(|subprocess\.|os.system|child_process|Runtime.getRuntime"
   ```
3. NoSQL Injection — Request body passed directly as query filter without type checking
4. LDAP Injection:
   ```
   grep -rn "ldap|LdapContext|ldap_search|ldap_bind"
   ```
5. Template Injection (SSTI):
   ```
   grep -rn "render_template_string|Template(|from_string|nunjucks"
   ```

### Verification
Trace user input from entry point to sink. Check for parameterized queries, prepared statements, ORM usage. ORM doesn't guarantee safety — raw queries within ORM are still vulnerable.

## A04: Insecure Design

### Detection Patterns
1. Missing rate limiting on: password reset, login, OTP verification, API key generation
2. Business logic flaws: race conditions (missing locking/transactions), negative quantity, coupon reuse
3. Missing server-side validation: only client-side validation, price sent from client

## A05: Security Misconfiguration

### Detection Patterns
1. Debug mode in production:
   ```
   grep -rni "debug\s*=\s*true|DEBUG\s*=\s*True|NODE_ENV.*development" --include="*.py" --include="*.js" --include="*.yaml" --include="*.env"
   ```
2. Default credentials:
   ```
   grep -rni "admin:admin|root:root|password123|default_password|changeme"
   ```
3. Verbose error handling — stack traces exposed
4. Missing security headers — X-Frame-Options, CSP, CORS wildcards
5. Exposed admin interfaces without IP restriction

## A06: Vulnerable and Outdated Components

### Detection Patterns
1. Dependency analysis: pip audit, npm audit, yarn audit, govulncheck
2. Known vulnerable versions in package.json, requirements.txt, pom.xml, go.mod
3. Unmaintained dependencies (>2yr since last commit, archived repos)

## A07: Identification and Authentication Failures

### Detection Patterns
1. Weak password policies: min length < 8, no complexity
2. Missing brute force protection on login
3. Session management: missing expiration, insecure cookie flags, predictable tokens
4. Password reset: predictable tokens, no expiration, token reuse

## A08: Software and Data Integrity Failures

### Detection Patterns
1. Insecure deserialization:
   ```
   grep -rn "pickle\.|yaml\.load(|unserialize(|readObject(|ObjectInputStream"
   ```
   Red flags: yaml.load() without SafeLoader, pickle.loads() on user input
2. Missing integrity checks on updates, plugins, dependencies
3. CI/CD pipeline vulnerabilities

## A09: Security Logging and Monitoring Failures

### Detection Patterns
1. Missing audit logging for: auth events, authz failures, data modifications, admin actions
2. Sensitive data in logs:
   ```
   grep -rn "log\.|logger\.|console\.log|print(" | grep -i "password|token|secret|credit|ssn"
   ```

## A10: Server-Side Request Forgery (SSRF)

### Detection Patterns
1. User-controlled URLs:
   ```
   grep -rn "requests\.|urllib|fetch(|http\.get|HttpClient|URL(|openConnection"
   ```
2. URL validation bypass — DNS rebinding, scheme restrictions, redirect following
3. Webhook/callback URLs submitted by users without validation

### Verification
Can user control full URL or just path? Are internal IP ranges blocked? Does app follow redirects?

## Priority for Bug Bounties

Focus detection in this order (by bounty ROI):
1. A01 Broken Access Control — Most common, highest payouts
2. A03 Injection — Classic high-severity
3. A10 SSRF — Hot bounty category, often overlooked
4. A07 Auth Failures — Account takeover = critical
5. A02 Crypto Failures — Data exposure = high severity

For each finding, document: location, vulnerable code, attack vector, impact, and suggested fix.
