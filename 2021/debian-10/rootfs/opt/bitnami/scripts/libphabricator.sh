#!/bin/bash
#
# Bitnami Phabricator library

# shellcheck disable=SC1091

# Load generic libraries
. /opt/bitnami/scripts/libphp.sh
. /opt/bitnami/scripts/libfs.sh
. /opt/bitnami/scripts/libnet.sh
. /opt/bitnami/scripts/libos.sh
. /opt/bitnami/scripts/libvalidations.sh
. /opt/bitnami/scripts/libpersistence.sh
. /opt/bitnami/scripts/libwebserver.sh

# Load database library
if [[ -f /opt/bitnami/scripts/libmysqlclient.sh ]]; then
    . /opt/bitnami/scripts/libmysqlclient.sh
elif [[ -f /opt/bitnami/scripts/libmysql.sh ]]; then
    . /opt/bitnami/scripts/libmysql.sh
elif [[ -f /opt/bitnami/scripts/libmariadb.sh ]]; then
    . /opt/bitnami/scripts/libmariadb.sh
fi

########################
# Check if Phabricator daemons are running
# Arguments:
#   None
# Returns:
#   Boolean
#########################
is_phabricator_running() {
    pid="$(get_pid_from_file "$PHABRICATOR_PID_FILE")"
    if [[ -n "$pid" ]]; then
        is_service_running "$pid"
    else
        false
    fi
}

########################
# Check if Phabricator daemons are not running
# Arguments:
#   None
# Returns:
#   Boolean
#########################
is_phabricator_not_running() {
    ! is_phabricator_running
}

########################
# Stop Phabricator daemons
# Arguments:
#   None
# Returns:
#   None
#########################
phabricator_stop() {
    ! is_phabricator_running && return
    info "Stopping Phabricator"
    stop_service_using_pid "$PHABRICATOR_PID_FILE"
}

########################
# Validate settings in PHABRICATOR_* env vars
# Globals:
#   PHABRICATOR_*
# Arguments:
#   None
# Returns:
#   0 if the validation succeeded, 1 otherwise
#########################
phabricator_validate() {
    debug "Validating settings in PHABRICATOR_* environment variables..."
    local error_code=0

    # Auxiliary functions
    print_validation_error() {
        error "$1"
        error_code=1
    }
    check_yes_no_value() {
        if ! is_yes_no_value "${!1}" && ! is_true_false_value "${!1}"; then
            print_validation_error "The allowed values for ${1} are: yes no"
        fi
    }
    check_multi_value() {
        if [[ " ${2} " != *" ${!1} "* ]]; then
            print_validation_error "The allowed values for ${1} are: ${2}"
        fi
    }
    check_resolved_hostname() {
        if ! is_hostname_resolved "$1"; then
            warn "Hostname ${1} could not be resolved, this could lead to connection issues"
        fi
    }
    check_empty_value() {
        if is_empty_value "${!1}"; then
            print_validation_error "${1} must be set"
        fi
    }

    # Warn users in case the configuration file is not writable
    is_file_writable "$PHABRICATOR_CONF_FILE" || warn "The Phabricator local configuration file '${PHABRICATOR_CONF_FILE}' is not writable. Configurations based on environment variables will not be applied for this file."

    # Validate user inputs
    ! is_empty_value "$PHABRICATOR_ENABLE_GIT_SSH_REPOSITORY" && check_yes_no_value "PHABRICATOR_ENABLE_GIT_SSH_REPOSITORY"
    ! is_empty_value "$PHABRICATOR_USE_LFS" && check_yes_no_value "PHABRICATOR_USE_LFS"
    ! is_empty_value "$PHABRICATOR_ENABLE_HTTPS" && check_yes_no_value "PHABRICATOR_ENABLE_HTTPS"
    ! is_empty_value "$PHABRICATOR_ENABLE_PYGMENTS" && check_yes_no_value "PHABRICATOR_ENABLE_PYGMENTS"
    ! is_empty_value "$PHABRICATOR_SSH_PORT_NUMBER" && validate_port "$PHABRICATOR_DATABASE_PORT_NUMBER"
    ! is_empty_value "$PHABRICATOR_SKIP_BOOTSTRAP" && check_yes_no_value "PHABRICATOR_SKIP_BOOTSTRAP"
    ! is_empty_value "$PHABRICATOR_DATABASE_HOST" && check_resolved_hostname "$PHABRICATOR_DATABASE_HOST"
    ! is_empty_value "$PHABRICATOR_DATABASE_PORT_NUMBER" && validate_port "$PHABRICATOR_DATABASE_PORT_NUMBER"

    # Validate SSH configuration
    local -r err_msg="You set the environment variable PHABRICATOR_ENABLE_GIT_SSH_REPOSITORY=yes while running the container as non-root. Please note this feature is currently supported when running the container as \"root\" at this moment."
    ! am_i_root && ! is_empty_value "$PHABRICATOR_ENABLE_GIT_SSH_REPOSITORY" && is_boolean_yes "$PHABRICATOR_ENABLE_GIT_SSH_REPOSITORY" && print_validation_error "$err_msg"

    # Validate credentials
    if is_boolean_yes "$ALLOW_EMPTY_PASSWORD"; then
        warn "You set the environment variable ALLOW_EMPTY_PASSWORD=${ALLOW_EMPTY_PASSWORD}. For safety reasons, do not use this flag in a production environment."
    else
        is_empty_value "$PHABRICATOR_DATABASE_ADMIN_PASSWORD" && print_validation_error "The PHABRICATOR_DATABASE_ADMIN_PASSWORD environment variable is empty or not set. Set the environment variable ALLOW_EMPTY_PASSWORD=yes to allow a blank password. This is only recommended for development environments."
    fi
    check_empty_value "PHABRICATOR_PASSWORD"
    if ((${#PHABRICATOR_PASSWORD} < 8)); then
        print_validation_error "The admin password must be at least 8 characters long. Set the environment variable PHABRICATOR_PASSWORD with a longer value"
    fi
    if grep -q "$PHABRICATOR_PASSWORD" "${PHABRICATOR_BASE_DIR}/externals/wordlist/password.lst"; then
        print_validation_error "The admin password configured is one of the most common passwords in use. Set the environment variable PHABRICATOR_PASSWORD with a stronger password."
    fi
    if is_boolean_yes "$PHABRICATOR_SKIP_BOOTSTRAP"; then
        if is_empty_value "$PHABRICATOR_EXISTING_DATABASE_USER" || is_empty_value "$PHABRICATOR_EXISTING_DATABASE_PASSWORD"; then
            print_validation_error "The database credentials must be set when skipping the initial bootstrapping of the application. To provide the credentials, set the environment variables PHABRICATOR_EXISTING_DATABASE_USER and PHABRICATOR_EXISTING_DATABASE_PASSWORD."
        fi
    fi

    # Validate SMTP credentials
    if ! is_empty_value "$PHABRICATOR_SMTP_HOST"; then
        for empty_env_var in "PHABRICATOR_SMTP_USER" "PHABRICATOR_SMTP_PASSWORD" "PHABRICATOR_SMTP_PORT_NUMBER"; do
            is_empty_value "${!empty_env_var}" && print_validation_error "The ${empty_env_var} environment variable is empty or not set."
        done
        ! is_empty_value "$PHABRICATOR_SMTP_PROTOCOL" && check_multi_value "PHABRICATOR_SMTP_PROTOCOL" "ssl tls"
    fi

    # Check that the web server is properly set up
    web_server_validate || print_validation_error "Web server validation failed"

    return "$error_code"
}

########################
# Ensure Phabricator is initialized
# Globals:
#   PHABRICATOR_*
# Arguments:
#   None
# Returns:
#   None
#########################
phabricator_initialize() {
    # Check if Phabricator has already been initialized and persisted in a previous run
    local -r app_name="phabricator"
    local -r port="${WEB_SERVER_HTTP_PORT_NUMBER:-"$WEB_SERVER_DEFAULT_HTTP_PORT_NUMBER"}"
    if ! is_app_initialized "$app_name"; then
        info "Creating Phabricator configuration file"
        # Configure SMTP settings
        ! is_empty_value "$PHABRICATOR_SMTP_HOST" && phabricator_configure_smtp
        # Configure Phabricator URL to pass Wizard"
        phabricator_conf_set "phabricator.base-uri"           "http://127.0.0.1:${port}"
        # Configure extra settings
        phabricator_conf_set "phd.log-directory"              "$PHABRICATOR_LOGS_DIR"
        phabricator_conf_set "storage.local-disk.path"        "$PHABRICATOR_DATA_DIR"
        phabricator_conf_set "repository.default-local-path"  "${PHABRICATOR_VAR_DIR}/repo"
        local -r -a append_paths=("${BITNAMI_ROOT_DIR}/git/bin")
        phabricator_conf_set "environment.append-paths"       "$(printf '%s\n' "${append_paths[@]}" | jq -R . | jq -s .)"
        phabricator_conf_set "security.hmac-key"              "$(generate_random_string -t alphanumeric -c 44)"
        phabricator_conf_set "diffusion.allow-git-lfs"        "$(php_convert_to_boolean "$PHABRICATOR_USE_LFS")"
        phabricator_conf_set "pygments.enabled"               "$(php_convert_to_boolean "$PHABRICATOR_ENABLE_PYGMENTS")"
        local -r -a ignore_issues=(
            "cluster.mailers"                         # Can be solved setting SMTP env. variables (unset by default). It's recommended but not mandatory.
            "security.security.alternate-file-domain" # Can be solved with PHABRICATOR_ALTERNATE_FILE_DOMAIN (unset by default). It's recommended but not mandatory.
        )
        phabricator_conf_set "config.ignore-issues"          "$(printf '%s\n' "${ignore_issues[@]}" | jq -R . | jq -s .)"
        if ! is_boolean_yes "$PHABRICATOR_SKIP_BOOTSTRAP"; then
            # Phabricator needs to create many databases during install so root credentials are needed
            info "Trying to connect to the database server"
            phabricator_wait_for_db_connection "$PHABRICATOR_DATABASE_HOST" "$PHABRICATOR_DATABASE_PORT_NUMBER" "$PHABRICATOR_DATABASE_ADMIN_USER" "$PHABRICATOR_DATABASE_ADMIN_PASSWORD"

            local -r db_user="bn_phabricator"
            local -r db_pass="$(generate_random_string -t alphanumeric -c 8)"
            # We grant all privileges for the user on the databases created by PH
            DB_ROOT_USER="$PHABRICATOR_DATABASE_ADMIN_USER" DB_ROOT_PASSWORD="$PHABRICATOR_DATABASE_ADMIN_PASSWORD" mysql_ensure_optional_user_exists "$db_user" "--host" "$PHABRICATOR_DATABASE_HOST" "--port" "$PHABRICATOR_DATABASE_PORT_NUMBER" "-p" "$db_pass"
            mysql_remote_execute "$PHABRICATOR_DATABASE_HOST" "$PHABRICATOR_DATABASE_PORT_NUMBER" "" "$PHABRICATOR_DATABASE_ADMIN_USER" "$PHABRICATOR_DATABASE_ADMIN_PASSWORD" <<< "GRANT ALL ON \`bitnami_phabricator\_%\`.* TO '$db_user'@'%';"
            # Configure Phabricator database
            phabricator_configure_database_credentials "$db_user" "$db_pass"

            # Upgrade database
            debug_execute "${PHABRICATOR_BIN_DIR}/storage" upgrade --force

            # Enable password authentication
            info "Enabling password authentication"
            phid="$(generate_random_string -t alphanumeric -c 20)"
            mysql_remote_execute "$PHABRICATOR_DATABASE_HOST" "$PHABRICATOR_DATABASE_PORT_NUMBER" "bitnami_phabricator_auth" "$db_user" "$db_pass" <<EOF
INSERT INTO auth_providerconfig (id, phid, providerClass, providerType, providerDomain, isEnabled, shouldAllowLogin, shouldAllowRegistration, shouldAllowLink, shouldAllowUnlink, shouldTrustEmails, properties, dateCreated, dateModified, shouldAutoLogin)
VALUES (1, '${phid}', 'PhabricatorPasswordAuthProvider', 'password', 'self', 1, 1, 1, 1, 0, 0, '[]', UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0);
EOF

            # Configure Admin account
            phabricator_pass_user_creation_wizard
            # Enable admin account
            info "Granting admin privileges to the new user"
            debug_execute "${PHABRICATOR_BIN_DIR}/auth" verify "$PHABRICATOR_EMAIL"
            debug_execute "${PHABRICATOR_BIN_DIR}/user" empower "--user" "$PHABRICATOR_USERNAME"
            # Phabricator still does not support approving users via CLI, so for now we will execute an SQL query to do so
            mysql_remote_execute "$PHABRICATOR_DATABASE_HOST" "$PHABRICATOR_DATABASE_PORT_NUMBER" "bitnami_phabricator_user" "$db_user" "$db_pass" <<< "UPDATE user SET isApproved = 1 WHERE userName = '${PHABRICATOR_USERNAME}';"
            info "Lock authentication"
            debug_execute "${PHABRICATOR_BIN_DIR}/auth" lock
        else
            info "An already initialized Phabricator database was provided, configuration will be skipped"
            # When using an existing database we want to avoid modifying the database at all cost, so the database password must be specified
            info "Trying to connect to the database server"
            phabricator_wait_for_db_connection "$PHABRICATOR_DATABASE_HOST" "$PHABRICATOR_DATABASE_PORT_NUMBER" "$PHABRICATOR_EXISTING_DATABASE_USER" "$PHABRICATOR_EXISTING_DATABASE_PASSWORD"

            # Configure Phabricator to use the new user to connect to the database
            phabricator_configure_database_credentials "$PHABRICATOR_EXISTING_DATABASE_USER" "$PHABRICATOR_EXISTING_DATABASE_PASSWORD"

            # Upgrade database
            debug_execute "${PHABRICATOR_BIN_DIR}/storage" upgrade --force
        fi

        # Configure host
        phabricator_configure_host
        # Configure alternate file domain
        ! is_empty_value "$PHABRICATOR_ALTERNATE_FILE_DOMAIN" && phabricator_configure_alternate_file_domain

        info "Persisting Phabricator installation"
        persist_app "$app_name" "$PHABRICATOR_DATA_TO_PERSIST"
    else
        info "Restoring persisted Phabricator installation"
        restore_persisted_app "$app_name" "$PHABRICATOR_DATA_TO_PERSIST"  
        info "Trying to connect to the database server"
        db_host="$(phabricator_conf_get "mysql.host")"
        db_port="$(phabricator_conf_get "mysql.port")"
        db_user="$(phabricator_conf_get "mysql.user")"
        db_pass="$(phabricator_conf_get "mysql.pass")"
        phabricator_wait_for_db_connection "$db_host" "$db_port" "$db_user" "$db_pass"
        # Upgrade database
        debug_execute "${PHABRICATOR_BIN_DIR}/storage" upgrade --force
    fi

    # Configure PH system users & SSH daemon
    am_i_root && phabricator_configure_system_users
    is_boolean_yes "$PHABRICATOR_ENABLE_GIT_SSH_REPOSITORY" && phabricator_enable_vcs_sshd_config

    # Avoid exit code of previous commands to affect the result of this function
    true
}

########################
# Add or modify an entry in the Phabricator local configuration
# Globals:
#   PHABRICATOR_*
# Arguments:
#   $1 - Property key
#   $2 - Property value
# Returns:
#   None
#########################
phabricator_conf_set() {
    local -r key="${1:?key missing}"
    local -r value="${2:?value missing}"

    debug "Setting ${key} to '${value}' in Phabricator local configuration"
    debug_execute "${PHABRICATOR_BIN_DIR}/config" set "$key" "$value"
}

########################
# Get a property value from Phabricator local configuration
# Globals:
#   PHABRICATOR_*
# Arguments:
#   $1 - Property key
# Returns:
#   (string) The property value 
#########################
phabricator_conf_get() {
    local -r key="${1:?key missing}"

    debug "Getting ${key} value from Phabricator local configuration"
    "${PHABRICATOR_BIN_DIR}/config" get "$key" | jq -r '.config[] | select( .source == "local") | .value'
}

########################
# Wait until the database is accessible with the currently-known credentials
# Globals:
#   *
# Arguments:
#   $1 - database host
#   $2 - database port
#   $3 - database username
#   $4 - database user password (optional)
# Returns:
#   true if the database connection succeeded, false otherwise
#########################
phabricator_wait_for_db_connection() {
    local -r db_host="${1:?missing database host}"
    local -r db_port="${2:?missing database port}"
    local -r db_user="${3:?missing database user}"
    local -r db_pass="${4:-}"
    check_mysql_connection() {
        echo "SELECT 1" | mysql_remote_execute "$db_host" "$db_port" "" "$db_user" "$db_pass"
    }
    if ! retry_while "check_mysql_connection"; then
        error "Could not connect to the database"
        return 1
    fi
}

#########################
# Configure Phabricator database
# Globals:
#   PHABRICATOR_*
# Arguments:
#   $1 - database user name
#   $2 - database user password
# Returns:
#   None
#########################
phabricator_configure_database_credentials() {
    local -r db_user="${1:?missing database user}"
    local -r db_pass="${2:?missing database password}"
            
    info "Configuring database"
    phabricator_conf_set "mysql.host"                     "$PHABRICATOR_DATABASE_HOST"
    phabricator_conf_set "mysql.port"                     "$PHABRICATOR_DATABASE_PORT_NUMBER"
    phabricator_conf_set "mysql.user"                     "$db_user"
    phabricator_conf_set "mysql.pass"                     "$db_pass"
    phabricator_conf_set "storage.default-namespace"      "bitnami_phabricator"
    phabricator_conf_set "storage.mysql-engine.max-size"  "0"
}

########################
# Configure SMTP
# Globals:
#   PHABRICATOR_*
# Arguments:
#   None
# Returns:
#   None
#########################
phabricator_configure_smtp() {
    info "Configuring SMTP"
    debug_execute "${PHABRICATOR_BIN_DIR}/config" set --stdin "cluster.mailers" <<EOF
[{
    "key": "smtp-mailer",
    "type": "smtp",
    "options": {
        "host": "${PHABRICATOR_SMTP_HOST}",
        "port": ${PHABRICATOR_SMTP_PORT_NUMBER},
        "user": "${PHABRICATOR_SMTP_USER}",
        "password": "${PHABRICATOR_SMTP_PASSWORD}",
        "protocol": "${PHABRICATOR_SMTP_PROTOCOL}"
    }
}]
EOF
    phabricator_conf_set "metamta.default-address"         "$PHABRICATOR_SMTP_USER"
    phabricator_conf_set "metamta.one-mail-per-recipient"  "true"
    phabricator_conf_set "metamta.can-send-as-user"        "false"
    phabricator_conf_set "metamta.recipients.show-hints"   "true"
    phabricator_conf_set "metamta.public-replies"          "false"
    phabricator_conf_set "metamta.user-address-format"     "real"
    phabricator_conf_set "metamta.reply-handler-domain"    "$PHABRICATOR_SMTP_HOST"
}

#########################
# Create Phabricator user passing the wizard
# Globals:
#   PHABRICATOR_*
# Arguments:
#   None
# Returns:
#   None
#########################
phabricator_pass_user_creation_wizard() {
    local -r port="${WEB_SERVER_HTTP_PORT_NUMBER:-"$WEB_SERVER_DEFAULT_HTTP_PORT_NUMBER"}"
    local wizard_url cookie_file curl_output csrf_token
    local -a curl_opts curl_data_opts

    info "Configuring Admin Account"
    wizard_url="http://127.0.0.1:${port}/auth/register/"    
    cookie_file="/tmp/cookie$(generate_random_string -t alphanumeric -c 8)"
    curl_opts=("--location" "--silent" "--cookie" "$cookie_file" "--cookie-jar" "$cookie_file")
    # Ensure the web server is started
    web_server_start
    # Step 0: Get cookies & obtain CSRF token
    curl_output="$(curl "${curl_opts[@]}" "$wizard_url" 2>/dev/null)"
    csrf_token="$(sed -z -E 's/^.*__csrf__"\s+value="([^"]*)".*$/\1/' <<< "$curl_output")"
    # Step 1: Admin user creation
    curl_data_opts=(
        "--data-urlencode" "__csrf__=${csrf_token}"
        "--data-urlencode" "__form__=1"
        "--data-urlencode" "username=${PHABRICATOR_USERNAME}"
        "--data-urlencode" "realName=${PHABRICATOR_FIRST_NAME} ${PHABRICATOR_LAST_NAME}"
        "--data-urlencode" "password=${PHABRICATOR_PASSWORD}"
        "--data-urlencode" "confirm=${PHABRICATOR_PASSWORD}"
        "--data-urlencode" "email=${PHABRICATOR_EMAIL}"
    )
    curl_output="$(curl "${curl_opts[@]}" "${curl_data_opts[@]}" "${wizard_url}" 2>/dev/null)"
    if [[ "$curl_output" != *"Wait for Approval"* ]]; then
        error "An error occurred while configuring Phabricator admin account"
        return 1
    fi
    # Stop the web server afterwards
    web_server_stop
}

#########################
# Configure Phabricator host
# Globals:
#   PHABRICATOR_*
# Arguments:
#   None
# Returns:
#   None
#########################
phabricator_configure_host() {
    local host
    local scheme

    get_hostname() {
        if [[ -n "${PHABRICATOR_HOST:-}" ]]; then
            echo "$PHABRICATOR_HOST"
        else
            dns_lookup "$(hostname)" "v4"
        fi
    }

    host="$(get_hostname)"
    if is_boolean_yes "$PHABRICATOR_ENABLE_HTTPS"; then
        scheme="https"
        [[ "$PHABRICATOR_EXTERNAL_HTTPS_PORT_NUMBER" != "443" ]] && host+=":${PHABRICATOR_EXTERNAL_HTTPS_PORT_NUMBER}"
    else
        scheme="http"
        [[ "$PHABRICATOR_EXTERNAL_HTTP_PORT_NUMBER" != "80" ]] && host+=":${PHABRICATOR_EXTERNAL_HTTP_PORT_NUMBER}"
    fi
    info "Configuring Phabricator URL to ${scheme}://${host}"
    phabricator_conf_set "phabricator.base-uri" "${scheme}://${host}"
}

#########################
# Configure Phabricator alternate file domain
# Globals:
#   PHABRICATOR_*
# Arguments:
#   None
# Returns:
#   None
#########################
phabricator_configure_alternate_file_domain() {
    local afd="$PHABRICATOR_ALTERNATE_FILE_DOMAIN"
    local scheme
    if is_boolean_yes "$PHABRICATOR_ENABLE_HTTPS"; then
        scheme="https"
        [[ "$PHABRICATOR_EXTERNAL_HTTPS_PORT_NUMBER" != "443" ]] && afd+=":${PHABRICATOR_EXTERNAL_HTTPS_PORT_NUMBER}"
    else
        scheme="http"
        [[ "$PHABRICATOR_EXTERNAL_HTTP_PORT_NUMBER" != "80" ]] && afd+=":${PHABRICATOR_EXTERNAL_HTTP_PORT_NUMBER}"
    fi
    info "Configuring Phabricator Alternate File Domain to ${scheme}://${afd}"
    phabricator_conf_set "security.alternate-file-domain" "${scheme}://${afd}"
}

#########################
# Configure PH system users
# Globals:
#   PHABRICATOR_*
# Arguments:
#   None
# Returns:
#   None
#########################
phabricator_configure_system_users() {
    local -r ssh_port="${PHABRICATOR_SSH_PORT_NUMBER:-"$PHABRICATOR_DEFAULT_SSH_PORT_NUMBER"}"

    info "Configuring Phabricator system users"
    # Configure system user properties
    phabricator_conf_set "phd.user"             "$PHABRICATOR_DAEMON_USER"
    phabricator_conf_set "diffusion.ssh-user"   "$PHABRICATOR_SSH_VCS_USER"
    phabricator_conf_set "diffusion.ssh-port"   "$ssh_port"
}

#########################
# Configure SSH daemon to support hosted git repositories over SSH
# Globals:
#   PHABRICATOR_*
# Arguments:
#   None
# Returns:
#   None
#########################
phabricator_enable_vcs_sshd_config() {
    local -r ssh_port="${PHABRICATOR_SSH_PORT_NUMBER:-"$PHABRICATOR_DEFAULT_SSH_PORT_NUMBER"}"
    
    info "Configuring SSH daemon to support hosted GIT repositories"
    replace_in_file "${PHABRICATOR_BASE_DIR}/resources/sshd/phabricator-ssh-hook.sh" "^\s*VCSUSER=\s*.*$" "VCSUSER=${PHABRICATOR_SSH_VCS_USER}"
    replace_in_file "${PHABRICATOR_BASE_DIR}/resources/sshd/phabricator-ssh-hook.sh" "^\s*ROOT=\s*.*$" "ROOT=${PHABRICATOR_BASE_DIR}\nPATH=$PATH"
    chmod 775 "${PHABRICATOR_BASE_DIR}/resources/sshd/phabricator-ssh-hook.sh"
    cp "${PHABRICATOR_BASE_DIR}/resources/sshd/sshd_config.phabricator.example" "/etc/ssh/sshd_config"
    replace_in_file "/etc/ssh/sshd_config" "^\\s*AuthorizedKeysCommand\\s+.*$" "AuthorizedKeysCommand ${PHABRICATOR_BASE_DIR}/resources/sshd/phabricator-ssh-hook.sh"
    replace_in_file "/etc/ssh/sshd_config" "^\\s*AuthorizedKeysCommandUser\\s+.*$" "AuthorizedKeysCommandUser $PHABRICATOR_SSH_VCS_USER"
    replace_in_file "/etc/ssh/sshd_config" "^\\s*AllowUsers\\s+.*$" "AllowUsers $PHABRICATOR_SSH_VCS_USER"
    replace_in_file "/etc/ssh/sshd_config" "^\\s*Port\\s+.*$" "Port $ssh_port"
    echo "PermitUserEnvironment yes" >> "/etc/ssh/sshd_config"
    mkdir -p "/home/${PHABRICATOR_SSH_VCS_USER}/.ssh"
    echo "PATH=$PATH" > "/home/${PHABRICATOR_SSH_VCS_USER}/.ssh/environment"
}

#########################
# Regenerate SSH keys
# Globals:
#   PHABRICATOR_*
# Arguments:
#   None
# Returns:
#   None
#########################
phabricator_regenerate_ssh_keys() {
    local -r ssh_keys_dir="${PHABRICATOR_VOLUME_DIR}/.sshkeys"
    if [[ ! -d "$ssh_keys_dir" ]]; then
        mkdir -p "$ssh_keys_dir"
        debug_execute ssh-keygen -t dsa -f "${ssh_keys_dir}/ssh_host_dsa_key" -N ""
        debug_execute ssh-keygen -t rsa -f "${ssh_keys_dir}/ssh_host_rsa_key" -N ""
        debug_execute ssh-keygen -t ecdsa -f "${ssh_keys_dir}/ssh_host_ecdsa_key" -N ""
        debug_execute ssh-keygen -t ed25519 -f "${ssh_keys_dir}/ssh_host_ed25519_key" -N ""
    fi
    rm -f /etc/ssh/ssh_host_*
    cp -rp "${ssh_keys_dir}"/. /etc/ssh/
}
