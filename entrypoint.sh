#!/usr/bin/env bash
# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or
# fallback

USER_ID=${LOCAL_USER_ID:-9001}
USER_NAME=${LOCAL_USER_NAME:user}
GROUP_ID=${LOCAL_GROUP_ID:-9001}
GROUP_NAME=${LOCAL_GROUP_NAME:group}

#echo "Starting with uid=$USER_ID($USER_NAME) gid=$GROUP_ID($GROUP_NAME)"

groupadd $GROUP_NAME -g $GROUP_ID
useradd $USER_NAME --shell /bin/bash -u $USER_ID -o -c "" -g $GROUP_NAME --no-create-home  > /dev/null

export HOME=/home/$USER_NAME
export JAVA_HOME
ln -s /usr/bin/python3 /usr/bin/python

# hook for operations which need root permission
test -f ./hook.bash && source ./hook.bash

exec /bin/gosu $USER_NAME "$@"
