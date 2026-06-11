#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mThis rule detects attempts to terminate recognized malicious processes. This is often seen within real attacks during which an adversary firstly tries to remove all competitive malicious software on a newly compromised system, ensuring that only their own will be running.\033[m"
pastebin 1000 &
pkill -f pastebin
