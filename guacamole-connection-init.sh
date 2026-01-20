#! /usr/bin/env sh
#
# This script will create connection for rdp and ssh
#

set -e
# set -x

# Guacamole properties
GUACAMOLE_HOST="${GUACAMOLE_HOST:-guacamole}"
GUACAMOLE_PORT="${GUACAMOLE_PORT:-8080}"
GUACAMOLE_USER="${GUACAMOLE_USER:-guacadmin}"
GUACAMOLE_PASSWORD="${GUACAMOLE_PASSWORD:-guacadmin}"

# Connection properties
SSH_HOST="${SSH_HOST:-openssh}"
SSH_PORT="${SSH_PORT:-2222}"
SSH_USERNAME="${SSH_USERNAME:-admin}"
SSH_PASSWORD="${SSH_PASSWORD:-admin}"
RDP_HOST="${RDP_HOST:-rdesktop}"
RDP_PORT="${RDP_PORT:-3389}"
RDP_USERNAME="${RDP_USERNAME:-abc}"
RDP_PASSWORD="${RDP_PASSWORD:-abc}"

# SFTP properties
SFTP_DISABLE_DOWNLOAD="${SFTP_DISABLE_DOWNLOAD:-false}"
SFTP_DISABLE_UPLOAD="${SFTP_DISABLE_UPLOAD:-false}"

API_URL="http://$GUACAMOLE_HOST:$GUACAMOLE_PORT/guacamole/api"

# Improved Login & DataSource retrieval
login_and_get_details() {
     response=$(curl -s -d username="$GUACAMOLE_USER" -d password="$GUACAMOLE_PASSWORD" "$API_URL/tokens")
     echo "$response"
}

create_connection() {
    local auth_token="$1"
    local data_source="$2"
    local payload="$3"

    curl -s -X POST "$API_URL/session/data/$data_source/connections?token=$auth_token" \
        -H 'Content-Type: application/json' \
        -d "$payload"
}

delete_token() {
    local auth_token="$1"
    curl -s -X DELETE "$API_URL/tokens/$auth_token"
}

# Main Execution
login_response=$(login_and_get_details)
auth_token=$(echo "$login_response" | jq -r '.authToken')
data_source=$(echo "$login_response" | jq -r '.dataSource')

existing_connections=$(curl -s -X GET "$API_URL/session/data/$data_source/connections?token=$auth_token" | jq -r '.[] | .name')

if [ -z "$existing_connections" ]; then
    echo "Creating connections..."

    # Create SSH connection
    ssh_payload=$(jq -n \
        --arg parentIdentifier "ROOT" \
        --arg name "openssh-ssh" \
        --arg protocol "ssh" \
        --arg port "$SSH_PORT" \
        --arg hostname "$SSH_HOST" \
        --arg username "$SSH_USERNAME" \
        --arg password "$SSH_PASSWORD" \
        --arg sftp_disable_download "$SFTP_DISABLE_DOWNLOAD" \
        --arg sftp_disable_upload "$SFTP_DISABLE_UPLOAD" \
        '{
            parentIdentifier: $parentIdentifier,
            name: $name,
            protocol: $protocol,
            parameters: {
                port: $port,
                hostname: $hostname,
                username: $username,
                password: $password,
                "enable-sftp": "true",
                "sftp-disable-download": $sftp_disable_download,
                "sftp-disable-upload": $sftp_disable_upload
            },
            attributes: {}
        }')
    create_connection "$auth_token" "$data_source" "$ssh_payload"

    # Create RDP connection
    rdp_payload=$(jq -n \
        --arg parentIdentifier "ROOT" \
        --arg name "rdesktop-rdp" \
        --arg protocol "rdp" \
        --arg port "$RDP_PORT" \
        --arg hostname "$RDP_HOST" \
        --arg username "$RDP_USERNAME" \
        --arg password "$RDP_PASSWORD" \
        --arg sftp_disable_download "$SFTP_DISABLE_DOWNLOAD" \
        --arg sftp_disable_upload "$SFTP_DISABLE_UPLOAD" \
        '{
            parentIdentifier: $parentIdentifier,
            name: $name,
            protocol: $protocol,
            parameters: {
                port: $port,
                hostname: $hostname,
                username: $username,
                password: $password,
                "ignore-cert": "true",
                "enable-sftp": "true",
                "sftp-username": $username,
                "sftp-password": $password,
                "sftp-disable-download": $sftp_disable_download,
                "sftp-disable-upload": $sftp_disable_upload
            },
            attributes: {}
        }')
    create_connection "$auth_token" "$data_source" "$rdp_payload"

else
    echo "Connections are already present."
fi

# Logout
delete_token "$auth_token"
