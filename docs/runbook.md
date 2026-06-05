# Hunter Operations Runbook

## Adding a New Target

1. Assess the bounty program (use 01-scope-assessment checklist)
2. Add target to config/hunter-config.yaml under targets.active
3. Deploy/trigger the Hunter
4. Monitor analysis progress
5. Review generated reports in reports/

## Reviewing a Report

Before submitting any report to a bounty platform:

1. Read the full report
2. Verify the vulnerable code path exists as described
3. Confirm the severity assessment is accurate
4. Check the remediation suggestion is correct
5. Ensure no sensitive data is included
6. Verify the finding is in-scope
7. Search for existing reports/disclosures on the same issue
8. Only then: submit via the bounty platform

## Updating Skills

Skills are the highest-leverage improvement. To update:

1. Identify the gap (missed vulnerability class, false positives, etc.)
2. Edit the relevant skill file in skills/
3. Commit and push
4. Redeploy the Hunter

## Common Issues

### False Positives
- Usually from grep patterns matching safe code (parameterized queries, etc.)
- Fix: improve the skill's safe-pattern documentation
- Consider adding framework-specific exclusion patterns

### Missed Findings
- Usually from incomplete data flow tracing
- Fix: add more source/sink patterns to the relevant skill
- Add framework-specific patterns for the target's stack

### Low Quality Reports
- Fix: improve 06-vulnerability-report-template
- Add more examples of good vs. bad reports
- Tighten the quality gates in config
