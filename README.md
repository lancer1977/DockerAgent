# DockerAgent

Unified Docker runner image for:
- GitHub Actions self-hosted runners
- Azure DevOps agents
- Godot build runners

## Current flow

### Build

```bash
docker build -t lancer1977/dockeragent:latest .
```

### Render runtime environment from Bitwarden

```bash
bw unlock
export BW_SESSION="..."
./render-env-from-bitwarden.sh
```

This generates `.env.runtime` for Docker Compose / Swarm deployment.

### Deploy

```bash
docker stack deploy -c docker-compose.yml docker-agents
```

## Environment files

- `.env.example` documents the Bitwarden-backed config/secrets shape
- `.env.runtime` is generated locally and should not be committed
- `render-env-from-bitwarden.sh` is the canonical way to produce runtime env values

## Image layout

- Root `Dockerfile` is the only image build definition that should be published
- `github/`, `AzureDevops/`, and `godot/` now primarily hold runtime scripts used by the unified image
- Old split-image publishing workflows have been removed in favor of a single unified publish workflow
