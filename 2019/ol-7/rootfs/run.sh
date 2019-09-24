#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

_forwardTerm () {
    echo "Caught signal SIGTERM, passing it to child processes..."
    pgrep -P $$ | xargs kill -15 2>/dev/null
    wait
    exit $?
}

trap _forwardTerm TERM

nami start --foreground phabricator &
if [[ "${PHABRICATOR_ENABLE_GIT_SSH_REPOSITORY}" = "yes" ]] ; then
    echo "Starting SSH..."
    /usr/sbin/sshd -D &
fi
echo "Starting Apache..."
exec httpd -f /opt/bitnami/apache/conf/httpd.conf -D FOREGROUND &
wait
