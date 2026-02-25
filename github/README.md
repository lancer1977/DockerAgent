# GitHubAgent

A docker image to create a containerized GitHub Actions self-hosted runner.

## Features

- **Multi-language Support**: .NET 10, Java 11, Node.js 22, Go 1.24, Rust, Python
- **Docker-in-Docker**: Full Docker support for containerized builds
- **GitHub CLI**: Pre-installed `gh` command-line tool
- **GitHub Actions Runner**: Self-hosted runner for GitHub Actions
- **Proper Cleanup**: Signal handling and graceful shutdown
- **Configuration Management**: Environment-based configuration

## Quick Start

### 1. Build the Image

```bash
cd github
docker build -t lancer1977/githubagent:latest .
```

### 2. Configure Environment

Create a `.env` file:

```bash
cp default.env .env
# Edit .env with your GitHub settings
```

Required environment variables:
- `GITHUB_URL`: Your GitHub repository URL (e.g., `https://github.com/your-org/your-repo`)
- `GITHUB_TOKEN`: GitHub Personal Access Token with `repo` and `admin:org` scopes

Optional environment variables:
- `GITHUB_RUNNER_NAME`: Custom runner name (defaults to `github-runner-$(hostname)`)
- `GITHUB_RUNNER_POOL`: Runner group name (defaults to `Default`)
- `DOCKER_USERNAME`/`DOCKER_PAT`: Docker Hub credentials for image pushes
- `GITHUB_PACKAGES_TOKEN`: Token for GitHub Packages access

### 3. Run with Docker Compose

```bash
docker-compose up -d
```

### 4. Run with Docker

```bash
docker run -d \
  --name github-runner \
  --restart unless-stopped \
  -e GITHUB_URL="https://github.com/your-org/your-repo" \
  -e GITHUB_TOKEN="your_github_pat" \
  -e GITHUB_RUNNER_NAME="my-runner" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /path/to/ssh:/root/.ssh:ro \
  lancer1977/githubagent:latest
```

## Creating GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Click "Generate new token (classic)"
3. Select scopes:
   - `repo` (Full control of private repositories)
   - `admin:org` (Manage GitHub Actions runners)
4. Copy the generated token

## Docker Compose Configuration

The `docker-compose.yml` file includes:

- **Two runner instances** for high availability
- **Persistent volumes** for runner work directories
- **Docker socket mounting** for Docker-in-Docker support
- **SSH key mounting** for repository access
- **Network isolation** with custom bridge network

## Supported Languages and Tools

- **.NET**: SDK 8, 9, 10
- **Java**: OpenJDK 11
- **Node.js**: Version 22
- **Go**: Version 1.24
- **Rust**: Latest stable
- **Python**: 3.x with pip
- **Mono**: Complete development environment
- **Docker**: CLI and engine
- **GitHub CLI**: `gh` command-line tool

## GitHub Actions Workflow Example

```yaml
name: CI/CD Pipeline
on: [push, pull_request]

jobs:
  build:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - name: Build with .NET
        run: dotnet build
      - name: Run tests
        run: dotnet test
      - name: Build Docker image
        run: docker build -t myapp .
```

## Security Considerations

- Use strong GitHub Personal Access Tokens
- Limit runner access to specific repositories
- Use GitHub's runner groups for organization
- Regularly rotate credentials
- Monitor runner logs for suspicious activity

## Troubleshooting

### Runner Not Appearing in GitHub

1. Check logs: `docker logs github-runner`
2. Verify GitHub URL and token
3. Ensure network connectivity to GitHub
4. Check GitHub repository permissions

### Docker-in-Docker Issues

1. Verify Docker socket is mounted: `/var/run/docker.sock`
2. Check Docker permissions in container
3. Ensure host Docker daemon is running

### Permission Issues

1. Verify SSH keys are properly mounted
2. Check file permissions on mounted volumes
3. Ensure proper user/group IDs (GUID/PUID)

## License

MIT License - see LICENSE file for details.