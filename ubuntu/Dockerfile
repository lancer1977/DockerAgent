# .NET 10 SDK official image (Ubuntu noble-based)
FROM mcr.microsoft.com/dotnet/sdk:10.0

ENV DEBIAN_FRONTEND=noninteractive \
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1

# Optional: target arch metadata
ENV TARGETARCH=linux-x64

# Base tools
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y -qq --no-install-recommends \
        apt-transport-https \
        apt-utils \
        ca-certificates \
        curl \
        git \
        gnupg \
        iputils-ping \
        jq \
        lsb-release \
        software-properties-common \
        wget \
        tar \
        python3 \
        python3-venv \
        python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# --- Optional: install .NET 8 & 9 SDKs alongside 10 using dotnet-install ---
RUN curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh && \
    chmod +x /tmp/dotnet-install.sh && \
    /tmp/dotnet-install.sh --channel 8.0 --install-dir /usr/share/dotnet --quality GA && \
    /tmp/dotnet-install.sh --channel 9.0 --install-dir /usr/share/dotnet --quality GA && \
    rm /tmp/dotnet-install.sh

# JAVA
RUN apt-get update && \
    apt-get install -y -qq --no-install-recommends \
        openjdk-11-jdk && \
    rm -rf /var/lib/apt/lists/*

# Docker (Docker-in-Docker) – Ubuntu repo
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y -qq --no-install-recommends \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

# Install NodeSource Node.js 22.x
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y -qq --no-install-recommends \
        nodejs && \
    rm -rf /var/lib/apt/lists/*

# Mono / misc tools
RUN apt-get update && \
    apt-get install -y -qq --no-install-recommends \
        mono-complete \
        mono-devel \ 
        unzip \
        zip \
        doxygen \
        rsync \
        openssh-client \
        gettext    && \
    rm -rf /var/lib/apt/lists/*

# Python tools: mkdocs & mkdocs-material in a dedicated venv
RUN python3 -m venv /opt/mkdocs && \
    /opt/mkdocs/bin/pip install --no-cache-dir mkdocs mkdocs-material

ENV PATH="/opt/mkdocs/bin:${PATH}"

# DocFX as global dotnet tool
RUN dotnet tool install -g docfx

# Make sure global dotnet tools are on PATH
ENV PATH="${PATH}:/root/.dotnet/tools"

# (Optional) verify dotnet SDKs
# RUN dotnet --list-sdks

# Azure Pipelines agent / working directory
WORKDIR /azp

# Copy entry scripts
COPY ./*.sh ./

RUN chmod +x *.sh

ENTRYPOINT ["./start.sh"]
