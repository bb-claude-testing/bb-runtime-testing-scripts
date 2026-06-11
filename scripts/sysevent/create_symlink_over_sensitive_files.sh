#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mA symbolic link of a sensitive file is created\033[m"
ln -sf /etc/shadow /tmp/marcel
sleep 1
rm /tmp/marcel
