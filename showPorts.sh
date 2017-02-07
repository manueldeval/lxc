#! /bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/containers.conf

CONTAINTER_NAME=""
CONTAINTER_IP=""

while getopts "n:p:" opt; do
  case $opt in
    n)
      CONTAINER_NAME=$OPTARG
      ;;
  esac
done

[[ $CONTAINER_NAME == "" ]] && echo "The container name can not be empty" && exit 1

#==================
# Container name
#==================
# Check if the container name already exists
RES=$(lxc-info -n $CONTAINER_NAME 2> /dev/null)
[ $? -ne 0 ] && echo "The container $CONTAINER_NAME does not exists" && exit 1

ls /etc/xinetd.d/lxc_${CONTAINER_NAME}_* | sed "s/.*_//"

