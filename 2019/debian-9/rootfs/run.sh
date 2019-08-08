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

if [ "${PHABRICATOR_SSH_PORT_NUMBER}" != "" ]; then
    if ! id $PHABRICATOR_SSH_USER > /dev/null 2>&1; then
        useradd $PHABRICATOR_SSH_USER
        if ! getent group "$PHABRICATOR_SSH_GROUP" > /dev/null 2>&1; then
            groupadd "$PHABRICATOR_SSH_GROUP" > /dev/null 2>&1
            usermod -a -G "$PHABRICATOR_SSH_GROUP" "$PHABRICATOR_SSH_USER" > /dev/null 2>&1
        fi
    fi
    usermod -p NP $PHABRICATOR_SSH_USER

    echo "$PHABRICATOR_SSH_USER ALL=(phabricator) SETENV: NOPASSWD:/opt/bitnami/git/bin/git-upload-pack,/opt/bitnami/git/bin/git-receive-pack" >> /etc/sudoers

    sed -i s/VCSUSER=.*/VCSUSER=\"$PHABRICATOR_SSH_USER\"/i /opt/bitnami/phabricator/resources/sshd/phabricator-ssh-hook.sh 
    sed -i 's|ROOT=.*|ROOT=\"/opt/bitnami/phabricator\"|i' /opt/bitnami/phabricator/resources/sshd/phabricator-ssh-hook.sh 
    chown root /opt/bitnami/phabricator/resources/sshd/phabricator-ssh-hook.sh 
    chmod 755 /opt/bitnami/phabricator/resources/sshd/phabricator-ssh-hook.sh 

    cat /opt/bitnami/phabricator/resources/sshd/sshd_config.phabricator.example > /etc/ssh/sshd_config
    sed -i 's|AuthorizedKeysCommand .*|AuthorizedKeysCommand /opt/bitnami/phabricator/resources/sshd/phabricator-ssh-hook.sh|i' /etc/ssh/sshd_config
    sed -i 's/AuthorizedKeysCommandUser .*/AuthorizedKeysCommandUser '$PHABRICATOR_SSH_USER'/i' /etc/ssh/sshd_config
    sed -i 's/AllowUsers.*/AllowUsers '$PHABRICATOR_SSH_USER'/i' /etc/ssh/sshd_config
    sed -i 's/Port.*/Port '$PHABRICATOR_SSH_PORT_NUMBER'/i' /etc/ssh/sshd_config
    if [ "${PHABRICATOR_SSH_USER}" == "git" ]; then
        sed -i 's;^\('$PHABRICATOR_SSH_USER''':.*\):/home/phabricator:;\1:/opt/bitnami/phabricator:;' /etc/passwd
    else
        sed -i 's;^\('$PHABRICATOR_SSH_USER''':.*\):/home/'$PHABRICATOR_SSH_USER':;\1:/opt/bitnami/phabricator:;' /etc/passwd
    fi

    if [[ ! -h "/usr/bin/php"  ]]; then
        ln -s /opt/bitnami/php/bin/php /usr/bin/php
    fi

    /opt/bitnami/phabricator/bin/config set diffusion.ssh-port $PHABRICATOR_SSH_PORT_NUMBER
    /opt/bitnami/phabricator/bin/config set diffusion.ssh-user $PHABRICATOR_SSH_USER
    service ssh start &
fi

if [[ "${PHABRICATOR_ALLOW_GIT_LFS:-no}" == "yes" ]] ; then
    /opt/bitnami/phabricator/bin/config set diffusion.allow-git-lfs true
fi

nami start --foreground phabricator &
echo "Starting Apache..."
exec httpd -f /opt/bitnami/apache/conf/httpd.conf -D FOREGROUND &
wait
