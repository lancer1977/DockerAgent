#!/usr/bin/env bash
set -euo pipefail

# Render a runtime env file for Docker Compose from Bitwarden org items.
#
# Requirements:
#   - bw CLI installed and unlocked
#   - BW_SESSION exported in the current shell
#
# Usage:
#   export BW_SESSION="..."
#   ./render-env-from-bitwarden.sh
#   docker stack deploy -c docker-compose.yml docker-agents

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUT_FILE="${1:-$SCRIPT_DIR/.env.runtime}"

CONFIG_ITEM_ID="${BW_DOCKERAGENT_CONFIG_ITEM_ID:-5bae9e62-e9d8-433c-8019-b40b003c93a3}"
SECRETS_ITEM_ID="${BW_DOCKERAGENT_SECRETS_ITEM_ID:-312c2b11-63d8-4055-9b59-b40b003c9a75}"

if ! command -v bw >/dev/null 2>&1; then
  echo "ERROR: bw CLI not found" >&2
  exit 1
fi

if [[ -z "${BW_SESSION:-}" ]]; then
  echo "ERROR: BW_SESSION is not set. Run 'bw unlock' first." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required" >&2
  exit 1
fi

CONFIG_JSON_FILE="$(mktemp)"
SECRETS_JSON_FILE="$(mktemp)"
trap 'rm -f "$CONFIG_JSON_FILE" "$SECRETS_JSON_FILE"' EXIT

bw --session "$BW_SESSION" get item "$CONFIG_ITEM_ID" > "$CONFIG_JSON_FILE"
bw --session "$BW_SESSION" get item "$SECRETS_ITEM_ID" > "$SECRETS_JSON_FILE"

python3 - "$OUT_FILE" "$CONFIG_JSON_FILE" "$SECRETS_JSON_FILE" <<'PY'
import json
import sys
from pathlib import Path

out_file = Path(sys.argv[1])
config = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
secrets = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))

def field_map(item):
    result = {}
    for field in item.get("fields", []):
        name = field.get("name")
        if name:
            value = field.get("value", "")
            result[name] = "" if value is None else value
    return result

cfg = field_map(config)
sec = field_map(secrets)

values = {
    "VERSION": cfg.get("VERSION", "latest"),
    "DOCKER_REGISTRY": cfg.get("DOCKER_REGISTRY", "lancer1977"),
    "TZ": cfg.get("TZ", "America/New_York"),
    "DOCKER_BUILDKIT": cfg.get("DOCKER_BUILDKIT", "1"),
    "COMPOSE_DOCKER_CLI_BUILD": cfg.get("COMPOSE_DOCKER_CLI_BUILD", "1"),
    "GITHUB_ORG": cfg.get("GITHUB_ORG", "Polyhydra-Games"),
    "GITHUB_URL": cfg.get("GITHUB_URL", f"https://github.com/{cfg.get('GITHUB_ORG', 'Polyhydra-Games')}"),
    "GITHUB_RUNNER_NAME": cfg.get("GITHUB_RUNNER_NAME", "github-runner"),
    "GITHUB_RUNNER_LABELS": cfg.get("GITHUB_RUNNER_LABELS", "docker,linux"),
    "GITHUB_TOKEN": sec.get("GITHUB_TOKEN", ""),
    "AZDO_ORG_URL": cfg.get("AZDO_ORG_URL", "https://dev.azure.com/PolyhydraGames"),
    "AZDO_POOL": cfg.get("AZDO_POOL", "Default"),
    "AZDO_AGENT_NAME": cfg.get("AZDO_AGENT_NAME", "azure-runner"),
    "AZDO_TOKEN": sec.get("AZDO_TOKEN", ""),
    "GODOT_VERSION": cfg.get("GODOT_VERSION", "4.2.2"),
    "GODOT_PROJECT_PATH": cfg.get("GODOT_PROJECT_PATH", "/godot-projects"),
}

lines = [
    "# Generated from Bitwarden items for DockerAgent.",
    "# Do not hand-edit; rerun render-env-from-bitwarden.sh instead.",
    "",
]
for key, value in values.items():
    safe = str(value).replace("\n", "\\n")
    lines.append(f"{key}={safe}")
lines.append("")
out_file.write_text("\n".join(lines), encoding="utf-8")
print(f"Wrote {out_file}")
PY

echo "Rendered DockerAgent env file to $OUT_FILE"
