#!/usr/bin/env bash
set -euo pipefail

TARGET_HOST="$1"
TARGET_USER="$2"
IMAGE_TAG="$3"

ssh "$TARGET_USER@$TARGET_HOST" "
  cd /opt/sdt &&
  docker login ghcr.io -u '${GITHUB_ACTOR}' -p '${GHCR_TOKEN}' &&
  docker pull '$IMAGE_TAG' &&
  sed -i 's|image: ghcr.io.*/sdt:.*|image: $IMAGE_TAG|' docker-compose.yml &&
  sudo systemctl restart sdt-app &&
  sudo systemctl status sdt-app --no-pager
"