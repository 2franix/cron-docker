#!/usr/bin/sh

set -e -u

check_variable() {
    VAR_NAME=$1
    VAR_DEFAULT=
    [ $# -ge 2 ] && VAR_DEFAULT="$2"

    if [ -z "$(printenv "$VAR_NAME")" ] ; then
        if [ -z "$VAR_DEFAULT" ] ; then
            echo "$VAR_NAME not set."
            exit 1
        else
            export "$VAR_NAME"="$VAR_DEFAULT"
        fi
    fi
}

check_variable CRON_UID
check_variable CRON_GID
check_variable CRON_SPEC_FILE "/crontab"
# Set verbosity to minimum.
check_variable VERBOSITY 8

# Don't exceed max verbosity.
[ "$VERBOSITY" -lt 0 ] && VERBOSITY=0
# Don't exceed min verbosity.
[ "$VERBOSITY" -gt 8 ] && VERBOSITY=8

if [ ! -f "$CRON_SPEC_FILE" ] ; then
    echo "Cron spec file $CRON_SPEC_FILE not found."
    exit 1
fi

CRON_USER=cron_worker
# Create user and group if not yet done.
if ! grep "^${CRON_USER}:" /etc/group ; then
    groupadd -g "$CRON_GID" ${CRON_USER}
fi
if ! id "$CRON_USER" >/dev/null 2>&1 ; then
    useradd -m -u "$CRON_UID" -g "$CRON_USER" "$CRON_USER"
fi

# Install crontab using standard tool to make sure the permissions
# are as cron expects. Otherwise, the crontab is silently discarded.
crontab -u "$CRON_USER" "$CRON_SPEC_FILE"

crond -f -d "$VERBOSITY" -l "$VERBOSITY"
