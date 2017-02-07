#! /bin/bash


CONTAINTER_NAME=""
CONTAINTER_IP=""
PORT=""
EXTERNAL_PREFIX="192.168.0."

while getopts "n:p:" opt; do
  case $opt in
    n)
      CONTAINER_NAME=$OPTARG
      ;;
    p)
      PORT=$OPTARG
      ;;
  esac
done

[[ $CONTAINER_NAME == "" ]] && echo "The container name can not be empty" && exit 1
[[ $PORT == "" ]] && echo "The port can not be empty" && exit 1

#==================
# Container name
#==================
# Check if the container name already exists
RES=$(lxc-info -n $CONTAINER_NAME 2> /dev/null)
[ $? -ne 0 ] && echo "The container $CONTAINER_NAME does not exists" && exit 1

INTERNAL_CONTAINER_IP=$(cat /var/lib/lxc/$CONTAINER_NAME/config | grep "lxc.network.ipv4 =" | sed "s/.*=//" | sed "s/\/.*//" | xargs)
LAST_DIGIT=$(echo $INTERNAL_CONTAINER_IP | cut -f4 -d.)
EXTERNAL_CONTAINER_IP=${EXTERNAL_PREFIX}${LAST_DIGIT}

echo "$EXTERNAL_CONTAINER_IP:$PORT => $INTERNAL_CONTAINER_IP:$PORT"

[ -f /etc/xinetd.d/lxc_${CONTAINER_NAME}_${PORT} ] && echo "The port is already forwarded" && exit 1
cat > /etc/xinetd.d/lxc_${CONTAINER_NAME}_${PORT} <<EOL
service lxc_${CONTAINER_NAME}_${PORT}
{
        disable         = no
        type            = UNLISTED
        socket_type     = stream
        protocol        = tcp
        user            = nobody
        wait            = no
        redirect        = $INTERNAL_CONTAINER_IP $PORT
        bind            = $EXTERNAL_CONTAINER_IP
        port            = $PORT
}
EOL

service xinetd restart



