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

# Those env vars are defined in the Dockerfile but
# let's check them one last time, to be on the safe side.
check_variable CRON_USER_UID
check_variable CRON_USER_GID
check_variable CRON_SPEC_FILE "/crontab"
check_variable CRON_VERBOSITY 8

# Don't exceed max verbosity.
[ "$CRON_VERBOSITY" -lt 0 ] && CRON_VERBOSITY=0
# Don't exceed min verbosity.
[ "$CRON_VERBOSITY" -gt 8 ] && CRON_VERBOSITY=8

if [ ! -f "$CRON_SPEC_FILE" ] ; then
    echo "Cron spec file $CRON_SPEC_FILE not found."
    exit 1
fi

# Adjust user and group ids if they were changed since the image
# was built.
if [ "$(id -g "$CRON_USER")" -ne "$CRON_USER_GID" ] ; then
    groupmod -g "$CRON_USER_GID" "$CRON_USER"
fi
if [ "$(id -u "$CRON_USER")" -ne "$CRON_USER_UID" ] ; then
    usermod -u "$CRON_USER_UID" "$CRON_USER"
fi

# Install crontab using standard tool to make sure the permissions
# are as cron expects. Otherwise, the crontab is silently discarded.
crontab -u "$CRON_USER" "$CRON_SPEC_FILE"

crond -f -d "$CRON_VERBOSITY" -l "$CRON_VERBOSITY"
