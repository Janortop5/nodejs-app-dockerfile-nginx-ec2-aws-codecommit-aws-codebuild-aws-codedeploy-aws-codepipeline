# Use Ubuntu as the base image
FROM ubuntu:latest

# Install necessary packages and clean up in one step
RUN apt-get update && apt-get install -y \
    git \
    nodejs \
    npm \
    nginx \
    dos2unix \
    && rm -rf /var/lib/apt/lists/* \
    && git clone https://github.com/Dejanor/provision-private-nginx-servers-using-bashscripting---nodejs-bash-script-alb-namedotcom.git /app \ 
    && cd /app \
    && dos2unix ./deploy-node-app.sh \
    && chmod +x ./deploy-node-app.sh

# Set the working directory
WORKDIR /app

# Run the script to install dependencies
RUN bash ./deploy-node-app.sh

# Expose port 80 for Nginx
EXPOSE 3000

# Start both Node.js app and Nginx
CMD node server.js & nginx -g 'daemon off;'
