FROM alpine 
RUN DEBIAN_FRONTEND=noninteractive apk update
RUN DEBIAN_FRONTEND=noninteractive apk upgrade -y

RUN apk add -y -qq  \
    apt-transport-https \
    apt-utils \
    ca-certificates \
    git \
    iputils-ping \
    jq \
    lsb-release \
    software-properties-common\
    curl \
    wget\
    tar \
    mono-complete \
    mono-devel \
    nuget

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Can be 'linux-x64', 'linux-arm64', 'linux-arm', 'rhel.6-x64'.
ENV TARGETARCH=linux-x64

 
#JAVA
RUN apt-get install -y -qq --no-install-recommends \
    openjdk-11-jdk

#DOTNET
RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh && chmod +x ./dotnet-install.sh && ./dotnet-install.sh --version latest

#Docker
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y -qq --no-install-recommends \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-compose-plugin

#RUN groupadd docker && sudo usermod -aG docker USERNAME

WORKDIR /azp

COPY ./start.sh .
RUN chmod +x start.sh

ENTRYPOINT [ "./start.sh" ]