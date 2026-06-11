#!/bin/bash

echo -e `date +"%Y-%m-%d %H:%M:%S"` "\e[92mThis rule detects steps indicative of extracting kubernetes service account tokens after successfully spawning a shell. Attackers may steal service account tokens in a running pod to access the Kubernetes API, cloud resources, or secrets managers. Unauthorized access to these tokens can lead to full cluster compromise or cloud account breaches.\033[m"
TOKEN_PATH=/var/run/secrets/kubernetes.io/serviceaccount/token
if [ ! -f "$TOKEN_PATH" ]; then
    mkdir -p "$(dirname $TOKEN_PATH)"
    echo "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.stub" > "$TOKEN_PATH"
fi
cat "$TOKEN_PATH"
