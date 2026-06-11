#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mDetect attempt to read mem or maps file in process folder to get credentials in plaintext\033[m"
cat /proc/$$/maps > /tmp/memory_dump
