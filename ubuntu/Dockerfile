# .NET 10 SDK official image (Debian-based)
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
        tar

# Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# --- Optional: install .NET 8 & 9 SDKs alongside 10 using dotnet-install ---
# The base image already has SDK 10.0; this adds 8.0 and 9.0 so you can build
# multi-targeted solutions (net8.0, net9.0, net10.0) in the same container.
RUN curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh && \
    chmod +x /tmp/dotnet-install.sh && \
    /tmp/dotnet-install.sh --channel 8.0 --install-dir /usr/share/dotnet --quality GA && \
    /tmp/dotnet-install.sh --channel 9.0 --install-dir /usr/share/dotnet --quality GA && \
    rm /tmp/dotnet-install.sh

# JAVA
RUN apt-get update && \
    apt-get install -y -qq --no-install-recommends \
        openjdk-11-jdk

# Docker (Docker CLI & daemon inside container – Docker-in-Docker style)
# Note: base image is Debian, so use the Debian repo URL.
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
        docker-compose-plugin

# Install NodeSource Node.js 22.x
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y -qq --no-install-recommends \
        nodejs

# Mono / tools / Python / etc.
RUN apt-get update && \
    apt-get install -y -qq --no-install-recommends \
        mono-complete \
        mono-devel \
        unzip \
        zip \
        doxygen \
        rsync \
        openssh-client \
        python3-pip

# Python tools: mkdocs & mkdocs-material
RUN pip3 install --no-cache-dir mkdocs mkdocs-material

# DocFX as global dotnet tool
RUN dotnet tool install -g docfx

# Make sure global dotnet tools are on PATH
ENV PATH="${PATH}:/root/.dotnet/tools"

# (Optional) verify dotnet SDKs
# RUN dotnet --list-sdks

# Azure Pipelines agent / working directory
WORKDIR /azp

# Copy entry scripts
COPY ./*.sh .

RUN chmod +x *.sh

ENTRYPOINT ["./start.sh"]
