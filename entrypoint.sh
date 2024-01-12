#!/usr/bin/sh

set -e -u

check_variable() {
    VAR_NAME=$1
    USE_FILE_VAR=$2
    MANDATORY=$3
    FILE_VAR_NAME="${VAR_NAME}_FILE"

    if [ "$USE_FILE_VAR" -eq 1 ] ; then
        VAR_FILE=$(printenv "$FILE_VAR_NAME")
    else
        VAR_FILE=""
    fi

    # Read content of _FILE if set.
    if [ -n "$VAR_FILE" ] ; then
        if [ -n "$(printenv "$VAR_NAME")" ] ; then
            echo "$VAR_NAME and $FILE_VAR_NAME are mutually exclusive."
            exit 1
        fi
        export "$VAR_NAME"="$(cat "$VAR_FILE")"
    fi

    if [ -z "$(printenv "$VAR_NAME")" ] && [ "$MANDATORY" -eq 1 ] ; then
        echo "$VAR_NAME is not set."
        exit 1
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

# Check all variables are defined and read their value from
# their corresponding *_FILE variable if set.
check_variable CRON_USER_UID 0 1
check_variable CRON_USER_GID 0 1
check_variable CRON_USER_HOME 0 1
check_variable CRON_SPEC_FILE 0 1
check_variable CRON_ENTRYPOINT_PRE_DIR 0 0
check_variable CRON_VERBOSITY 0 1
check_variable CRON_MAILTO 1 0
check_variable SMTP_HOST 1 0
check_variable SMTP_PORT 1 0
check_variable SMTP_TLS 0 0
check_variable SMTP_FROM 1 0
check_variable SMTP_USER 1 0
check_variable SMTP_PASSWORD 1 0

# Don't exceed max verbosity.
[ "$CRON_VERBOSITY" -lt 0 ] && CRON_VERBOSITY=0
# Don't exceed min verbosity.
[ "$CRON_VERBOSITY" -gt 8 ] && CRON_VERBOSITY=8

if [ ! -f "$CRON_SPEC_FILE" ] ; then
    echo "Cron spec file $CRON_SPEC_FILE not found."
    exit 1
fi

# Create msmtp config if enabled.
if [ -n "$SMTP_HOST" ] ; then
    echo "SMTP host set, configuring msmtp..."
    {
        echo account relay
        echo tls "$SMTP_TLS"
        echo host "$SMTP_HOST"
        if [ -n "$SMTP_PORT" ] ; then
            echo port "$SMTP_PORT"
        fi
        if [ -n "$SMTP_FROM" ] ; then
            echo from "$SMTP_FROM"
        fi
        if [ -n "$SMTP_USER" ] ; then
                echo auth on
                echo user "$SMTP_USER"
                echo password "$SMTP_PASSWORD"
        fi
        echo account default : relay
    } > /etc/msmtprc
    echo "Done: msmtp is configured in /etc/msmtprc"
else
    echo "SMTP host not set, skipping msmtp configuration."
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
