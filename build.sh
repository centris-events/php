#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "No tag supplied. Please supply a tag."
    echo "Example: ./build.sh 2.1.0"
    exit 1
fi

docker build -t centris/php:$1 .