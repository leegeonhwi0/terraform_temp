#!/bin/bash -x
sudo yum install ansible -y
ansible --version
sudo yum install python3-pip -y
sudo pip3 install boto3
sudo pip3 install --upgrade awscli