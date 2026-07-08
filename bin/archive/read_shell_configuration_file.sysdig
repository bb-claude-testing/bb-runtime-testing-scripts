#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mThis rule detects attempts of non-shell programs reading shell configuration files, a common practice among attackers to extract sensitive information or gain insights into the system's configuration. For instance, an attacker could leverage the obtained configuration information to identify privileged accounts or vulnerable system settings, potentially aiding in lateral movement or privilege escalation.\033[m"
cat /etc/profile >/tmp/profile
