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
docker run --rm --mount="type=bind,src=./crontab,dst=/worker/crontab" ghcr.io/2franix/cron-docker:latest
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
      - ./crontab:/worker/crontab
```

See [the sample compose.yaml](examples/compose/compose.yaml) file in the examples folder.

# Features

The image runs the cron daemon as root but uses the `worker` user to run the cron job.
At runtime, it installs the crontab file specified by the `CRON_SPEC_FILE` environment variable as `worker`'s crontab.

If you need additional scripts to run the job, the recommended way is to mount them in `worker`'s home directory (defaults to `/worker`, configurable via the `CRON_USER_HOME` environment variable). Doing so, the image guarantees that those file are owned by the `worker` user at runtime.

## Environment variables in the image

| Variable       | Default value   | Modifiable | Notes                                                                                                |
|----------------|-----------------|------------|------------------------------------------------------------------------------------------------------|
| CRON_USER      | "worker"        | no         | Set at build time, cannot be changed.                                                                |
| CRON_USER_UID  | 1000            | yes        |                                                                                                      |
| CRON_USER_GID  | 1000            | yes        |                                                                                                      |
| CRON_USER_HOME | /worker         | yes        | See CRON_SPEC_FILE if you change this variable.                                                      |
| CRON_SPEC_FILE | /worker/crontab | yes        | Contains the crontab definition, as expected by cron. Make sure to keep it under the home directory. |
| CRON_VERBOSITY | 8               | yes        | A value between 0 (max) and 8 (min) to control cron's verbosity.                                     |
