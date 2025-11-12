# syntax=docker/dockerfile:1.7-labs
ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION} AS base
SHELL ["/bin/bash", "-lc"]
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# Copy scripts
COPY docker/scripts/install-common.sh /tmp/install-common.sh
RUN chmod +x /tmp/install-common.sh && /tmp/install-common.sh

# Create non-root build user
ARG USERNAME=builder
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid ${USER_GID} ${USERNAME}       && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME}       && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}       && chmod 0440 /etc/sudoers.d/${USERNAME}

# Tools layer using asdf (versions are pinned in .tool-versions)
FROM base AS tools
COPY .tool-versions /tmp/.tool-versions
COPY docker/scripts/install-asdf.sh /tmp/install-asdf.sh
RUN chmod +x /tmp/install-asdf.sh       && mkdir -p /home/builder       && cp /tmp/.tool-versions /home/builder/.tool-versions       && chown -R builder:builder /home/builder       && /tmp/install-asdf.sh

# Optional extras
FROM tools AS extras
COPY docker/scripts/install-extras.sh /tmp/install-extras.sh
RUN chmod +x /tmp/install-extras.sh && /tmp/install-extras.sh

# Final image
FROM extras AS final
SHELL ["/bin/bash", "-lc"]
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# asdf in PATH for all shells
RUN echo '. /opt/asdf/asdf.sh' >> /etc/profile      && echo 'export PATH="$PATH:/home/builder/.asdf/shims:/home/builder/.asdf/bin"' >> /etc/profile

# Prepare caches (BuildKit cache mounts for faster builds)
RUN mkdir -p /var/cache/apt /home/builder/.cache/npm /home/builder/.nuget/packages         /home/builder/.cache/pip && chown -R builder:builder /home/builder

USER builder
WORKDIR /workspace

# Example of cache mounts (used when you docker build this image)
# Note: these are hints for application builds; not executed here.
# RUN --mount=type=cache,target=/home/builder/.cache/npm npm ci

# Default shell
CMD [ "bash" ]
