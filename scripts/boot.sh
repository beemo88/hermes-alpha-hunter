#!/usr/bin/env bash
# boot.sh — Hunter agent entrypoint
# Configures environment, loads skills, and starts the Hunter in automated mode.
set -euo pipefail

REPO_DIR="/app"
SKILLS_DIR="${REPO_DIR}/skills"
CONFIG_DIR="${REPO_DIR}/config"
REPORTS_DIR="${REPO_DIR}/reports"
TARGETS_DIR="${REPO_DIR}/targets"
HERMES_HOME="${HOME}/.hermes"

echo "=== Hunter Agent Boot ==="
echo "Time: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"

# ── Ensure directories exist ──
mkdir -p "${HERMES_HOME}/skills" "${REPORTS_DIR}" "${TARGETS_DIR}"

# ── Install skills into Hermes skill directory ──
echo "Loading security skills..."
for skill_file in "${SKILLS_DIR}"/*.md; do
    if [ -f "$skill_file" ]; then
        skill_name=$(basename "$skill_file" .md)
        skill_dir="${HERMES_HOME}/skills/${skill_name}"
        mkdir -p "$skill_dir"
        cp "$skill_file" "${skill_dir}/SKILL.md"
        echo "  Loaded: ${skill_name}"
    fi
done

# ── Write Hermes config ──
# This configures the agent's model, provider, and behavior.
# Env vars OPENROUTER_API_KEY and LLM_MODEL should be set via fly secrets.
cat > "${HERMES_HOME}/config.yaml" <<EOF
model:
  default: "${LLM_MODEL:-nousresearch/hermes-3-llama-3.1-70b}"
  provider: "${HERMES_INFERENCE_PROVIDER:-openrouter}"
  base_url: "${LLM_BASE_URL:-https://openrouter.ai/api/v1}"

tools:
  enabled:
    - terminal
    - file
    - web

safety:
  yolo: true
EOF

# ── Write .env for hermes-agent ──
cat > "${HERMES_HOME}/.env" <<EOF
OPENROUTER_API_KEY=${OPENROUTER_API_KEY:-}
LLM_MODEL=${LLM_MODEL:-nousresearch/hermes-3-llama-3.1-70b}
HERMES_INFERENCE_PROVIDER=${HERMES_INFERENCE_PROVIDER:-openrouter}
EOF

# ── Inject the system prompt as SOUL.md ──
if [ -f "${CONFIG_DIR}/hunter-system-prompt.md" ]; then
    cp "${CONFIG_DIR}/hunter-system-prompt.md" "${HERMES_HOME}/SOUL.md"
    echo "System prompt loaded as SOUL.md"
fi

# ── Build the target analysis query ──
# If HUNTER_TARGET is set (repo URL), use it. Otherwise enter standby.
if [ -n "${HUNTER_TARGET:-}" ]; then
    QUERY="Analyze the target repository at ${HUNTER_TARGET} for security vulnerabilities. Follow your workflow: scope assessment, reconnaissance, systematic analysis, verification, and reporting. Save all reports to /app/reports/. Program: ${HUNTER_PROGRAM:-unknown}. Stack: ${HUNTER_STACK:-unknown}."
    echo "Target: ${HUNTER_TARGET}"
    echo "Program: ${HUNTER_PROGRAM:-unknown}"
    echo "Starting analysis..."
else
    QUERY="You are the Hunter agent. No target has been assigned yet. Report your status: list your loaded skills, confirm your environment is working (check git, python, curl are available), and then stand by. Save a status report to /app/reports/status.md."
    echo "No target assigned — entering standby mode."
fi

# ── Launch the Hunter ──
echo "=== Launching Hermes Agent ==="
exec hermes chat \
    --query "$QUERY" \
    --quiet \
    --yolo \
    --model "${LLM_MODEL:-nousresearch/hermes-3-llama-3.1-70b}" \
    --toolsets "terminal,file,web"
