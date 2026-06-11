#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mExecuting 'Modify ld.so.preload'. File /etc/ld.so.preload has been opened for writing. Possible hidden process attempt\033[m"
echo '' > /etc/ld.so.preload
