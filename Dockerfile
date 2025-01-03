FROM alpine:3.21

RUN apk update
RUN apk add \
    shadow \
    tzdata \
    msmtp

# Name of the user to run the cron job. Its UID and GID
# is decided at container runtime, via CRON_USER_UID and CRON_USER_GID
# Defining the name here so that derived images can use it.
ENV CRON_USER="worker"
ENV CRON_USER_UID=1000
ENV CRON_USER_GID=1000
ENV CRON_USER_HOME="/$CRON_USER"
ENV CRON_SPEC_FILE="/crontab"
ENV CRON_ENTRYPOINT_PRE_DIR="/entrypoint.pre.d"
ENV CRON_VERBOSITY=8
ENV CRON_MAILTO=
ENV CRON_MAILTO_FILE=
ENV SMTP_HOST=
ENV SMTP_HOST_FILE=
ENV SMTP_PORT=
ENV SMTP_PORT_FILE=
ENV SMTP_TLS=on
ENV SMTP_FROM=
ENV SMTP_FROM_FILE=
ENV SMTP_USER=
ENV SMTP_USER_FILE=
ENV SMTP_PASSWORD=
ENV SMTP_PASSWORD_FILE=

# Create user and its group.
RUN groupadd -g "$CRON_USER_GID" $CRON_USER
RUN useradd -m -u "$CRON_USER_UID" -g "$CRON_USER_GID" -d "$CRON_USER_HOME" $CRON_USER
RUN ln -f -s /usr/bin/msmtp /usr/sbin/sendmail

COPY --chmod=500 ./entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/bin/sh", "/entrypoint.sh" ]
