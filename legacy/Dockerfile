# GitHub Actions Self-Hosted Runner (Ubuntu noble)
FROM mcr.microsoft.com/dotnet/sdk:10.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    TARGETARCH=linux-x64 \
    PATH="/root/.dotnet/tools:/opt/mkdocs/bin:${PATH}"

# ---- Base packages (single layer) ----
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

# ---- GitHub CLI ----
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/*

# ---- Optional: install .NET 8 & 9 alongside 10 ----
RUN curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh && \
    chmod +x /tmp/dotnet-install.sh && \    
    /tmp/dotnet-install.sh --channel 9.0 --install-dir /usr/share/dotnet --quality GA && \
    /tmp/dotnet-install.sh --channel 10.0 --install-dir /usr/share/dotnet --quality GA && \
    rm -f /tmp/dotnet-install.sh

# ---- Java (consider 17 unless you need 11) ----
RUN apt-get update && \
    apt-get install -y --no-install-recommends openjdk-11-jdk && \
    rm -rf /var/lib/apt/lists/*

# ---- Docker CLI/Engine (DinD style) ----
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

# ---- Node.js 22.x ----
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# ---- Go 1.24.x ----
RUN wget https://go.dev/dl/go1.24.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.24.0.linux-amd64.tar.gz && \
    rm go1.24.0.linux-amd64.tar.gz && \
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile

# ---- Rust ----
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    echo 'source ~/.cargo/env' >> /etc/profile

# ---- Mono + misc tools ----
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      mono-complete \
      mono-devel \
      && rm -rf /var/lib/apt/lists/*

# ---- MkDocs in venv ----
RUN python3 -m venv /opt/mkdocs && \
    /opt/mkdocs/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/mkdocs/bin/pip install --no-cache-dir mkdocs mkdocs-material

# ---- DocFX ----
RUN dotnet tool install -g docfx

# GitHub Actions runner workdir
WORKDIR /actions-runner

# Create runneruser (UID 1000) for non-root execution (ignore if already exists)
RUN (groupadd -g 1000 runnergroup 2>/dev/null || true) && \
    (useradd -u 1000 -g 1000 -d /home/runneruser -s /bin/bash runneruser 2>/dev/null || true) && \
    mkdir -p /home/runneruser && \
    chown -R 1000:1000 /actions-runner /home/runneruser

COPY ./*.sh ./
RUN chmod +x ./*.sh

ENTRYPOINT ["./start.sh"]