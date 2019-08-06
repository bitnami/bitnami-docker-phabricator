#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

_forwardTerm () {
    echo "Caugth signal SIGTERM, passing it to child processes..."
    pgrep -P $$ | xargs kill -15 2>/dev/null
    wait
    exit $?
}

trap _forwardTerm TERM

if [ "${PHABRICATOR_SSH_PORT_NUMBER}" != "" ] && [ "${PHABRICATOR_SSH_PORT_NUMBER}" != "22" ] ; then
    PHABRICATOR_SSH_USER="git"
    if ! id $PHABRICATOR_SSH_USER > /dev/null 2>&1; then
        useradd -m $PHABRICATOR_SSH_USER
    fi
    usermod -p '*' $PHABRICATOR_SSH_USER

    echo "$PHABRICATOR_SSH_USER ALL=(daemon) SETENV: NOPASSWD: /opt/bitnami/git/bin/git-upload-pack, /opt/bitnami/git/bin/git-receive-pack" >> /etc/sudoers

    cp /opt/bitnami/phabricator/resources/sshd/phabricator-ssh-hook.sh /usr/share/
    sed -i s/VCSUSER=.*/VCSUSER=\"$PHABRICATOR_SSH_USER\"/i /usr/share/phabricator-ssh-hook.sh
    sed -i 's|ROOT=.*|ROOT=\"/opt/bitnami/phabricator\"|i' /usr/share/phabricator-ssh-hook.sh
    chown root /usr/share/phabricator-ssh-hook.sh
    chmod 755 /usr/share/phabricator-ssh-hook.sh

    cat /opt/bitnami/phabricator/resources/sshd/sshd_config.phabricator.example > /etc/ssh/sshd_config
    sed -i 's|AuthorizedKeysCommand .*|AuthorizedKeysCommand /usr/share/phabricator-ssh-hook.sh|i' /etc/ssh/sshd_config
    sed -i 's/AuthorizedKeysCommandUser .*/AuthorizedKeysCommandUser '$PHABRICATOR_SSH_USER'/i' /etc/ssh/sshd_config
    sed -i 's/AllowUsers.*/AllowUsers '$PHABRICATOR_SSH_USER'/i' /etc/ssh/sshd_config
    sed -i 's/Port.*/Port '$PHABRICATOR_SSH_PORT_NUMBER'/i' /etc/ssh/sshd_config
    ln -s /opt/bitnami/php/bin/php /usr/bin/php
    /opt/bitnami/phabricator/bin/config set diffusion.ssh-port $PHABRICATOR_SSH_PORT_NUMBER
    service ssh start &
fi

if [ "${PHABRICATOR_ALLOW_GIT_LFS}" == "true" ] ; then
    /opt/bitnami/phabricator/bin/config set diffusion.allow-git-lfs true
fi

nami start --foreground phabricator &
echo "Starting Apache..."
exec httpd -f /opt/bitnami/apache/conf/httpd.conf -D FOREGROUND &
wait
