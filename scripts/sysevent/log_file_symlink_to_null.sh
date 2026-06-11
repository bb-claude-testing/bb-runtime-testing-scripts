#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mSymlinks created over log files by process ln with parent bash under user root \033[m"
cd /var/log
[ -e auth.log ] && rm auth.log
ln -s /dev/null auth.log
