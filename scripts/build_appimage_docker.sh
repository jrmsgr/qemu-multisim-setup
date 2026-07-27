#!/usr/bin/env bash
# Build the AppImage inside the rocky8 container described by docker-compose.yml.
#
# HOST_UID/HOST_GID are exported so the container runs as the calling user and
# the artifacts dropped in the bind-mounted repo are owned by them, not root.

set -e

source $(dirname $(realpath $(readlink -f "$0")))/utils.sh

cd $REPO_ROOT

export HOST_UID=$(id -u)
export HOST_GID=$(id -g)

exec docker compose run --build --rm build-appimage "$@"
