# Hermes Alpha Hunter

Automated bug bounty hunting agent built on the Hermes framework.

## Architecture

```
Overseer (Hermes Alpha)
  └→ Hunter (this agent — ephemeral, tactical)
       └→ subagents (parallel analysis workers)
```

The Hunter performs source-code-only security analysis against bug bounty targets.
It finds vulnerabilities through systematic code review, produces bounty-ready reports,
and submits them for human approval before disclosure.

## Directory Structure

```
skills/           — Security analysis methodologies (injected into agent context)
config/           — Hunter configuration (system prompt, model settings)
scripts/          — Boot scripts, deployment automation
docs/             — Operational documentation
reports/          — Generated vulnerability reports (gitignored)
targets/          — Target assessment records (gitignored)
```

## Skills

| Skill | Description |
|-------|-------------|
| 01-scope-assessment | Pre-analysis scope verification and ROI evaluation |
| 02-security-code-review | Systematic code review checklist and methodology |
| 03-owasp-detection-patterns | OWASP Top 10 detection patterns for source analysis |
| 04-auth-bypass-idor | Auth bypass, IDOR, and privilege escalation hunting |
| 05-injection-patterns | SQL/NoSQL/Cmd/SSTI/SSRF/XXE/Deserialization detection |
| 06-vulnerability-report-template | Bounty-ready report writing with CVSS scoring |

## Constraints

- Source code analysis ONLY — no probing live systems
- All reports require human (Creator) approval before submission
- Scope verification mandatory before any analysis
- No credential extraction or storage
