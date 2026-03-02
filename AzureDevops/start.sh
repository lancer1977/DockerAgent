#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date +'%H:%M:%S')] $*"; }
die() { echo "ERROR: $*" 1>&2; exit 1; }

# ---- existing: read AZP_PAT, download agent, configure agent, etc ----
# (keep your current logic up through ./config.sh --unattended ...)

cleanup() {
  # Don’t spam cleanup if we never configured
  if [[ -f .agent ]]; then
    log "Cleanup: removing Azure Pipelines agent registration..."
    local deadline=$((SECONDS + 120))  # 2 min max
    while true; do
      ./config.sh remove --unattended --auth PAT --token "$AZP_PAT" && break
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
    # give the agent a moment to stop gracefully
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
