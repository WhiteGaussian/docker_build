#!/usr/bin/env bash
set -x  # Debug
set -e   # Exit when error

#===============Build Cling/Grpc=================
USER=`whoami`
USER_ID=`id -u ${USER}`
USER_GROUP=`id -g ${USER}`
DOCKERFILE_PATH=docker/sdk-build/
DOCKER_TAG=`cat ${DOCKERFILE_PATH}Dockerfile | sha1sum | awk '{print substr($1,0,11);}'`
DOCKER_NAME_BASE=docker.xinuolc.com/sdk/clingenv/sdk-build-docker
WORKING_DIR=`pwd`
SDK_OPTS="$@"
function create_user_docker(){
    echo "Create User Docker $DOCKER_NAME_BASE:$DOCKER_TAG"
    docker build --no-cache -t $DOCKER_NAME_BASE:$DOCKER_TAG $DOCKERFILE_PATH
}

function prepare_docker(){
    echo "Docker $DOCKER_NAME_BASE:$DOCKER_TAG"
    docker inspect --type image $DOCKER_NAME_BASE:$DOCKER_TAG &> /dev/null || create_user_docker
}

function build_debian(){
    echo "current build options : $SDK_OPTS "
    docker run --rm -v $WORKING_DIR/:/cling $DOCKER_NAME_BASE:$DOCKER_TAG bash -c "cd /cling/xinuolc-sdk ; export $SDK_OPTS; dpkg-buildpackage -b -uc -us "
}

# Pull from gitlab
#prepare_docker
build_debian

