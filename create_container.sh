#! /bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/containers.conf

CONTAINTER_NAME=""
CONTAINTER_IP=""
START="FALSE"

while getopts "n:i:s" opt; do
  case $opt in
    n)
      CONTAINER_NAME=$OPTARG
      ;;
    i)
      CONTAINER_IP=$OPTARG
      ;;
    s)
      START="TRUE"
  esac
done

[[ $CONTAINER_NAME == "" ]] && echo "The container name can not be empty" && exit 1
[[ $CONTAINER_IP == "" ]] && echo "The container ip can not be empty" && exit 1

#==================
# Container name
#==================
# Check if the container name already exists
RES=$(lxc-info -n $CONTAINER_NAME 2> /dev/null)
[ $? -eq 0 ] && echo "One container with name $CONTAINER_NAME already exists" && exit 1

#==================
# Requested IP
#==================
# The ip must be in the external net
[[ $CONTAINER_IP != $EXTERNAL_PREFIX* ]] && echo "The ip $CONTAINER_IP must start with $EXTERNAL_PREFIX" && exit 1
[[ $CONTAINER_IP == ${GATEWAY} ]] && echo "The ip $CONTAINER_IP must not use the gateway ip" && exit 1
[[ $CONTAINER_IP == ${BROADCAST} ]] && echo "The ip $CONTAINER_IP must not use the broadcast ip" && exit 1
# Check if the ip is available
RES=$(ip addr show | grep "inet " | sed "s/.*inet //" | sed "s/\/.*//" | grep $CONTAINER_IP)
[ $? -eq 0 ] && echo "The ip $CONTAINER_IP is already in use." && exit 1
# Get Last digit

#=================
# Container creation
#=================
LAST_DIGIT=$(echo $CONTAINER_IP | cut -f4 -d.)
EXTERNAL_CONTAINER_IP=$CONTAINER_IP
INTERNAL_CONTAINER_IP=${INTERNAL_PREFIX}${LAST_DIGIT}
CONTAINER_BASE="/var/lib/lxc/$CONTAINER_NAME/"
CONTAINER_ROOTFS="$CONTAINER_BASE/rootfs/"

echo "About to create container: $CONTAINER_NAME"
echo "External IP: $EXTERNAL_CONTAINER_IP"
echo "Internal IP: $INTERNAL_CONTAINER_IP"

RET=$(lxc-create -n $CONTAINER_NAME -t centos 2> /dev/null)
[ $? -ne 0 ] && echo "Error during the creation." && exit 1

#=================
# Configuration
#=================
echo "Setting new password"
chroot /var/lib/lxc/${CONTAINER_NAME}/rootfs passwd &> /dev/null << EOF
$PASSWORD
$PASSWORD
EOF

echo "Change container config file"
echo "lxc.kmsg = 0" >> $CONTAINER_BASE/config
echo "lxc.network.ipv4 = $INTERNAL_CONTAINER_IP/24" >> $CONTAINER_BASE/config
echo "lxc.network.ipv4.gateway = auto" >> $CONTAINER_BASE/config

echo "Change eth0 container config file"
sed -i s/BOOTPROTO.*/BOOTPROTO=static/ $CONTAINER_ROOTFS/etc/sysconfig/network-scripts/ifcfg-eth0
echo "IPADDR=$INTERNAL_CONTAINER_IP" >> $CONTAINER_ROOTFS/etc/sysconfig/network-scripts/ifcfg-eth0
echo "NETMASK=255.255.255.0" >> $CONTAINER_ROOTFS/etc/sysconfig/network-scripts/ifcfg-eth0
echo "GATEWAY=$GATEWAY" >> $CONTAINER_ROOTFS/etc/sysconfig/network-scripts/ifcfg-eth0

echo "Change sshd container config file"
sed -i "s/GSSAPIAuthentication yes/GSSAPIAuthentication no/" $CONTAINER_ROOTFS/etc/ssh/sshd_config
echo "UseDNS no" >> $CONTAINER_ROOTFS/etc/ssh/sshd_config

echo "Add proxy"
cat >> $CONTAINER_ROOTFS/etc/bashrc << EOL
export http_proxy=$HTTP_PROXY
export https_proxy=$HTTP_PROXY
export HTTP_PROXY=$HTTP_PROXY
export HTTPS_PROXY=$HTTP_PROXY
EOL

#===================
# Create ETH ALIAS
#===================
ALIAS_NAME="${ITF_TO_ALIAS}:${LAST_DIGIT}"
ETH_ALIAS_FILE=/etc/sysconfig/network-scripts/ifcfg-$ALIAS_NAME
echo "Creation of alias interface: $ALIAS_NAME"

cat > $ETH_ALIAS_FILE <<EOL
TYPE="Ethernet"
BOOTPROTO="static"
NM_CONTROLLED="no"
IPADDR="$EXTERNAL_CONTAINER_IP"
NETMASK="$NETMASK"
GATEWAY="$GATEWAY"
DEFROUTE="yes"
PEERDNS="yes"
PEERROUTES="yes"
IPV4_FAILURE_FATAL="no"
IPV6INIT="yes"
IPV6_AUTOCONF="yes"
IPV6_DEFROUTE="yes"
IPV6_PEERDNS="yes"
IPV6_PEERROUTES="yes"
IPV6_FAILURE_FATAL="no"
IPV6_ADDR_GEN_MODE="stable-privacy"
NAME="${ITF_TO_ALIAS}:${LAST_DIGIT}"
DEVICE="${ITF_TO_ALIAS}:${LAST_DIGIT}"
ONBOOT="yes"
EOL

ifup $ALIAS_NAME

echo "Expose port 22"
$DIR/exposePort.sh -n $CONTAINER_NAME -p 22

if [[ $START == "TRUE" ]]; then
  echo "Starting container"
  lxc-start -n $CONTAINER_NAME -d
fi



