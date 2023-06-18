#!/usr/bin/env bash
DOCKERFILE_PATH=./
DOCKER_TAG=`cat ${DOCKERFILE_PATH}Dockerfile | sha1sum | awk '{print substr($1,0,11);}'`
DOCKER_NAME_BASE=wifienv
docker build --no-cache -t $DOCKER_NAME_BASE:$DOCKERFILE_PATH
