#!/bin/bash

USER=`whoami`

show_usage(){
    echo "Usage: xlc-sim.sh [start|stop|EXEC_CMD]"
}
if [ "$#" -eq 0 ]
then
    show_usage
    exit 1
fi

case "$1" in
    start)
        ./docker/cling-grpc-build/docker_run_mock.sh &
        ;;
    stop)
        docker exec -it sdkdocker-$USER killall sdk_asicsim
        docker stop sdkdocker-$USER
        ;;
    *) 
        docker exec -it sdkdocker-$USER $@
        ;;
esac