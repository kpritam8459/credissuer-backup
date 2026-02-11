# Use lightweight image with bash + PostgreSQL client + AWS CLI
FROM ubuntu:22.04

# Disable interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    openssh-client \
    sshpass \
    postgresql-client \
    curl \
    awscli \
    && rm -rf /var/lib/apt/lists/*
    
# Create non-root user 'buildpiper' with UID and GID 65522
RUN addgroup -g 65522 buildpiper && \
    adduser -u 65522 -G buildpiper -D -s /bin/bash buildpiper
  
# Create application directories and set ownership to non-root user
RUN mkdir -p /opt/buildpiper/shell-functions && \
    chown -R buildpiper:buildpiper /opt/buildpiper
 
# Copy scripts into the container
COPY step-utilities /opt/buildpiper/shell-functions/

# Set working directory
WORKDIR /app

# Copy bash script into container
COPY build.sh .
RUN chown buildpiper:buildpiper build.sh
# Make script executable
RUN chmod +x build.sh

# Default command
CMD ["./build.sh"]
