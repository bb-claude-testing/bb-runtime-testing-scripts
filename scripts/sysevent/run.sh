#!/bin/bash
# run.sh — fire sysevent runtime-detection tests ON DEMAND, from the bastion,
# inside the dedicated `sysevent` pod (via `kubectl exec`).
#
# The sysevent Deployment (k8s-manifests/24-sysevent-deployment.yaml) starts
# PAUSED, so it never fires tests on its own — this script is how you trigger
# them. Each test runs the matching /home/eval/bin/<name>.sysdig in the pod,
# which is byte-for-byte identical to the *.sh files in this folder.
#
# Usage (run from the bastion, with kubectl configured for the cluster):
#   ./run.sh list                          # list every available test
#   ./run.sh <test_name>                   # run ONE test
#                                          #   e.g. ./run.sh reverse_shell_detected_python
#   ./run.sh all                           # run every single-action test (skips the 2 chains)
#   ./run.sh chains                        # run only the 7-stage + 10-stage attack chains
#   ./run.sh everything                    # run all single tests AND both chains
#
# Options:
#   SYSEVENT_NS=<ns>  ./run.sh ...         # override namespace (default: sysevent)
#
# After running, watch the detections light up in Sysdig Secure
# (Threats / Events), filtered to kubernetes.namespace.name = "sysevent".
set -euo pipefail

NS="${SYSEVENT_NS:-sysevent}"
EDIR=/home/eval/bin
CHAINS=(simulated_attack_chain k8s_cluster_takeover_and_cryptominer)

die() { echo "ERROR: $*" >&2; exit 1; }

command -v kubectl >/dev/null 2>&1 || die "kubectl not found on PATH."

POD=$(kubectl get pod -n "$NS" -l app=sysevent \
        -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
[ -n "$POD" ] || die "no running sysevent pod in namespace '$NS'.
  Is the Deployment applied?  kubectl get pods -n $NS"

# Every test name available in the pod (without the .sysdig extension).
all_tests() {
  kubectl exec -n "$NS" "$POD" -- bash -c "ls -1 $EDIR/*.sysdig 2>/dev/null" \
    | xargs -n1 basename | sed 's/\.sysdig$//'
}

is_chain() { local t="$1"; for c in "${CHAINS[@]}"; do [ "$t" = "$c" ] && return 0; done; return 1; }

run_one() {
  local t="${1%.sysdig}"; t="${t%.sh}"
  echo "=== [$(date +%H:%M:%S)] running: $t ==="
  # Tests intentionally do "bad" things and often exit non-zero — that is fine,
  # the syscalls Sysdig detects have already happened. Never abort on failure.
  kubectl exec -n "$NS" "$POD" -- bash "$EDIR/$t.sysdig" || \
    echo "  (test exited non-zero — usually expected)"
}

cmd="${1:-help}"
case "$cmd" in
  list|ls)
    echo "sysevent tests available in pod '$POD' (namespace '$NS'):"
    all_tests | sed 's/^/  /'
    ;;
  all)
    while read -r t; do is_chain "$t" && continue; run_one "$t"; done < <(all_tests)
    echo "=== done: all single-action tests (chains skipped — use './run.sh chains') ==="
    ;;
  chains|chain)
    for c in "${CHAINS[@]}"; do run_one "$c"; done
    echo "=== done: multi-stage attack chains ==="
    ;;
  everything|all-including-chains)
    while read -r t; do run_one "$t"; done < <(all_tests)
    echo "=== done: every test ==="
    ;;
  help|-h|--help)
    sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
    ;;
  *)
    # Anything else is treated as a single test name.
    if all_tests | grep -qx "${cmd%.sysdig}"; then
      run_one "$cmd"
    else
      die "unknown test '$cmd'. Run './run.sh list' to see valid names."
    fi
    ;;
esac
