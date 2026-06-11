#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mThis rule detects processes attempting to clear bulk data from the disk, such as 'shred' or 'mkfs', potentially erasing sensitive information. An attacker could perform data destruction by running these commands to cover their tracks and hinder forensic investigations\033[m"
echo ''> ~/.bash_history
shred ~/.bash_history
