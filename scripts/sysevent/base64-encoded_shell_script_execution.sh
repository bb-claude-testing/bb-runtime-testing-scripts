#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mBase64-encoded Shell script executions as part of a set of command line arguments.\033[m"
sh -c "echo 'IyEvYmluL3NoCmVjaG8gIkhlbGxvISIK'|base64 -d" >/dev/null
