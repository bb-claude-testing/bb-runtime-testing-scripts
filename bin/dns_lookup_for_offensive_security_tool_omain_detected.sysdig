#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mThis rule detects DNS lookups to domains usually contacted during security testing or known penetration testing repositories.\033[m"
tempdn=`shuf -i 0-9 -n 6 --repeat | tr -d '\n'`
curl -o /tmp/dns_lookup $tempdn.oastify.com 
