## DOCKER PHP IMAGE

How to build the image:

    docker build . -t myworkupapp/docker-php:<tag>

How to publish the image:

    ./push.sh <tag>

`push.sh` publishes a multi-arch image manifest for `linux/amd64` and `linux/arm64`.
