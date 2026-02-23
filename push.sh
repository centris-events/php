#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "No tag supplied. Please supply a tag."
    echo "Example: ./push.sh 2.1.0"
    exit 1
fi

set -euo pipefail

TAG="$1"
BUILDER_NAME="centris-multiarch"
REGISTRY_HOST="7f0b2mhv.eu-west-par.container-registry.ovh.net"
IMAGE_NAME="${PHP_BASE_IMAGE_NAME:-centris/php}"
IMAGE_REPO="${IMAGE_REPO:-${REGISTRY_HOST}/${IMAGE_NAME}}"

if ! docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
  docker buildx create --name "$BUILDER_NAME" --use
else
  docker buildx use "$BUILDER_NAME"
fi

docker buildx inspect --bootstrap >/dev/null

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag "${IMAGE_REPO}:${TAG}" \
  --push \
  .
