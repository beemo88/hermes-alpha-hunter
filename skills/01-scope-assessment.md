# Scope Assessment Procedures

MANDATORY: Run this assessment BEFORE analyzing any target. Out-of-scope findings waste time and can result in legal consequences.

## Phase 1: Program Analysis

### Step 1: Read the Full Program Policy
Before ANY analysis, locate and read:
- Program scope page (assets list)
- Program policy page (rules, exclusions, safe harbor)
- Response SLA (triage times, resolution times)
- Bounty table (payout ranges by severity)

Record these fields:
```
PROGRAM ASSESSMENT
==================
Platform:        [HackerOne / Bugcrowd / Intigriti / Direct]
Program name:    [exact name]
Program type:    [Public / Private / VDP]
Bounty range:    [min - max per severity]
Response SLA:    [triage within X days]
Last updated:    [date of last scope change]
Active?:         [accepting submissions?]
```

### Step 2: Map In-Scope Assets
Create an explicit list of what IS in scope:
```
IN-SCOPE ASSETS
================
Domains:         [*.example.com, api.example.com]
Applications:    [web app at app.example.com, mobile API]
Source repos:    [github.com/company/repo1, github.com/company/repo2]
IP ranges:       [if specified]
Specific features: [if the program narrows to specific features]
```

### Step 3: Map Exclusions
Create an explicit list of what is OUT of scope:
```
OUT-OF-SCOPE
=============
Domains:         [blog.example.com, marketing.example.com]
Vulnerability types: [self-XSS, missing rate limiting, etc.]
Features:        [third-party widgets, sandbox environments]
Attack types:    [social engineering, phishing, physical]
Special rules:   [no automated scanning, no DoS testing]
```

### Step 4: Check for Source Code Analysis Rules
CRITICAL for the Hunter's mode of operation:
- Does the program accept source-code-only findings? (most do)
- Do they require a working PoC against a running instance?
- Do they accept theoretical/design-level findings?
- Is there a separate scope for source code vs. running application?

## Phase 2: Target Evaluation

### ROI Assessment
Score each potential target on these factors:

| Factor | Score 1-5 | Weight |
|--------|-----------|--------|
| Bounty amount | | 30% |
| Code complexity (more = more bugs) | | 20% |
| Technology stack (familiar?) | | 20% |
| Competition (how many researchers?) | | 15% |
| Code freshness (recent commits?) | | 15% |

Sweet spots for automated source analysis:
- Large codebases with many contributors (more inconsistency)
- Recently added features (less review time)
- Custom auth implementations (not using standard libraries)
- APIs with many endpoints (larger attack surface)
- Applications handling sensitive data (higher bounty for same bug class)

### Technology Stack Assessment
Rate analysis effectiveness by stack:

HIGH effectiveness: Python (Django/Flask/FastAPI), JavaScript/TypeScript (Express/Node), Java (Spring Boot), Go
MEDIUM effectiveness: Ruby on Rails, PHP (Laravel/Symfony), C# (.NET)
LOWER effectiveness: Rust, Elixir/Phoenix, exotic frameworks

## Phase 3: Compliance Checks

### Before Starting Analysis
- [ ] Program is currently active and accepting submissions
- [ ] Target asset is explicitly listed in scope
- [ ] Our analysis method (source code review) is allowed
- [ ] We are NOT using any prohibited methods (scanning, DoS, social engineering)
- [ ] We have recorded the scope assessment in our audit trail
- [ ] We understand the disclosure policy (timeframes, coordination)

### During Analysis
- [ ] All analysis is on source code only — NO probing of production systems
- [ ] No credentials found in code are being extracted or stored
- [ ] Findings are within the vulnerability types the program accepts
- [ ] No testing that could affect service availability
- [ ] All PoCs are sandboxed / theoretical only

### Before Report Submission
- [ ] Finding is within the program's defined scope
- [ ] Vulnerability type is not in the exclusion list
- [ ] Report does not contain any extracted secrets/credentials
- [ ] Report meets the program's minimum severity threshold
- [ ] Report has been reviewed by Creator (MANDATORY)
- [ ] No similar report exists (check disclosed reports)

## Phase 4: Repository Access Assessment

### GitHub Public Repositories
1. Verify the repo is owned/maintained by the target organization
2. Check if the repo IS the in-scope application (not a fork, demo, or deprecated version)
3. Check the repo's license — some restrict security research
4. Check if the org has a SECURITY.md or security policy
5. Verify the repo is actively maintained (recent commits)

### Red Flags (Skip This Target)
- Program hasn't responded to reports in 60+ days
- Bounty amounts are very low relative to code complexity
- Program has a history of disputing valid findings
- Code is minimal/trivial (unlikely to have meaningful bugs)
- Program scope is extremely narrow relative to the codebase

## Quick Decision Framework

```
Is the program active? NO → SKIP
Is source code analysis allowed or not prohibited? PROHIBITED → SKIP
Is the specific repo/asset in scope? NO → SKIP
Is the bounty worth our analysis time? (>$500 for medium severity?) NO → SKIP
Do we have strong patterns for this stack? NO → SKIP or deprioritize
Is the codebase large enough to have bugs? (>5000 LOC?) NO → SKIP
→ PROCEED: Run security-code-review
```

## Target Database Record
For each assessed target, record:
```
TARGET: [name]
PROGRAM: [platform/program name]
SCOPE STATUS: [in-scope / out-of-scope / borderline]
ASSET: [repo URL or domain]
STACK: [language/framework]
BOUNTY RANGE: [min-max for relevant severity]
ROI SCORE: [1-10]
DECISION: [ANALYZE / SKIP / DEPRIORITIZE]
REASON: [brief justification]
DATE ASSESSED: [YYYY-MM-DD]
```
