#! /bin/bash

SERVICE_IP=$(ip addr show ens192 | grep "inet " | sed "s/ *inet//" | sed "s/\/26.*//" | xargs)
ADMIN_IP=$(ip addr show ens160 | grep "inet " | sed "s/ *inet//" | sed "s/\/26.*//" | xargs)
yum install xinetd -y
yum install epel-release -y
yum install debootstrap perl libvirt -y
yum install lxc lxc-templates -y
yum install bridge-utils -y
yum install net-tools -y
yum install /usr/bin/lxc-ls -y
systemctl enable lxc.service
systemctl start lxc.service
systemctl start libvirtd

# Listen only on main ip!
echo "ListenAddress $SERVICE_IP" >> /etc/ssh/sshd_config
echo "ListenAddress $ADMIN_IP"   >> /etc/ssh/sshd_config
service sshd restart

# Server.py

#firewall-cmd --zone=public --add-port=8080/tcp
#yum install python-bottle -y 
#yum install python-yaml -y 
