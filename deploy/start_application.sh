#!/bin/bash

ECR_URI=$(jq -r '.[0].imageUri' /opt/codedeploy-agent/deployment-root/imagedefinitions.json)

# Stop any running containers
docker stop $(docker ps -a -q) || true
docker rm $(docker ps -a -q) || true

# Run the new container
# The ECR_URI environment variable should be set in the CodeDeploy deployment configuration
if [ -z "$ECR_URI" ]; then
    echo "Error: ECR_URI is not set. Cannot start the container." >&2
    exit 1
fi

docker run -d -p 80:3000 $ECR_URI:latest
