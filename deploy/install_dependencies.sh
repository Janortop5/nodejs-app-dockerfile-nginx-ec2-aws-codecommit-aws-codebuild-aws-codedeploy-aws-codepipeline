#!/bin/bash

# Install Docker if not already installed
if ! [ -x "$(command -v docker)" ]; then
  echo 'Error: docker is not installed.' >&2
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  usermod -aG docker $USER
  systemctl start docker
  systemctl enable docker
fi

# Pull the latest image
docker pull 767397895765.dkr.ecr.us-east-1.amazonaws.com/endowdafrica_37:latest
