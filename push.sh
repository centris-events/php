#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "No tag supplied. Please supply a tag."
    echo "Example: ./push.sh 2.1.0"
    exit 1
fi

docker push myworkupapp/docker-php:$1