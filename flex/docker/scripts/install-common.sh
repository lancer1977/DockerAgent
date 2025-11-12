#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends       ca-certificates curl git unzip zip gnupg locales bash-completion       build-essential pkg-config python3 python3-pip python3-venv       rsync openssh-client jq make wget sudo
rm -rf /var/lib/apt/lists/*

# Locales (use en_US.UTF-8 by default)
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8
