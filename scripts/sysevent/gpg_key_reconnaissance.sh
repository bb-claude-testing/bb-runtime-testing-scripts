#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mDetects reconnaissance attempts that try to locate GPG security keys using 'find' or 'grep' commands. An attacker could potentially identify and steal GPG security keys to gain unauthorized access to encrypted communications or files.\033[m"
find / -name "*.gpg" -o -name "secring.gpg" -o -name "pubring.gpg" 2>/dev/null | head -5
gpg --list-keys 2>/dev/null
gpg --list-secret-keys 2>/dev/null
