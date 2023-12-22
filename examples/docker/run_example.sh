#!/usr/bin/env sh

docker run --rm --mount="type=bind,src=./crontab,dst=/worker/crontab" ghcr.io/2franix/cron-docker:latest
