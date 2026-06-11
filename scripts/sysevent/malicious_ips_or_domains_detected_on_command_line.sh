#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mMalicious commands detected in pod or host. The rule was triggered by the IP or domains in proc_cmdline\033[m"
curl -fsSL tst.xmr.pool.minergate.com >/dev/null
