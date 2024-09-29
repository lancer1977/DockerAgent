FROM ubuntu:20.04
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    apt-transport-https \
    apt-utils \
    ca-certificates \
    curl \
    git \
    iputils-ping \
    jq \
    lsb-release \
    software-properties-common\
    wget

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Can be 'linux-x64', 'linux-arm64', 'linux-arm', 'rhel.6-x64'.
ENV TARGETARCH=linux-x64

#RUN declare repo_version=$(if command -v lsb_release &> /dev/null; then lsb_release -r -s; else grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"'; fi)

# Download Microsoft signing key and repository
RUN wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
# Install Microsoft signing key and repository
RUN dpkg -i packages-microsoft-prod.deb
# Clean up
RUN rm packages-microsoft-prod.deb
# Update packages
RUN apt update



#Mono / DotNet
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | tee /etc/apt/sources.list.d/mono-official-stable.list
RUN apt-get update
RUN apt-get install -y -qq --no-install-recommends \
    tar \
    mono-complete \
    mono-devel \
    dotnet-sdk-6.0 \
    dotnet-sdk-7.0 \
    dotnet-sdk-8.0
 

#JAVA
#RUN add-apt-repository ppa:webupd8team/java
#RUN apt-get update
RUN apt-get install -y -qq --no-install-recommends \
    openjdk-11-jdk

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
RUN apt-get install -y -qq --no-install-recommends \
    nuget \
    doxygen \
    unzip
#ENV USERNAME=godot
#RUN useradd -ms /bin/bash $USERNAME 
#RUN chown -R $USERNAME:$USERNAME /home/$USERNAME
#WORKDIR /home/$USERNAME
#RUN usermod -aG docker $USERNAME


#USER $USERNAME

RUN wget https://github.com/godotengine/godot/releases/download/4.2.2-stable/Godot_v4.2.2-stable_mono_linux_x86_64.zip -O godot.zip
RUN unzip godot.zip 
RUN ln Godot_v4.2.2-stable_mono_linux_x86_64/GodotSharp godotsharp -s
COPY ./*.sh .
RUN chmod +x *.sh 


ENTRYPOINT [ "./start.sh" ]