#!/usr/bin/bash

# Install Docker if not already installed
if ! [ -x "$(command -v docker)" ]; then
    echo 'Installing Docker...' >&2
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    # Create docker group if it doesn't exist
    if ! getent group docker > /dev/null; then
        sudo groupadd docker
    fi
    sudo usermod -aG docker $USER
    # Start and enable Docker service
    systemctl start docker
    systemctl enable docker
fi

sudo usermod -aG docker $USER

# Authenticate Docker with ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 767397895765.dkr.ecr.us-east-1.amazonaws.com

# Pull the latest image
# The ECR_URI environment variable should be set in the CodeDeploy deployment configuration
if [ -z "$ECR_URI" ]; then
    echo "Error: ECR_URI is not set. Cannot pull the image." >&2
    exit 1
fi

docker pull $ECR_URI
