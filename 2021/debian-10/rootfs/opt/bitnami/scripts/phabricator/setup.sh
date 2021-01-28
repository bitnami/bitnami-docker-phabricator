#!/bin/bash

# shellcheck disable=SC1090,SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load Phabricator environment
. /opt/bitnami/scripts/phabricator-env.sh

# Load MySQL Client environment for 'mysql_remote_execute' (after 'phabricator-env.sh' so that MODULE is not set to a wrong value)
if [[ -f /opt/bitnami/scripts/mysql-client-env.sh ]]; then
    . /opt/bitnami/scripts/mysql-client-env.sh
elif [[ -f /opt/bitnami/scripts/mysql-env.sh ]]; then
    . /opt/bitnami/scripts/mysql-env.sh
elif [[ -f /opt/bitnami/scripts/mariadb-env.sh ]]; then
    . /opt/bitnami/scripts/mariadb-env.sh
fi

# Load libraries
. /opt/bitnami/scripts/libphabricator.sh
. /opt/bitnami/scripts/libwebserver.sh

# Load web server environment and functions (after Phabricator environment file so MODULE is not set to a wrong value)
. "/opt/bitnami/scripts/$(web_server_type)-env.sh"

# Ensure Phabricator environment variables are valid
phabricator_validate

# Update web server configuration with runtime environment (needs to happen before the initialization)
web_server_update_app_configuration "phabricator"

if am_i_root; then
    # Ensure required system users exist
    # ref: https://secure.phabricator.com/book/phabricator/article/diffusion_hosting/
    info "Configuring system users"
    ensure_user_exists "$WEB_SERVER_DAEMON_USER" --group "$WEB_SERVER_DAEMON_GROUP"
    ensure_user_exists "$PHABRICATOR_DAEMON_USER" --group "$PHABRICATOR_DAEMON_GROUP" --home "/home/$PHABRICATOR_DAEMON_USER" --system
    ensure_user_exists "$PHABRICATOR_SSH_VCS_USER" --group "$PHABRICATOR_SSH_VCS_GROUP" --home "/home/$PHABRICATOR_SSH_VCS_USER" --system
    # Unlock VCS user without password authentication
    debug_execute usermod -p NP "$PHABRICATOR_SSH_VCS_USER"
    # Web Server & VCS users need to be able to sudo as the PH daemon user so they can interact with repositories
    cat > /etc/sudoers.d/phabricator << EOF
"${WEB_SERVER_DAEMON_USER}" ALL=("${PHABRICATOR_DAEMON_USER}") SETENV: NOPASSWD: $(command -v git), $(command -v git-http-backend), $(command -v ssh)
"${PHABRICATOR_SSH_VCS_USER}" ALL=("${PHABRICATOR_DAEMON_USER}") SETENV: NOPASSWD: $(command -v git), $(command -v git-upload-pack), $(command -v git-receive-pack), $(command -v ssh)
EOF
    chmod 440 /etc/sudoers.d/phabricator

    # Ensure required directories exists and have proper permissions
    info "Configuring file permissions for Phabricator"
    configure_permissions_ownership "${PHABRICATOR_DATA_DIR}" -d "775" -f "664" -u "$WEB_SERVER_DAEMON_USER" -g "$WEB_SERVER_DAEMON_GROUP"
    configure_permissions_ownership "${PHABRICATOR_VAR_DIR}" -d "775" -f "664" -u "$PHABRICATOR_DAEMON_USER" -g "$PHABRICATOR_DAEMON_GROUP"
    # Remove writing permissions in the config directory to the group when running as root
    configure_permissions_ownership "${PHABRICATOR_BASE_DIR}/conf/local" -d "755" -f "644"
fi

# Ensure Phabricator is initialized
phabricator_initialize

# Regenerate keys
am_i_root && phabricator_regenerate_ssh_keys || true
