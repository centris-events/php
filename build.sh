#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "No tag supplied. Please supply a tag."
    echo "Example: ./build.sh 2.1.0"
    exit 1
fi

# Build for host architecture (arm64 on Apple Silicon, amd64 on Intel/CI) so the image runs natively
ARCH=$(uname -m)
[ "$ARCH" = x86_64 ] && ARCH=amd64 || ARCH=arm64
docker build --platform linux/$ARCH -t centris/php:$1 .