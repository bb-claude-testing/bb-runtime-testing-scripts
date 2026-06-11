#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mThis rule detects attempts to steal Azure Credentials using find or grep commands. An attacker could obtain sensitive Azure data, such as private keys, leading to unauthorized access to critical resources.\e[m"
find /root azure.json 2> /dev/null
