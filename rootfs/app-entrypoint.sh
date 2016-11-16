#!/bin/bash
set -e

function initialize {
    # Package can be "installed" or "unpacked"
    status=`nami inspect $1`
    if [[ "$status" == *'"lifecycle": "unpacked"'* ]]; then
        # Clean up inputs
        inputs=""
        if [[ -f /$1-inputs.json ]]; then
            inputs=--inputs-file=/$1-inputs.json
        fi
        nami initialize $1 $inputs
    fi
}

# Set default values
export APACHE_HTTP_PORT=${APACHE_HTTP_PORT:-"80"}
export APACHE_HTTPS_PORT=${APACHE_HTTPS_PORT:-"443"}
export PHABRICATOR_USERNAME=${PHABRICATOR_USERNAME:-"user"}
export PHABRICATOR_PASSWORD=${PHABRICATOR_PASSWORD:-"bitnami1"}
export PHABRICATOR_FIRSTNAME=${PHABRICATOR_FIRSTNAME:-"FirstName"}
export PHABRICATOR_LASTNAME=${PHABRICATOR_LASTNAME:-"LastName"}
export PHABRICATOR_HOST=${PHABRICATOR_HOST:-"127.0.0.1"}
export PHABRICATOR_EMAIL=${PHABRICATOR_EMAIL:-"user@example.com"}
export MARIADB_USER=${MARIADB_USER:-"root"}
export MARIADB_HOST=${MARIADB_HOST:-"mariadb"}
export MARIADB_PORT=${MARIADB_PORT:-"3306"}

if [[ "$1" == "nami" && "$2" == "start" ]] ||  [[ "$1" == "/init.sh" ]]; then
   for module in apache php phabricator; do
    initialize $module
   done
   echo "Starting application ..."
fi

exec /entrypoint.sh "$@"
