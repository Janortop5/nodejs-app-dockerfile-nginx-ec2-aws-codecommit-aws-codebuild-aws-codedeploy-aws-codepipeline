#!/bin/bash

# Stop any running containers
docker stop $(docker ps -a -q) || true
docker rm $(docker ps -a -q) || true

# Run the new container
docker run -d -p 80:3000 767397895765.dkr.ecr.us-east-1.amazonaws.com/endowdafrica_37:latest
