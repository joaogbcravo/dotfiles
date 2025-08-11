FROM ubuntu:24.04

# Set environment variables to avoid interactive prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages for Nix installer and user creation
RUN apt-get update && apt-get install -y \
    curl \
    sudo \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create the user "sandbox"
RUN useradd -m -s /bin/bash sandbox && \
    echo "sandbox ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/sandbox && \
    chmod 0440 /etc/sudoers.d/sandbox

USER sandbox
WORKDIR /home/sandbox

ENTRYPOINT ["sleep", "infinity"]
