#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mAn attempt is made to read any sensitive file (e.g. files containing user/password/authentication information). Exceptions are made for known trusted programs\033[m"
cat /etc/shadow >/tmp/shadowcopy
rm /tmp/shadowcopy
