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

cd "${CODEBASE_LOCATION}" || { 
  logErrorMessage "Failed to change directory to $CODEBASE_LOCATION"
  exit 1
}

# -------------------------------------------------------
# REQUIRED VARIABLES
# -------------------------------------------------------

: "${DB_HOST_IP:?DB_HOST_IP not set}"
: "${DB_PORT:?DB_PORT not set}"
: "${DB_NAME:?DB_NAME not set}"
: "${BACKUP_DIR:?BACKUP_DIR not set}"

mkdir -p "${BACKUP_DIR}"

BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}-backup-$(date +%d%b%Y).archive"

logInfoMessage "Starting MongoDB backup..."
logInfoMessage "Backup file: ${BACKUP_FILE}"

# -------------------------------------------------------
# MONGODB BACKUP 
# -------------------------------------------------------

if mongodump \
  --host "${DB_HOST_IP}" \
  --port "${DB_PORT}" \
  --db "${DB_NAME}" \
  --archive="${BACKUP_FILE}"
then
    logInfoMessage "MongoDB backup created successfully."
else
    logErrorMessage "MongoDB backup FAILED!"
    exit 1
fi
