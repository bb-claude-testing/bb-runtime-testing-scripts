#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mDetected reconnaissance script executing\033[m"
curl -fsSL https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh -o /tmp/LinEnum.sh 2>/dev/null
chmod +x /tmp/LinEnum.sh
bash /tmp/LinEnum.sh -r /tmp/linenum_report -d 1 >/dev/null 2>&1
rm -f /tmp/LinEnum.sh /tmp/linenum_report
