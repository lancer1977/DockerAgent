#!/bin/bash
set -e

print_header() {
  lightcyan='\033[1;36m'
  nocolor='\033[0m'
  echo -e "${lightcyan}$1${nocolor}"
}

cleanup() {
  if [ -e ./config.sh ]; then
    print_header "Cleanup. Removing Azure Pipelines agent..."
    while true; do
      ./config.sh remove --unattended --auth PAT --token "$(cat "$AZP_TOKEN_FILE")" && break
      echo "Retrying in 30 seconds..."
      sleep 30
    done
  fi
}

# traps MUST be set early
trap 'cleanup; exit 0' EXIT
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Run external setup scripts (ignore failures)
./runscripts.sh || true

if [ -z "$AZP_URL" ]; then
  echo 1>&2 "error: missing AZP_URL environment variable"
  exit 1
fi

if [ -z "$AZP_TOKEN_FILE" ]; then
  if [ -z "$AZP_TOKEN" ]; then
    echo 1>&2 "error: missing A
