#!/usr/bin/env bash
# Script to demonstrate how to interact with security-playground

# Robust NodePort target: honor a pre-set NODE_IP, else the first READY node's internal IP; never silently empty (see workshop node-IP note).
NODE_IP="${NODE_IP:-$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status} {.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}' 2>/dev/null | awk '$1=="True"{print $2; exit}')}"
[ -z "$NODE_IP" ] && { echo "ERROR: could not resolve a Ready node IP via kubectl — run 'sudo bash' so KUBECONFIG is set (or export NODE_IP=<node internal IP>)." >&2; exit 1; }
NODE_PORT=30000
HELLO_NAMESPACE=hello

echo "Trying to reach hello-server from security-playground"
echo "---"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=curl --connect-timeout 5 http://hello-server.$HELLO_NAMESPACE.svc:8080"
