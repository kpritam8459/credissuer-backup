FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget gnupg curl ca-certificates lsb-release && \
    rm -rf /var/lib/apt/lists/*

# Add PostgreSQL official repository
RUN echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg

# Install PostgreSQL 16 client (contains pg_dump)
RUN apt-get update && \
    apt-get install -y postgresql-client-16 && \
    rm -rf /var/lib/apt/lists/*

# Verify pg_dump version
RUN /usr/lib/postgresql/16/bin/pg_dump --version

# Set PATH so pg_dump 16 is default
ENV PATH="/usr/lib/postgresql/16/bin:${PATH}"

# Create non-root group and user (UID/GID 65522)
RUN groupadd -g 65522 buildpiper && \
    useradd -u 65522 -g 65522 -m -s /bin/bash buildpiper

# Create application directory
RUN mkdir -p /opt/buildpiper/shell-functions

# Copy shell functions
COPY BP-BASE-SHELL-STEPS /opt/buildpiper/shell-functions/

# Copy backup script
COPY build.sh /opt/buildpiper/build.sh

# Set ownership and permissions
RUN chown -R buildpiper:buildpiper /opt/buildpiper && \
    chmod +x /opt/buildpiper/build.sh

# Switch to non-root user
USER buildpiper

WORKDIR /opt/buildpiper

# Default command
ENTRYPOINT ["./build.sh"]
