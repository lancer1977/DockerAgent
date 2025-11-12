# Build Container Starter

A reproducible build container using **Ubuntu 24.04 + asdf** to pin toolchain versions.
Update versions in `.tool-versions` and rebuild to roll dependencies forward.

## Why this approach?
- **Single source of truth** for versions via `.tool-versions`.
- Works locally (via devcontainer), in CI (Azure DevOps container jobs), and on your self-hosted agents.
- **Fast rebuilds** using Docker BuildKit cache mounts.
- Multi-language: .NET + Node out of the box; add more as needed.

## Quickstart

```bash
# Build (from repo root containing this folder)
docker build -f docker/build/Dockerfile -t my-build-img:latest .

# Run
docker run --rm -it -v "$PWD:/workspace" my-build-img:latest
```

Edit `.tool-versions` to bump **dotnet-core** or **nodejs** and rebuild.

## Add another language
1) Add an asdf plugin (e.g., Python):
```bash
asdf plugin add python https://github.com/danhper/asdf-python.git
```
2) Add `python <version>` to `.tool-versions` and rebuild.

## Azure DevOps
- Build & push your image to ACR or GHCR.
- Use `resources.containers` + `container:` in your job (see `azure-pipelines.yml`).

## Tips
- Use `--mount=type=cache` for npm, NuGet, and pip caches during *application* builds.
- Store private feeds creds as pipeline secrets; inject at runtime, not baked into the image.
- Consider a **monthly** image refresh cadence; pin exact versions for stability between refreshes.
