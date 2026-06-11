#!/bin/bash
# run.sh — fire sysevent runtime-detection tests ON DEMAND, from the bastion,
# inside the dedicated `sysevent` pod (via `kubectl exec`).
#
# The sysevent Deployment (k8s-manifests/24-sysevent-deployment.yaml) starts
# PAUSED, so it never fires tests on its own — this script is how you trigger
# them. Each test runs the matching /home/eval/bin/<name>.sysdig in the pod,
# which is byte-for-byte identical to the *.sh files in this folder.
#
# Usage (run from the bastion, as root, with kubectl configured):
#   ./run.sh list                          # list every available test
#   ./run.sh <test_name>                   # run ONE test
#                                          #   e.g. ./run.sh reverse_shell_detected_python
#   ./run.sh all                           # run every single-action test (skips the 2 chains)
#   ./run.sh chains                        # run only the 7-stage + 10-stage attack chains
#   ./run.sh everything                    # run all single tests AND both chains
#   ./run.sh help                          # show this help (no pod needed)
#
# Options (environment variables):
#   SYSEVENT_NS=<ns>      namespace of the sysevent pod   (default: sysevent)
#   TEST_TIMEOUT=<secs>   max seconds per single test     (default: 45)
#   CHAIN_TIMEOUT=<secs>  max seconds per multi-stage chain (default: 300)
#
# After running, watch the detections light up in Sysdig Secure
# (Threats / Events), filtered to kubernetes.namespace.name = "sysevent".
set -euo pipefail

NS="${SYSEVENT_NS:-sysevent}"
EDIR=/home/eval/bin
CHAINS=(simulated_attack_chain k8s_cluster_takeover_and_cryptominer)
TEST_TIMEOUT="${TEST_TIMEOUT:-45}"      # per single test
CHAIN_TIMEOUT="${CHAIN_TIMEOUT:-300}"   # per multi-stage chain
POD=""

die()  { echo "ERROR: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
usage(){ awk 'NR==1{next} /^#/{sub(/^# ?/,"");print;next} {exit}' "$0"; }

have kubectl || die "kubectl not found on PATH."

# Find the sysevent pod and wait until it's Ready, so this works even right
# after a fresh deploy. Only called by commands that actually touch the pod.
ensure_pod() {
  [ -n "$POD" ] && return 0
  kubectl get ns "$NS" >/dev/null 2>&1 \
    || die "namespace '$NS' not found — is the sysevent Deployment applied?  (kubectl get pods -n $NS)"
  echo "Waiting for the sysevent pod to be ready in namespace '$NS'..."
  kubectl wait --for=condition=Ready pod -l app=sysevent -n "$NS" --timeout=120s >/dev/null 2>&1 \
    || die "the sysevent pod isn't Ready yet.  Check:  kubectl get pods -n $NS"
  POD=$(kubectl get pod -n "$NS" -l app=sysevent -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  [ -n "$POD" ] || die "couldn't find a sysevent pod in namespace '$NS'."
  echo "Using pod: $POD"
}

# Every test name available in the pod (without the .sysdig extension).
all_tests() {
  kubectl exec -n "$NS" "$POD" -- bash -c "ls -1 $EDIR/*.sysdig 2>/dev/null" \
    | xargs -n1 basename | sed 's/\.sysdig$//'
}

is_chain() { local t="$1"; for c in "${CHAINS[@]}"; do [ "$t" = "$c" ] && return 0; done; return 1; }

# Run a single test, capped by a timeout so nothing can hang the demo. The
# reverse-shell tests spawn an interactive /bin/sh over a socket; their
# detection fires instantly, but the shell can linger — the timeout cleans up.
run_one() {
  local t="${1%.sysdig}"; t="${t%.sh}"
  local to="$TEST_TIMEOUT"; is_chain "$t" && to="$CHAIN_TIMEOUT"
  echo "=== [$(date +%H:%M:%S)] running: $t  (max ${to}s) ==="
  local rc=0
  if have timeout; then
    timeout "$to" kubectl exec -n "$NS" "$POD" -- bash "$EDIR/$t.sysdig" || rc=$?
  else
    kubectl exec -n "$NS" "$POD" -- bash "$EDIR/$t.sysdig" || rc=$?
  fi
  if [ "$rc" -eq 124 ]; then
    echo "  (stopped at ${to}s — expected for shell-spawning tests; the detection already fired)"
  elif [ "$rc" -ne 0 ]; then
    echo "  (test exited non-zero — usually expected for an attack simulation)"
  fi
  return 0
}

cmd="${1:-help}"
case "$cmd" in
  help|-h|--help)
    usage
    ;;
  list|ls)
    ensure_pod
    echo "sysevent tests available (namespace '$NS'):"
    all_tests | sed 's/^/  /'
    ;;
  all)
    ensure_pod
    while read -r t; do is_chain "$t" && continue; run_one "$t"; done < <(all_tests)
    echo "=== done: all single-action tests (chains skipped — use './run.sh chains') ==="
    ;;
  chains|chain)
    ensure_pod
    for c in "${CHAINS[@]}"; do run_one "$c"; done
    echo "=== done: multi-stage attack chains ==="
    ;;
  everything|all-including-chains)
    ensure_pod
    while read -r t; do run_one "$t"; done < <(all_tests)
    echo "=== done: every test ==="
    ;;
  *)
    ensure_pod
    if all_tests | grep -qx "${cmd%.sysdig}"; then
      run_one "$cmd"
    else
      die "unknown test '$cmd'.  Run './run.sh list' to see valid names."
    fi
    ;;
esac
