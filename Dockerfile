# Use Ubuntu as the base image
FROM ubuntu:latest

# Install necessary packages and clean up in one step
RUN apt-get update && apt-get install -y \
    nodejs \
    npm \
    nginx \
    dos2unix \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy the repository files into the container
COPY . /app

# Convert line endings and make the script executable
RUN dos2unix ./deploy-node-app.sh && chmod +x ./deploy-node-app.sh

# Run the script to install dependencies
RUN bash ./deploy-node-app.sh

# Expose port 3000 for the Node.js app
EXPOSE 3000

# Start both Node.js app and Nginx
CMD node server.js & nginx -g 'daemon off;'