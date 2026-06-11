#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mThis rule detects unauthorized attempts to access the EC2 Instance Metadata Service from a container. An attacker could gain sensitive information about the AWS infrastructure, such as security credentials, which may lead to unauthorized access and potential data breaches.\033[m"
curl -m2 http://169.254.169.254/latest/meta-data/iam/security-credentials/$(curl -m2 http://169.254.169.254/latest/meta-data/iam/security-credentials/)

