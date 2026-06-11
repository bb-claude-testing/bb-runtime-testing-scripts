#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mAttempt to tamper with security software detected\033[m"
sysctl kernel.nmi_watchdog=0 2>/dev/null
