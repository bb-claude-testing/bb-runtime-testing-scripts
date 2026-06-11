#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mAttempt to enumerate SUID binaries. This typically occurs as part of reconaissance on a compromised machine, where an attacker is looking to escalate privileges.\033[m"
su - recon -c "find / -perm -4000 -type f ! -path "/dev/*" 2>/dev/null"
