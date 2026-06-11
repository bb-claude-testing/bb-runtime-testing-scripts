#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mMiners typically specify the mining pool to connect to with a URI that begins with 'stratum+tcp' or 'stratum+ssl'\033[m"
cgminer -o stratum+tcp://uk1.ghash.io:3333 -u username.worker -p getmecoins 
