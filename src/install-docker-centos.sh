#!/bin/bash

# 环境: aws ec2
# 系统: centos

sudo yum update -y
sudo yum install git -y
sudo amazon-linux-extras install docker -y
sudo systemctl enable docker
sudo systemctl start docker
