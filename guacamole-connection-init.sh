#! /usr/bin/env sh
#
# This script will create connection for rdp and ssh
#

set -e
# set -x

# Guacamole properties
GUCAMOLE_HOST="${GUCAMOLE_HOST:-guacamole}"
GUCAMOLE_PORT="${GUCAMOLE_PORT:-8080}"
GUCAMOLE_USER="${GUCAMOLE_USER:-guacadmin}"
GUCAMOLE_PASSWORD="${GUCAMOLE_PASSWORD:-guacadmin}"

# Connection properties
SSH_HOST="${SSH_HOST:-openssh}"
SSH_PORT="${SSH_PORT:-2222}"
SSH_USERNAME="${SSH_USERNAME:-admin}"
SSH_PASSWORD="${SSH_PASSWORD:-admin}"
RDP_HOST="${RDP_HOST:-rdesktop}"
RDP_PORT="${RDP_PORT:-3389}"
RDP_USERNAME="${RDP_USERNAME:-abc}"
RDP_PASSWORD="${RDP_PASSWORD:-abc}"

# Login
loginResponse=$(curl -s \
-d username=$GUCAMOLE_USER \
-d password=$GUCAMOLE_PASSWORD \
http://$GUCAMOLE_HOST:$GUCAMOLE_PORT/guacamole/api/tokens)
authToken=$(echo $loginResponse | jq -r '.authToken')
dataSource=$(echo $loginResponse | jq -r '.dataSource')

anyConnectionPresent=$(curl -s -X GET http://$GUCAMOLE_HOST:$GUCAMOLE_PORT/guacamole/api/session/data/$dataSource/connections?token=$authToken | jq -r '.[] | .name')

if [ -z "$anyConnectionPresent" ]; then

  # Create SSH connection
  curl -s -X POST http://$GUCAMOLE_HOST:$GUCAMOLE_PORT/guacamole/api/session/data/$dataSource/connections?token=$authToken \
    -H 'Content-Type: application/json' \
    -d "{ \"parentIdentifier\": \"ROOT\", \"name\": \"openssh-ssh\", \"protocol\": \"ssh\", \"parameters\": { \"port\": \"${SSH_PORT}\", \"hostname\": \"${SSH_HOST}\", \"username\": \"${SSH_USERNAME}\", \"password\": \"${SSH_PASSWORD}\" }, \"attributes\": {} }"

  # Create RDP connection
  curl -s -X POST http://$GUCAMOLE_HOST:$GUCAMOLE_PORT/guacamole/api/session/data/$dataSource/connections?token=$authToken \
    -H 'Content-Type: application/json' \
    -d "{ \"parentIdentifier\": \"ROOT\", \"name\": \"rdesktop-rdp\", \"protocol\": \"rdp\", \"parameters\": { \"port\": \"${RDP_PORT}\", \"hostname\": \"${RDP_HOST}\", \"username\": \"${RDP_USERNAME}\", \"password\": \"${RDP_PASSWORD}\", \"ignore-cert\": \"true\" }, \"attributes\": {} }"
else
  echo "connections are already present."
fi

# Logout
curl -s -X DELETE http://$GUCAMOLE_HOST:$GUCAMOLE_PORT/guacamole/api/tokens/$authToken