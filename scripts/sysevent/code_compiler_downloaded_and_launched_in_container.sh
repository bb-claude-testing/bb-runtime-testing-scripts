#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mThis rule detects the downloading and execution of code compilers in containers, a behavior often associated with malicious attempts to compile and run unauthorized code within a system. An attacker could potentially exploit this to introduce and execute malicious code in a container, bypassing normal application deployment controls and potentially compromising the host system or other resources.\033[m"
gcc cgminer.cpp -o cgminer
