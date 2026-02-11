#!/bin/bash
# -------------------------------------------------------
# Load BuildPiper Functions
# -------------------------------------------------------
source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh
# Ensure required local environment variables are set before SSH
: "${SSH_USER:?SSH_USER not set}"
: "${SSH_SERVER:?SSH_SERVER not set}"
: "${SSH_PORT:?SSH_PORT not set}"      # Added SSH_PORT
: "${DB_USER:?DB_USER not set}"
: "${DB_PASSWORD:?DB_PASSWORD not set}"
: "${DB_HOST_IP:?DB_HOST_IP not set}"
: "${DB_PORT:?DB_PORT not set}"
: "${DB_NAME:?DB_NAME not set}"
: "${DJANGO_ENV:?DJANGO_ENV not set}"
: "${AWS_ACCESS_KEY_ID:?AWS_ACCESS_KEY_ID not set}"
: "${AWS_SECRET_ACCESS_KEY:?AWS_SECRET_ACCESS_KEY not set}"
: "${AWS_BACKUP_BUCKET_NAME:?AWS_BACKUP_BUCKET_NAME not set}"
: "${DISCORD_WEBHOOK_URL:?DISCORD_WEBHOOK_URL not set}"

# SSH options with port support
SSH_BASE_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5 -p ${SSH_PORT:-22}"

# Function to run SSH commands
run_ssh() {
    local CMD="$1"
    if [[ -n "$SSH_PASSWORD" ]]; then
        sshpass -p "$SSH_PASSWORD" ssh $SSH_BASE_OPTS "${SSH_USER}@${SSH_SERVER}" "$CMD"
    else
        ssh $SSH_BASE_OPTS "${SSH_USER}@${SSH_SERVER}" "$CMD"
    fi
}

# Info logs
echo "[INFO] SSH_USER=${SSH_USER}"
echo "[INFO] SSH_SERVER=${SSH_SERVER}"
echo "[INFO] SSH_PORT=${SSH_PORT:-22}"

echo "[INFO] Checking SSH connectivity..."
if run_ssh "echo connected"; then
    echo "[INFO] SSH authentication successful."
else
    echo "[ERROR] SSH authentication failed."
    exit 1
fi

# Prepare remote commands as a single string
REMOTE_COMMANDS=$(cat <<EOF
# Export required variables on remote server
export DB_USER="$DB_USER"
export DB_PASSWORD="$DB_PASSWORD"
export DB_HOST_IP="$DB_HOST_IP"
export DB_PORT="$DB_PORT"
export DB_NAME="$DB_NAME"
export DJANGO_ENV="$DJANGO_ENV"
export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
export AWS_BACKUP_BUCKET_NAME="$AWS_BACKUP_BUCKET_NAME"
export DISCORD_WEBHOOK_URL="$DISCORD_WEBHOOK_URL"

# Generate backup file name
UTC_TIME=\$(date -u +"%Y-%m-%d-%H-%M-%S")
DATE_FOLDER=\$(date -u +"%d-%m-%Y")
BACKUP_FILE_PATH="\${DB_NAME}-\${UTC_TIME}-dump.sql"

# Generate backup file
echo "Generating database backup..."
PGPASSWORD="\$DB_PASSWORD" pg_dump -U "\$DB_USER" -h "\$DB_HOST_IP" -p "\$DB_PORT" -d "\$DB_NAME" --clean --if-exists > "\$BACKUP_FILE_PATH"

# Check if backup was successful
if [ -f "\$BACKUP_FILE_PATH" ]; then
    echo "Database backup created successfully."

    # Determine folder name based on DJANGO_ENV
    if [ "\$DJANGO_ENV" = "STAGING" ]; then
        FOLDER_NAME="database/staging/\${DATE_FOLDER}"
    elif [ "\$DJANGO_ENV" = "PROD" ]; then
        FOLDER_NAME="database/production/\${DATE_FOLDER}"
    else
        echo "Invalid DJANGO_ENV value."
        exit 1
    fi

    OBJECT_NAME="\${FOLDER_NAME}/\$(basename "\$BACKUP_FILE_PATH")"

    # Upload to S3
    echo "Uploading the backup to S3..."
    aws s3 cp "\$BACKUP_FILE_PATH" "s3://\${AWS_BACKUP_BUCKET_NAME}/\${OBJECT_NAME}"

    if [ \$? -eq 0 ]; then
        S3_URL="https://\${AWS_BACKUP_BUCKET_NAME}.s3.amazonaws.com/\${OBJECT_NAME}"
        echo "File uploaded successfully: \$S3_URL"
        curl -X POST -H 'Content-type: application/json' --data "{\"content\": \"Backup uploaded to S3: \$S3_URL\"}" "\$DISCORD_WEBHOOK_URL"

        # Delete local backup on remote server
        rm "\$BACKUP_FILE_PATH"
        echo "Local backup file deleted successfully."
    else
        echo "Failed to upload to S3."
        curl -X POST -H 'Content-type: application/json' --data "{\"content\": \"Error uploading file to S3: \$OBJECT_NAME\"}" "\$DISCORD_WEBHOOK_URL"
    fi
else
    echo "Backup file does not exist."
    curl -X POST -H 'Content-type: application/json' --data "{\"content\": \"Backup file \$BACKUP_FILE_PATH does not exist.\"}" "\$DISCORD_WEBHOOK_URL"
fi
EOF
)

# Execute remote commands using run_ssh function
run_ssh "$REMOTE_COMMANDS"
