#!/bin/bash
check_status() {
    if [ $1 != 0 ]; then
        echo
        echo $2
        exit $1
    fi
}
DOCKER_REPOSITORY=renaalve
IMAGE_NAME=aws-lambda-layer-kubectl
IMAGE_TAG=latest

docker build -f Dockerfile --no-cache -t ${DOCKER_REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG} .
check_status $? 'An error occurred when generating docker image.'

docker cp $(docker run -d ${DOCKER_REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG}):/root/lambda-layer.zip .
check_status $? 'An error occurred when getting lambda-layer.zip file.'