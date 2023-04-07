#!/usr/bin/env bash
set -x

docker build . -t local/zk
docker compose down
docker compose rm --force
docker compose up
