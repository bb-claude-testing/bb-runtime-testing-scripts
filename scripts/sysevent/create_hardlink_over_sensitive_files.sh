#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mDetect a hardlink being created over sensitive files\033[m"
ln -f /etc/shadow /root/shadowfile
