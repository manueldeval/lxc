#! /bin/bash

CONTAINTER_NAME=""
ITF_TO_ALIAS=enp0s3


while getopts "n:i:" opt; do
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

#==================
# Unexpose all
#===================
echo "Unexpose all ports"
$(rm -f /etc/xinetd.d/lxc_${CONTAINER_NAME}_*)
service xinetd restart

echo "Remove ip alias"
INTERNAL_CONTAINER_IP=$(cat /var/lib/lxc/$CONTAINER_NAME/config | grep "lxc.network.ipv4 =" | sed "s/.*=//" | sed "s/\/.*//" | xargs)
LAST_DIGIT=$(echo $INTERNAL_CONTAINER_IP | cut -f4 -d.)
ALIAS_NAME="${ITF_TO_ALIAS}:${LAST_DIGIT}"
ifdown $ALIAS_NAME
rm /etc/sysconfig/network-scripts/ifcfg-$ALIAS_NAME

#==================
# Destroy container
#===================
echo "Destroy container"
$(lxc-destroy -n ${CONTAINER_NAME} -f)

