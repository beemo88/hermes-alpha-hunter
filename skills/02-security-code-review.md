# Security Code Review Checklist

Systematic approach to reviewing source code for security vulnerabilities. Follow this workflow for every target codebase.

## Phase 0: Reconnaissance (5 minutes)

### Step 1: Identify the Stack
```
ls package.json requirements.txt Gemfile pom.xml go.mod Cargo.toml composer.json *.csproj
cat package.json | grep -E "express|fastify|koa|next|nuxt|nest"
cat requirements.txt | grep -E "django|flask|fastapi|tornado"
```

### Step 2: Map the Architecture
```
# Find entry points
find . -name "main.*" -o -name "app.*" -o -name "server.*" -o -name "index.*" | head -20

# Find route definitions
grep -rn "route|@app\.|@router\.|router\.|@Controller|@RequestMapping" --include="*.py" --include="*.js" --include="*.ts" --include="*.java" --include="*.go" -l

# Find models/schemas
find . -path "*/models/*" -o -path "*/schemas/*" -o -path "*/entities/*" | head -20

# Find middleware
grep -rn "middleware|interceptor|filter|before_request|before_action" -l
```

### Step 3: Identify Data Stores
```
grep -rn "mongoose|sequelize|typeorm|prisma|sqlalchemy|django\.db|ActiveRecord|gorm|database/sql" -l | head -10
```

Record: framework, language, DB type, auth mechanism, API style (REST/GraphQL/gRPC).

## Phase 1: High-Value Target Identification

Review these areas FIRST — they have the highest vulnerability density:

### Priority 1: Authentication & Session Management
Find auth-related files:
```
grep -rln "login|signin|authenticate|session|jwt|token|password" --include="*.py" --include="*.js" --include="*.ts" --include="*.java" --include="*.go"
```

Checklist:
- [ ] Password hashing algorithm (bcrypt/scrypt/argon2 = good, MD5/SHA1 = bad)
- [ ] Brute force protection (rate limiting, account lockout)
- [ ] Session ID entropy and generation
- [ ] Session invalidation on logout and password change
- [ ] JWT signing algorithm enforcement (no "none", no alg confusion)
- [ ] JWT expiration and refresh token rotation
- [ ] Cookie flags (Secure, HttpOnly, SameSite)
- [ ] Multi-factor authentication bypass potential

### Priority 2: Authorization / Access Control
Find authz-related files:
```
grep -rln "authorize|permission|role|admin|isOwner|canAccess|policy|guard" --include="*.py" --include="*.js" --include="*.ts" --include="*.java" --include="*.go"
```

Checklist:
- [ ] Every route has auth middleware applied
- [ ] Object-level authorization (not just endpoint-level)
- [ ] Role checks at service layer (not just controller)
- [ ] No mass assignment of role/permission fields
- [ ] Admin endpoints have role verification
- [ ] Multi-tenant isolation

### Priority 3: Input Handling & Injection
Find dangerous sinks:
```
grep -rln "query|execute|eval|exec|system|spawn|render.*template|innerHTML|dangerouslySetInnerHTML" --include="*.py" --include="*.js" --include="*.ts" --include="*.java" --include="*.go"
```

Checklist:
- [ ] All SQL queries use parameterized/prepared statements
- [ ] No string concatenation in queries
- [ ] No eval()/exec() with user input
- [ ] No command injection via system()/exec()/spawn()
- [ ] Template rendering sanitizes user input
- [ ] File paths validated (no path traversal)
- [ ] XML parsing disables external entities (XXE)

### Priority 4: Data Exposure
```
grep -rln "serialize|to_json|to_dict|response|render|send" --include="*.py" --include="*.js" --include="*.ts" --include="*.java" --include="*.go"
```

Checklist:
- [ ] API responses don't leak sensitive fields (password hashes, tokens, internal IDs)
- [ ] Error messages don't expose stack traces or internal paths
- [ ] Debug endpoints disabled in production
- [ ] Logging doesn't include sensitive data
- [ ] GraphQL introspection disabled in production

## Phase 2: Data Flow Tracing

For each user input entry point, trace the data through the application:

### Step 1: Identify Sources (where user data enters)
```
# HTTP request data
grep -rn "req\.body|req\.params|req\.query|req\.headers|req\.cookies"
grep -rn "request\.form|request\.args|request\.json|request\.data|request\.files"
grep -rn "@RequestParam|@PathVariable|@RequestBody|@RequestHeader"

# File uploads
grep -rn "upload|multipart|multer|formidable|FileField|MultipartFile"

# WebSocket messages
grep -rn "on\('message'|onmessage|ws\.on|socket\.on"
```

### Step 2: Identify Sinks (where data is used dangerously)
```
# Database queries
grep -rn "\.execute|\.query|\.raw|\.rawQuery|\.find(|\.findOne(|\.aggregate("

# Command execution
grep -rn "child_process|subprocess|os\.system|exec(|spawn(|popen("

# File system
grep -rn "readFile|writeFile|createReadStream|open(|unlink|rmdir"

# Network requests (SSRF)
grep -rn "fetch(|axios\.|requests\.|http\.get|urllib\.request|HttpClient"

# HTML rendering (XSS)
grep -rn "innerHTML|outerHTML|document\.write|dangerouslySetInnerHTML|render_template_string"
```

### Step 3: Trace Source to Sink
For each (source, sink) pair:
1. Does user data reach the sink?
2. What transformations/validations happen in between?
3. Are the validations sufficient to prevent exploitation?

## Phase 3: Framework-Specific Checks

### Django
- [ ] CSRF_COOKIE_SECURE = True and SESSION_COOKIE_SECURE = True
- [ ] No @csrf_exempt on state-changing views
- [ ] ALLOWED_HOSTS properly configured
- [ ] No .extra() or .raw() with unsanitized input
- [ ] SECRET_KEY not hardcoded or in version control
- [ ] Django admin restricted by IP/VPN
- [ ] Queryset filtering uses request.user for ownership

### Flask
- [ ] SECRET_KEY strong and not hardcoded
- [ ] No render_template_string() with user input (SSTI)
- [ ] Session configuration secure (cookie flags)
- [ ] No app.run(debug=True) in production
- [ ] Blueprint auth middleware applied consistently

### Express/Node
- [ ] Helmet.js or equivalent security headers
- [ ] No eval(), Function(), or vm.runInNewContext() with user input
- [ ] express-rate-limit or equivalent on auth endpoints
- [ ] cors properly configured (no wildcard in production)
- [ ] No prototype pollution via merge, extend, defaultsDeep
- [ ] MongoDB: no $where, $regex with user input without sanitization

### Spring Boot
- [ ] Spring Security properly configured
- [ ] CSRF protection enabled
- [ ] No @CrossOrigin("*") on sensitive endpoints
- [ ] SpEL injection prevented
- [ ] Actuator endpoints secured
- [ ] No unsafe deserialization (Jackson polymorphic types)

### Ruby on Rails
- [ ] Strong parameters used (no permit!)
- [ ] CSRF token verified
- [ ] No html_safe or raw on user input
- [ ] Mass assignment protection
- [ ] No SQL injection via .where("name = '\#{name}'")

### Go
- [ ] html/template used (not text/template) for HTML
- [ ] No SQL injection via fmt.Sprintf in queries
- [ ] Race conditions in goroutines sharing state
- [ ] Error messages don't leak internal info

## Phase 4: Configuration Review

### Environment & Secrets
```
find . -name ".env*" -o -name "*.env" -o -name "secrets.*" -o -name "credentials.*" 2>/dev/null
grep -rn "API_KEY|SECRET|PASSWORD|TOKEN|PRIVATE_KEY" --include="*.env" --include="*.yaml" --include="*.json" --include="*.toml"
```

### Docker/Deployment
```
find . -name "Dockerfile*" -o -name "docker-compose*" -o -name "*.yaml" -path "*/k8s/*" 2>/dev/null
```
Check: Running as non-root, no secrets in Dockerfile, minimal base image, no exposed debug ports.

### CI/CD
```
find . -name "*.yml" -path "*/.github/*" -o -name "*.yml" -path "*/.gitlab-ci*" -o -name "Jenkinsfile" 2>/dev/null
```
Check: No secrets in pipeline configs, PR reviews required, dependency scanning enabled.

## Review Strategy: Time-Boxed Approach

If limited time, allocate:
- 30% — Auth & access control review
- 25% — Input handling & injection
- 20% — Data flow tracing (source -> sink)
- 15% — Configuration & secrets
- 10% — Framework-specific checks

Document ALL findings, even low-severity. Multiple low-severity findings can combine into a high-severity report.
