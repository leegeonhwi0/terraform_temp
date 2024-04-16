#!/bin/bash -x
sudo su -
yum install libreswan -y
echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter = 0" >>/etc/sysctl.conf
echo "net.ipv4.conf.default.accept_source_route = 0" >>/etc/sysctl.conf

sysctl -p
service network restart
