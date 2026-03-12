#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date +'%H:%M:%S')] $*"; }
die() { echo "ERROR: $*" 1>&2; exit 1; }

# ---- Azure DevOps Agent Setup ----
if [[ -z "${AZP_URL:-}" ]]; then
  die "AZP_URL environment variable is required (e.g., https://dev.azure.com/YourOrg)"
fi

if [[ -z "${AZP_TOKEN:-}" ]]; then
  die "AZP_TOKEN environment variable is required"
fi

AZP_POOL="${AZP_POOL:-Default}"
AZP_AGENT_NAME="${AZP_AGENT_NAME:-azure-runner-$(hostname)}"
AZP_WORK="${AZP_WORK:-_work}"

# Download Azure Pipelines agent if not present
if [[ ! -f ./config.sh ]]; then
  log "Downloading Azure Pipelines agent..."
  
  # Detect architecture
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64) AGENT_ARCH="x64" ;;
    aarch64) AGENT_ARCH="arm64" ;;
    armv7l)  AGENT_ARCH="arm" ;;
    *) die "Unsupported architecture: $ARCH" ;;
  esac
  
  # Get latest agent version
  AGENT_VERSION=$(curl -s "${AZP_URL}/_apis/distributedtask/packages/agent?platform=linux&architecture=${AGENT_ARCH}" | \
    jq -r '.value[0].version')
  
  if [[ -z "$AGENT_VERSION" ]] || [[ "$AGENT_VERSION" == "null" ]]; then
    # Fallback to known version
    AGENT_VERSION="4.248.0"
    log "Could not detect agent version, using default: $AGENT_VERSION"
  fi
  
  AGENT_URL="${AZP_URL}/_apis/distributedtask/packages/agent/${AGENT_VERSION}/linux-${AGENT_ARCH}-agent.tar.gz"
  
  log "Downloading agent from $AGENT_URL"
  curl -L -o agent.tar.gz "$AGENT_URL"
  
  log "Extracting agent..."
  tar xzf agent.tar.gz
  rm agent.tar.gz
  
  log "Agent downloaded successfully"
fi

# Configure the agent if not already configured
if [[ ! -f .agent ]]; then
  log "Configuring Azure Pipelines agent..."
  ./config.sh \
    --unattended \
    --url "${AZP_URL}" \
    --auth PAT \
    --token "${AZP_TOKEN}" \
    --pool "${AZP_POOL}" \
    --agent "${AZP_AGENT_NAME}" \
    --work "${AZP_WORK}" \
    --acceptTeeEula
  log "Agent configured successfully"
fi

cleanup() {
  if [[ -f .agent ]]; then
    log "Cleanup: removing Azure Pipelines agent registration..."
    local deadline=$((SECONDS + 120))
    while true; do
      if ./config.sh remove --unattended --auth PAT --token "${AZP_TOKEN}" 2>/dev/null; then
        log "Agent removed successfully"
        break
      fi
      if (( SECONDS >= deadline )); then
        log "Cleanup: timed out removing agent; exiting anyway."
        break
      fi
      log "Cleanup: remove failed (maybe job still running). Retrying in 10s..."
      sleep 10
    done
  else
    log "Cleanup: no .agent file found; skipping remove."
  fi
}

AGENT_PID=""

on_term() {
  log "Signal received; stopping agent..."
  if [[ -n "${AGENT_PID}" ]] && kill -0 "${AGENT_PID}" 2>/dev/null; then
    kill -TERM "${AGENT_PID}" 2>/dev/null || true
    local deadline=$((SECONDS + 30))
    while kill -0 "${AGENT_PID}" 2>/dev/null; do
      if (( SECONDS >= deadline )); then
        log "Agent did not stop in time; killing..."
        kill -KILL "${AGENT_PID}" 2>/dev/null || true
        break
      fi
      sleep 1
    done
  fi

  cleanup
  exit 0
}

trap on_term TERM INT

log "Starting Azure Pipelines agent..."
./run.sh &
AGENT_PID=$!

wait "${AGENT_PID}" || true

log "Agent exited; running cleanup..."
cleanup