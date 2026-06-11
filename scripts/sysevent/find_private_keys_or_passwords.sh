#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mThis rule detects activities searching for private keys or passwords, alerting on potential credential exposure. An attacker could gain unauthorized access to sensitive information such as SSH keys, compromising system security.\033[m"
find /root -name "id_rsa"
