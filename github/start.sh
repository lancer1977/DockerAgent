#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date +'%H:%M:%S')] $*"; }
die() { echo "ERROR: $*" 1>&2; exit 1; }

# ---- GitHub Actions Runner Setup ----
if [[ -z "${GITHUB_URL:-}" ]]; then
  die "GITHUB_URL environment variable is required"
fi

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  die "GITHUB_TOKEN environment variable is required"
fi

if [[ -z "${GITHUB_RUNNER_NAME:-}" ]]; then
  GITHUB_RUNNER_NAME="github-runner-$(hostname)"
fi

if [[ -z "${GITHUB_RUNNER_POOL:-}" ]]; then
  GITHUB_RUNNER_POOL="Default"
fi

# Download GitHub Actions runner
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/v//')
RUNNER_OS="linux"
RUNNER_ARCH="x64"
RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-${RUNNER_OS}-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"

log "Downloading GitHub Actions runner v${RUNNER_VERSION}..."
curl -L -o actions-runner.tar.gz "${RUNNER_URL}"
tar xzf actions-runner.tar.gz
rm actions-runner.tar.gz

# Configure the runner
log "Configuring GitHub Actions runner..."
./config.sh \
  --url "${GITHUB_URL}" \
  --token "${GITHUB_TOKEN}" \
  --name "${GITHUB_RUNNER_NAME}" \
  --runnergroup "${GITHUB_RUNNER_POOL}" \
  --work "_work" \
  --unattended \
  --replace

cleanup() {
  # Don't spam cleanup if we never configured
  if [[ -f .runner ]]; then
    log "Cleanup: removing GitHub Actions runner registration..."
    local deadline=$((SECONDS + 120))  # 2 min max
    while true; do
      ./config.sh remove --unattended --token "${GITHUB_TOKEN}" && break
      if (( SECONDS >= deadline )); then
        log "Cleanup: timed out removing runner; exiting anyway."
        break
      fi
      log "Cleanup: remove failed (maybe job still running). Retrying in 10s..."
      sleep 10
    done
  else
    log "Cleanup: no .runner file found; skipping remove."
  fi
}

RUNNER_PID=""

on_term() {
  log "Signal received; stopping runner..."
  if [[ -n "${RUNNER_PID}" ]] && kill -0 "${RUNNER_PID}" 2>/dev/null; then
    kill -TERM "${RUNNER_PID}" 2>/dev/null || true
    # give the runner a moment to stop gracefully
    local deadline=$((SECONDS + 30))
    while kill -0 "${RUNNER_PID}" 2>/dev/null; do
      if (( SECONDS >= deadline )); then
        log "Runner did not stop in time; killing..."
        kill -KILL "${RUNNER_PID}" 2>/dev/null || true
        break
      fi
      sleep 1
    done
  fi

  cleanup
  exit 0
}

trap on_term TERM INT

log "Starting GitHub Actions runner..."
./run.sh &
RUNNER_PID=$!

wait "${RUNNER_PID}" || true

log "Runner exited; running cleanup..."
cleanup