#!/usr/bin/env bash
set -euo pipefail

ASDF_DIR=/opt/asdf
if [ ! -d "$ASDF_DIR" ]; then
  git clone https://github.com/asdf-vm/asdf.git "$ASDF_DIR" --branch v0.14.0
fi

echo '. /opt/asdf/asdf.sh' >> /etc/profile.d/asdf.sh
echo '. /opt/asdf/completions/asdf.bash' >> /etc/profile.d/asdf.sh
chmod +x /etc/profile.d/asdf.sh

. /opt/asdf/asdf.sh

# Plugins
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git || true
asdf plugin add dotnet-core https://github.com/emersonsoares/asdf-dotnet-core.git || true

# NodeJS plugin requires gpg keys for Node releases
bash -c '${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-release-team-keyring'

# Install all versions from .tool-versions copied at build time
asdf install

# Make corepack (pnpm/yarn) available
corepack enable || true
