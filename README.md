[![Docker](https://github.com/2franix/cron-docker/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/2franix/cron-docker/actions/workflows/docker-publish.yml)

# A lightweight docker image for cronjobs

## Manual example with docker

Pull it with:

``` sh
docker pull docker pull ghcr.io/2franix/cron-docker:latest
```

Create a `./crontab` file:

``` sh
# Create this file in the current directory and name it crontab
* * * * * echo "It works!"
```

Run it!

``` sh
docker run --rm --mount="type=bind,src=./crontab,dst=/crontab" ghcr.io/2franix/cron-docker:latest
```

On the next minute, you should see in the output that it is working:

``` sh
crond: crond (busybox 1.36.1) started, log level 8
crond: USER worker pid  15 cmd echo "It works!"
It works!
```

## With compose

``` yaml
services:
  cron:
    image: ghcr.io/2franix/cron-docker:latest
    restart: unless-stopped
    volumes:
      - ./crontab:/crontab
```

See [the sample compose.yaml](https://github.com/2franix/cron-docker/tree/main/examples/compose) file in the examples folder for a more detailed example.

# Features

The image runs the cron daemon as root but uses the `worker` user to run the cron job.
At runtime, it installs the crontab file specified by the `CRON_SPEC_FILE` environment variable as `worker`'s crontab.

If you need additional scripts to run the job, two approaches are available:
- mount them in `worker`'s home directory (defaults to `/worker`, configurable via the `CRON_USER_HOME` environment variable). At startup, the container recursively changes ownership of the home directory, which guarantees that those files are owned by the `worker` user at runtime. The drawback is that the files ownership is changed on the host as well, which may not be suitable to all use cases
- create a derived image and copy the files in `worker`'s home directory at build time. Unlike the other approach above, the files on the host  are not modified, since this is a copy.

If you need to perform additional actions as root before starting the cron daemon, mount shell scripts in the `/entrypoint.pre.d` directory. Those files are executed in alphabetical order.

Note that the mounted crontab is installed at startup, so modifying it while the container is running does not have any effect on cron.

## SMTP with msmtp

It is possible to configure msmtp in the container so that any output produced by the cronjobs is automatically sent by email. See the `SMTP_*` and `CRON_MAILTO` variables below. This feature is disabled by default and is only enabled when `SMTP_HOST` is set.

## Environment variables in the image

| Variable                  | Default value       | Modifiable | Notes                                                                                                                               |
|---------------------------|---------------------|------------|-------------------------------------------------------------------------------------------------------------------------------------|
| `CRON_USER`               | "worker"            | no         | Set at build time, cannot be changed.                                                                                               |
| `CRON_USER_UID`           | 1000                | yes        |                                                                                                                                     |
| `CRON_USER_GID`           | 1000                | yes        |                                                                                                                                     |
| `CRON_USER_HOME`          | `/worker`           | yes        | See CRON_SPEC_FILE if you change this variable.                                                                                     |
| `CRON_ENTRYPOINT_PRE_DIR` | `/entrypoint.pre.d` | yes        | Optional folder containing scripts to execute as root before starting cron.                                                         |
| `CRON_SPEC_FILE`          | `/crontab`          | yes        | Contains the crontab definition, as expected by cron.                                                                               |
| `CRON_VERBOSITY`          | 8                   | yes        | A value between 0 (max) and 8 (min) to control cron's verbosity.                                                                    |
| `CRON_MAILTO`             | ""                  | yes        | Cron emails recipient.                                                                                                              |
| `SMTP_HOST`               | ""                  | yes        | SMTP host server to use to send emails. Leave it empty to disable msmtp entirely.                                                   |
| `SMTP_PORT`               | ""                  | yes        | Port of the SMTP server to use to send emails.                                                                                      |
| `SMTP_TLS`                | "on"                | yes        | Value of [msmtp's TLS option](https://marlam.de/msmtp/msmtp.html#index-tls).                                                        |
| `SMTP_FROM`               | ""                  | yes        | Address to appear as sender of emails sent by cron.                                                                                 |
| `SMTP_USER`               | ""                  | yes        | Username when authenticating against the SMTP server.                                                                               |
| `SMTP_PASSWORD`           | ""                  | yes        | Password when authenticating against the SMTP server.                                                                               |
| `SMTP_PASSWORD_FILE`      | ""                  | yes        | File containing the password to use when authenticating against the SMTP server. Leave it empty to use the value of `SMTP_PASSWORD` |
