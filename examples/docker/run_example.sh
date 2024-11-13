#!/usr/bin/env sh

docker run --rm --mount="type=bind,src=./crontab,dst=/crontab" ghcr.io/2franix/cron-docker:latest
