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
# let's check them one last time, in case the running environment
# messed up.
check_variable CRON_USER_UID
check_variable CRON_USER_GID
check_variable CRON_USER_HOME
check_variable CRON_SPEC_FILE
check_variable CRON_VERBOSITY

# Don't exceed max verbosity.
[ "$CRON_VERBOSITY" -lt 0 ] && CRON_VERBOSITY=0
# Don't exceed min verbosity.
[ "$CRON_VERBOSITY" -gt 8 ] && CRON_VERBOSITY=8

if [ ! -f "$CRON_SPEC_FILE" ] ; then
    echo "Cron spec file $CRON_SPEC_FILE not found."
    exit 1
fi

# Move user home if it was changed since the image was built.
usermod -m -u "$CRON_USER_UID" -d "$CRON_USER_HOME" "$CRON_USER"

# Adjust user and group ids if they were changed since the image
# was built.
RUN_CHOWN=no
if [ "$(id -g "$CRON_USER")" -ne "$CRON_USER_GID" ] ; then
    groupmod -g "$CRON_USER_GID" "$CRON_USER"
    RUN_CHOWN=yes
fi
if [ "$(id -u "$CRON_USER")" -ne "$CRON_USER_UID" ] ; then
    usermod -u "$CRON_USER_UID" "$CRON_USER"
    RUN_CHOWN=yes
fi

if [ "$RUN_CHOWN" = "yes" ] ; then
    chown -R "$CRON_USER_UID:$CRON_USER_GID" "$CRON_USER_HOME"
fi

# Install crontab using standard tool to make sure the permissions
# are as cron expects. Otherwise, the crontab is silently discarded.
crontab -u "$CRON_USER" "$CRON_SPEC_FILE"

crond -f -d "$CRON_VERBOSITY" -l "$CRON_VERBOSITY"
