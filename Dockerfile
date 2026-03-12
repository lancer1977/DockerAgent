# Unified Docker Agent (GitHub Actions + Azure DevOps)
# Build with: docker build -t lancer1977/dockeragent:latest .
# Run with: docker run -e RUNNER_TYPE=github -e GITHUB_ORG=... -e GITHUB_TOKEN=...

FROM mcr.microsoft.com/dotnet/sdk:10.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    TARGETARCH=linux-x64 \
    PATH="/root/.dotnet/tools:/opt/mkdocs/bin:${PATH}" \
    RUNNER_TYPE=${RUNNER_TYPE:-none}

# ============================================
# Base packages (shared by all runners)
# ============================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      gnupg \
      iputils-ping \
      jq \
      lsb-release \
      python3 \
      python3-pip \
      python3-venv \
      rsync \
      openssh-client \
      software-properties-common \
      tar \
      unzip \
      wget \
      zip \
      gettext \
      doxygen \
      apt-transport-https \
      && rm -rf /var/lib/apt/lists/*

# ============================================
# GitHub CLI
# ============================================
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# Azure CLI
# ============================================
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# ============================================
# .NET 6/7/8/9/10 (support all versions)
# ============================================
RUN curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh && \
    chmod +x /tmp/dotnet-install.sh && \
    /tmp/dotnet-install.sh --channel 6.0 --install-dir /usr/share/dotnet --quality GA && \
    /tmp/dotnet-install.sh --channel 7.0 --install-dir /usr/share/dotnet --quality GA && \
    /tmp/dotnet-install.sh --channel 8.0 --install-dir /usr/share/dotnet --quality GA && \
    /tmp/dotnet-install.sh --channel 9.0 --install-dir /usr/share/dotnet --quality GA && \
    /tmp/dotnet-install.sh --channel 10.0 --install-dir /usr/share/dotnet --quality GA && \
    rm -f /tmp/dotnet-install.sh

# ============================================
# Java (OpenJDK 11 + 17 for builds)
# ============================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      openjdk-11-jdk \
      openjdk-17-jdk \
      && rm -rf /var/lib/apt/lists/*

# ============================================
# Docker (DinD style)
# ============================================
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
      > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# Node.js 22.x
# ============================================
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# Go 1.24.x
# ============================================
RUN wget https://go.dev/dl/go1.24.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.24.0.linux-amd64.tar.gz && \
    rm go1.24.0.linux-amd64.tar.gz && \
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile

# ============================================
# Rust
# ============================================
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    echo 'source ~/.cargo/env' >> /etc/profile

# ============================================
# Mono (for C# builds)
# ============================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      mono-complete \
      mono-devel \
      && rm -rf /var/lib/apt/lists/*

# ============================================
# MkDocs
# ============================================
RUN python3 -m venv /opt/mkdocs && \
    /opt/mkdocs/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/mkdocs/bin/pip install --no-cache-dir mkdocs mkdocs-material

# ============================================
# DocFX
# ============================================
RUN dotnet tool install -g docfx

# ============================================
# Runner directories
# ============================================
RUN mkdir -p /actions-runner /azp

# ============================================
# Copy scripts from each runner type
# ============================================
COPY github/start.sh /actions-runner/start.sh
COPY github/run.sh /actions-runner/run.sh
COPY github/config.sh /actions-runner/config.sh
COPY github/runscripts.sh /actions-runner/runscripts.sh
COPY AzureDevops/start.sh /azp/start.sh
COPY AzureDevops/runscripts.sh /azp/runscripts.sh

# Make scripts executable
RUN chmod +x /actions-runner/*.sh && \
    chmod +x /azp/*.sh

# Create entrypoint that routes based on RUNNER_TYPE
COPY <<'EOF' /entrypoint.sh
#!/bin/bash
set -e

echo "Starting Docker Agent..."
echo "RUNNER_TYPE: ${RUNNER_TYPE:-not set}"

case "${RUNNER_TYPE}" in
    github)
        echo "Starting GitHub Actions Runner..."
        cd /actions-runner
        exec ./start.sh
        ;;
    azure|azdo)
        echo "Starting Azure DevOps Agent..."
        cd /azp
        exec ./start.sh
        ;;
    *)
        echo "ERROR: RUNNER_TYPE must be set to: github or azure"
        echo ""
        echo "Examples:"
        echo "  docker run -e RUNNER_TYPE=github -e GITHUB_ORG=MyOrg -e GITHUB_TOKEN=... dockeragent"
        echo "  docker run -e RUNNER_TYPE=azure -e AZP_URL=https://dev.azure.com/MyOrg -e AZP_TOKEN=... dockeragent"
        exit 1
        ;;
esac
EOF

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]