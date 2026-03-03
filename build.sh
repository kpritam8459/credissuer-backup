#!/bin/bash
set -e

# -------------------------------------------------------
# Load BuildPiper Functions 
# -------------------------------------------------------
source /opt/buildpiper/shell-functions/log-functions.sh
source /opt/buildpiper/shell-functions/functions.sh

# Set the codebase location
CODEBASE_LOCATION="${WORKSPACE}"/"${CODEBASE_DIR}"
logInfoMessage "I'll build the code available at [$CODEBASE_LOCATION]"

# Change to the codebase directory
cd "${CODEBASE_LOCATION}" || { logErrorMessage "Failed to change directory to $CODEBASE_LOCATION"; exit 1; }

# -------------------------------------------------------
# REQUIRED VARIABLES
# -------------------------------------------------------

: "${DB_USER:?DB_USER not set}"
: "${DB_PASSWORD:?DB_PASSWORD not set}"
: "${DB_HOST_IP:?DB_HOST_IP not set}"
: "${DB_PORT:?DB_PORT not set}"
: "${DB_NAME:?DB_NAME not set}"
: "${BACKUP_DIR:?BACKUP_DIR not set}"   

mkdir -p "${BACKUP_DIR}"

# -------------------------------------------------------
# DATE
# -------------------------------------------------------
UTC_TIME=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}-${UTC_TIME}-dump.sql"
logInfoMessage "Starting Postgres backup..."
logInfoMessage "Backup will be stored at: ${BACKUP_FILE}"

export PGPASSWORD="${DB_PASSWORD}"

# -------------------------------------------------------
# POSTGRES BACKUP 
# -------------------------------------------------------
if pg_dump -U "${DB_USER}" \
    -h "${DB_HOST_IP}" \
    -p "${DB_PORT}" \
    -d "${DB_NAME}" \
    --clean --if-exists > "${BACKUP_FILE}"
then
    logInfoMessage "Postgres backup created successfully."
    logInfoMessage "Postgres backup completed successfully."
else
    logErrorMessage "Postgres backup FAILED!"
    exit 1
fi
