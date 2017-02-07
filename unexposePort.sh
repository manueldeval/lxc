#! /bin/bash


CONTAINTER_NAME=""
PORT=""
ALL=""

while getopts "n:p:a" opt; do
  case $opt in
    n)
      CONTAINER_NAME=$OPTARG
      ;;
    p)
      PORT=$OPTARG
      ;;
    a)
      ALL=YES
      ;;
  esac
done

[[ $CONTAINER_NAME == "" ]] && echo "The container name can not be empty" && exit 1
if [[ $PORT != "" ]]; then 
  echo "unexpose port $PORT"
  $(rm -f /etc/xinetd.d/lxc_${CONTAINER_NAME}_${PORT})
fi
if [[ $ALL != "" ]]; then 
  echo "unexpose all"
  $(rm -f /etc/xinetd.d/lxc_${CONTAINER_NAME}_*)
fi

service xinetd restart




