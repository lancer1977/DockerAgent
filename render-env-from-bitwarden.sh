#!/usr/bin/env bash
set -euo pipefail

# Render a runtime env file for Docker Compose from Bitwarden.
#
# Uses a single Login item with custom fields for both config and secrets.
# Create the item in Bitwarden with fields:
#   GITHUB_TOKEN (hidden), AZDO_TOKEN (hidden),
#   DOCKER_REGISTRY, GITHUB_ORG, GITHUB_RUNNER_NAME, GITHUB_RUNNER_LABELS,
#   AZDO_ORG_URL, AZDO_POOL, AZDO_AGENT_NAME, VERSION, TZ
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

ITEM_ID="${BW_DOCKERAGENT_ITEM_ID:-80186610-10ab-4eb5-a2ce-b40b005178eb}"

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

ITEM_JSON_FILE="$(mktemp)"
trap 'rm -f "$ITEM_JSON_FILE"' EXIT

bw --session "$BW_SESSION" get item "$ITEM_ID" > "$ITEM_JSON_FILE"

python3 - "$OUT_FILE" "$ITEM_JSON_FILE" <<'PY'
import json
import sys
from pathlib import Path

out_file = Path(sys.argv[1])
item = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

def field_map(item):
    result = {}
    for field in item.get("fields", []):
        name = field.get("name")
        if name:
            value = field.get("value", "")
            result[name] = "" if value is None else value
    return result

fields = field_map(item)

values = {
    "VERSION": fields.get("VERSION", "latest"),
    "DOCKER_REGISTRY": fields.get("DOCKER_REGISTRY", "lancer1977"),
    "TZ": fields.get("TZ", "America/New_York"),
    "DOCKER_BUILDKIT": "1",
    "COMPOSE_DOCKER_CLI_BUILD": "1",
    "GITHUB_ORG": fields.get("GITHUB_ORG", "Polyhydra-Games"),
    "GITHUB_URL": f"https://github.com/{fields.get('GITHUB_ORG', 'Polyhydra-Games')}",
    "GITHUB_RUNNER_NAME": fields.get("GITHUB_RUNNER_NAME", "github-runner"),
    "GITHUB_RUNNER_LABELS": fields.get("GITHUB_RUNNER_LABELS", "docker,linux"),
    "GITHUB_TOKEN": fields.get("GITHUB_TOKEN", ""),
    "AZDO_ORG_URL": fields.get("AZDO_ORG_URL", "https://dev.azure.com/PolyhydraGames"),
    "AZDO_POOL": fields.get("AZDO_POOL", "Default"),
    "AZDO_AGENT_NAME": fields.get("AZDO_AGENT_NAME", "azure-runner"),
    "AZDO_TOKEN": fields.get("AZDO_TOKEN", ""),
}

lines = [
    "# Generated from Bitwarden: DockerAgent Credentials",
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