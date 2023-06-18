#!/bin/bash

USER=`whoami`
USER_ID=`id -u ${USER}`
USER_GROUP=`id -g ${USER}`
DOCKERFILE_PATH=docker/cling-grpc-build/
DOCKER_TAG=`cat ${DOCKERFILE_PATH}Dockerfile | sha1sum | awk '{print substr($1,0,11);}'`
DOCKER_NAME_BASE=docker.xinuolc.com/sdk/clingenv/cling-grpc-build
WORKING_DIR=`pwd`
create_user_docker(){
    echo "Create User Docker $DOCKER_NAME_BASE:$DOCKER_TAG"
    docker build --no-cache -t $DOCKER_NAME_BASE:$DOCKER_TAG $DOCKERFILE_PATH
}

prepaer_docker(){
    echo "Docker $DOCKER_NAME_BASE:$DOCKER_TAG"
    docker inspect --type image $DOCKER_NAME_BASE:$DOCKER_TAG &> /dev/null || create_user_docker
}

run_docker(){
    docker container inspect sdkdocker-$USER &> /dev/null
    if [ $? -eq 0 ]; then
        docker container rm sdkdocker-$USER
    fi

    docker run --rm --privileged \
        --name sdkdocker-$USER \
        -v $WORKING_DIR/clingenv_auto:/cling/clingenv \
        -v $WORKING_DIR/mock:/mock \
        -v $WORKING_DIR/mock/xlc_diag:/mock/xlc_diag \
        -v $WORKING_DIR/mock/machine.conf:/etc/machine.conf \
        --env PATH=/cling/clingenv/tools/cling:/cling/clingenv/tools/sdk_asicsim:/cling/clingenv/tools/sdk_asicsim/tests:/cling/clingenv/tools/xlc_shell:$PATH \
        $DOCKER_NAME_BASE:$DOCKER_TAG bash -C /cling/clingenv/tools/sdk_asicsim/run_asicsim.sh

}

prepaer_docker
run_docker

