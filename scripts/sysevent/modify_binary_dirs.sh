#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mAn attempt to modify any file below a set of binary directories\033[m"
rm -f /bin/id2 ; cp /bin/id /bin/id2 2>/dev/null; /bin/id2 2>/dev/null
