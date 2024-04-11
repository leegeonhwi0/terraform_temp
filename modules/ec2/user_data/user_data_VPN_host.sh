#!/bin/bash -x
sudo su -
yum install libreswan -y
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.eth0.send_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.accept_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.eth0.accept_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.ip_vti0.rp_filter = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.eth0.rp_filter = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter = 0" >> /etc/sysctl.conf
sysctl -p
service network restart