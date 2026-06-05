# Hunter Architecture

## Overview

The Hunter is a Hermes agent specialized for automated security analysis of source code.
It operates as a tactical, ephemeral worker deployed by the Overseer (Hermes Alpha).

## Components

### Skills (skills/)
Markdown files loaded into the Hunter's context that define analysis methodologies:

1. **01-scope-assessment** — Mandatory pre-analysis gate. Verifies targets are in-scope,
   assesses ROI, prevents wasted effort and legal risk.

2. **02-security-code-review** — The main analysis framework. Four-phase approach:
   reconnaissance, high-value target identification, data flow tracing, framework checks.

3. **03-owasp-detection-patterns** — OWASP Top 10 mapped to source code grep patterns.
   Provides systematic search queries for each vulnerability class.

4. **04-auth-bypass-idor** — Deep dive into authentication bypass and insecure direct
   object references. The highest-value bug class for automated analysis.

5. **05-injection-patterns** — Source-to-sink analysis for all injection types: SQL,
   NoSQL, command, SSTI, SSRF, XXE, deserialization, prototype pollution.

6. **06-vulnerability-report-template** — Report writing guide with platform-specific
   formatting, CVSS scoring, and quality checklist.

### System Prompt (config/hunter-system-prompt.md)
Defines the Hunter's identity, constraints, and workflow. Injected at agent startup.

### Configuration (config/hunter-config.yaml)
Model settings, skill loading order, time allocation, quality gates, target list.

## Analysis Workflow

```
1. SCOPE ASSESSMENT
   ├── Verify program is active
   ├── Confirm asset is in-scope
   ├── Assess ROI
   └── Record assessment → targets/

2. RECONNAISSANCE
   ├── Clone repository
   ├── Identify stack/framework
   ├── Map routes, models, middleware
   └── Identify auth mechanism

3. SYSTEMATIC ANALYSIS
   ├── Auth & access control (30%)
   ├── Injection vulnerabilities (25%)
   ├── Data flow tracing (20%)
   ├── Configuration & secrets (15%)
   └── Framework-specific checks (10%)

4. VERIFICATION
   ├── Trace complete data flow
   ├── Confirm exploitability
   ├── Assess CVSS severity
   └── Check for duplicates

5. REPORTING
   ├── Write bounty-ready report
   ├── Include code, impact, remediation
   ├── Save to reports/
   └── Flag for Creator review
```

## Target Sweet Spot

The Hunter is optimized for:
- Mid-tier bounties ($500-$5,000)
- Auth bypass, IDOR, privilege escalation, injection, SSRF
- Large codebases in Python, JavaScript, Java, Go
- Programs that accept source-code-only findings

## Deployment

The Hunter runs as a containerized Hermes agent on Fly.io. The Overseer manages
its lifecycle: deploy, configure targets, monitor results, iterate on skills.
