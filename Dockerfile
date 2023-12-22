FROM alpine:3.19.0

RUN apk update
RUN apk add \
    x2goserver \
    shadow \
    tzdata

# Name of the user to run the cron job. Its UID and GID
# is decided at container runtime, via CRON_USER_UID and CRON_USER_GID
# Defining the name here so that derived images can use it.
ENV CRON_USER="worker"
ENV CRON_USER_UID=1000
ENV CRON_USER_GID=1000
ENV CRON_USER_HOME="/$CRON_USER"
ENV CRON_SPEC_FILE="/crontab"
ENV CRON_VERBOSITY=8

# Create user and its group.
RUN groupadd -g "$CRON_USER_GID" $CRON_USER
RUN useradd -m -u "$CRON_USER_UID" -g "$CRON_USER_GID" -d "$CRON_USER_HOME" $CRON_USER

COPY --chmod=500 ./entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/bin/sh", "/entrypoint.sh" ]
