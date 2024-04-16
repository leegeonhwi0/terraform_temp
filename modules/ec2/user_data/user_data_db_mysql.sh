#!/bin/bash -x
sudo yum update
sudo systemctl start mysql
sudo systemctl enable mysql
