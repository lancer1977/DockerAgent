#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Example: install ImageMagick (often handy in build pipelines)
apt-get update && apt-get install -y --no-install-recommends imagemagick && rm -rf /var/lib/apt/lists/*

# Example: Azure CLI (uncomment if you need it frequently)
# curl -sL https://aka.ms/InstallAzureCLIDeb | bash
