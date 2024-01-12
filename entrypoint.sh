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

run_script_folder() {
    folder="$1"
    if [ -d "$folder" ] ; then
        echo "Running scripts in $folder now."
    else
        echo "No $folder found, skipping this step."
        return
    fi
    for f in "$1"/* ; do
        echo "=> executing $f"
        sh "$f"
        echo "=> $f done"
    done
}

# Create msmtp config if enabled.
if [ -n "$SMTP_HOST" ] ; then
    MSMTPRC=/etc/msmtprc
    echo account relay > "$MSMTPRC"
    echo tls "$SMTP_TLS" >> "$MSMTPRC"
    echo host "$SMTP_HOST" >> "$MSMTPRC"
    if [ -n "$SMTP_PORT" ] ; then
        echo port "$SMTP_PORT" >> "$MSMTPRC"
    fi
    if [ -n "$SMTP_FROM" ] ; then
        echo from "$SMTP_FROM" >> "$MSMTPRC"
    fi
    if [ -n "$SMTP_USER" ] ; then
        echo auth on >> "$MSMTPRC"
        echo user "$SMTP_USER" >> "$MSMTPRC"
        if [ -n "$SMTP_PASSWORD_FILE" ] ; then
            echo password "$(cat "$SMTP_PASSWORD_FILE")" >> "$MSMTPRC"
        else
            echo password "$SMTP_PASSWORD" >> "$MSMTPRC"
        fi
    fi
    echo account default : relay >> "$MSMTPRC"
fi

# Those env vars are defined in the Dockerfile but
# let's check them one last time, in case the running environment
# messed up.
check_variable CRON_USER_UID
check_variable CRON_USER_GID
check_variable CRON_USER_HOME
check_variable CRON_SPEC_FILE
check_variable CRON_ENTRYPOINT_PRE_DIR
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
usermod -m -d "$CRON_USER_HOME" "$CRON_USER"

# Adjust user and group ids if they were changed since the image
# was built.
RUN_CHOWN=no
if [ "$(id -g "$CRON_USER")" -ne "$CRON_USER_GID" ] ; then
    echo "Adjusting id of group $CRON_USER to $CRON_USER_GID"
    groupmod -g "$CRON_USER_GID" "$CRON_USER"
    RUN_CHOWN=yes
fi
if [ "$(id -u "$CRON_USER")" -ne "$CRON_USER_UID" ] ; then
    echo "Adjusting user id of $CRON_USER to $CRON_USER_UID"
    usermod -u "$CRON_USER_UID" "$CRON_USER"
    RUN_CHOWN=yes
fi

if [ "$RUN_CHOWN" = "yes" ] ; then
    echo "Changing ownership of $CRON_USER_HOME"
    chown -R "$CRON_USER_UID:$CRON_USER_GID" "$CRON_USER_HOME"
fi

if [ -n "$CRON_MAILTO" ] ; then
    echo MAILTO=${CRON_MAILTO} > /tmp/crontab
fi
cat "$CRON_SPEC_FILE" >> /tmp/crontab

# Install crontab using standard tool to make sure the permissions
# are as cron expects. Otherwise, the crontab is silently discarded.
crontab -u "$CRON_USER" /tmp/crontab

run_script_folder "$CRON_ENTRYPOINT_PRE_DIR"
crond -f -d "$CRON_VERBOSITY" -l "$CRON_VERBOSITY"
