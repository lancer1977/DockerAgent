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

# Get a fresh registration token from the API
log "Fetching runner registration token..."
REGISTRATION_RESPONSE=$(curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" "${GITHUB_URL}/actions/runners/registration-token")
RUNNER_TOKEN=$(echo "$REGISTRATION_RESPONSE" | jq -r '.token')

if [[ -z "$RUNNER_TOKEN" ]] || [[ "$RUNNER_TOKEN" == "null" ]]; then
  die "Failed to get registration token: $REGISTRATION_RESPONSE"
fi

log "Got registration token (expires soon)"

if [[ -z "${GITHUB_RUNNER_NAME:-}" ]]; then
  GITHUB_RUNNER_NAME="github-runner-$(hostname)"
fi

if [[ -z "${GITHUB_RUNNER_POOL:-}" ]]; then
  GITHUB_RUNNER_POOL="Default"
fi

# Download GitHub Actions runner
# Hardcoded for now - can add version check later
RUNNER_VERSION="2.332.0"

log "Using runner version v${RUNNER_VERSION}..."

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
  --token "${RUNNER_TOKEN}" \
  --name "${GITHUB_RUNNER_NAME}" \
  --runnergroup "${GITHUB_RUNNER_POOL}" \
  --work "_work" \
  --unattended \
  --replace

cleanup() {
  if [[ -f .runner ]]; then
    log "Cleanup: removing GitHub Actions runner registration..."
    REMOVAL_RESPONSE=$(curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" "${GITHUB_URL}/actions/runners/remove-token")
    REMOVAL_TOKEN=$(echo "$REMOVAL_RESPONSE" | jq -r '.token')
    if [[ -n "$REMOVAL_TOKEN" ]] && [[ "$REMOVAL_TOKEN" != "null" ]]; then
      ./config.sh remove --unattended --token "${REMOVAL_TOKEN}" || true
    fi
  fi
}

trap cleanup TERM INT

log "Starting GitHub Actions runner..."
./run.sh