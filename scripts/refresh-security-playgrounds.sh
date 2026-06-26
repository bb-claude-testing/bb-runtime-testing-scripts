#!/bin/bash
# Reset the security-playground namespaces between Module 1 runs:
# clear the drift artifact + all pods (their Deployments recreate them fresh),
# and remove any NetworkPolicies generated in Module 6. Safe to re-run.
kubectl delete deployment nefarious-workload -n security-playground --ignore-not-found
kubectl delete --all pods --namespace=security-playground
kubectl delete --all pods --namespace=security-playground-restricted
kubectl delete -f ./generated-network-policy.yml --ignore-not-found 2>/dev/null || true
kubectl delete -f ./generated-network-policy2.yml --ignore-not-found 2>/dev/null || true
