

#!/bin/bash

# Script versiyonu ve son güncelleme tarihi
VERSION="2.0.0"
LAST_UPDATED="2025-01-09"
AUTHOR="mericalp"

# Strict mode ve hata yakalama
set -euo pipefail
trap 'echo "Error on line $LINENO"' ERR

# Fonksiyon: Deployment durumunu kontrol et
check_deployment_status() {
    local deploy_name=$1
    local namespace=$2
    local timeout=300

    echo "Checking rollout status for $deploy_name..."
    if ! kubectl rollout status deployment/$deploy_name -n $namespace --timeout=${timeout}s; then
        echo "Deployment failed! Rolling back..."
        kubectl rollout undo deployment/$deploy_name -n $namespace
        return 1
    fi
}

# Fonksiyon: Namespace security policies uygula
apply_security_policies() {
    local namespace=$1
    
    # Network Policy
    kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: $namespace
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

    # Resource Quota
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-resources
  namespace: $namespace
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
EOF
}

# Ana script başlangıcı
echo "Starting Enterprise Kubernetes Deployment (v${VERSION})"
echo "Author: ${AUTHOR}"
echo "Last Updated: ${LAST_UPDATED}"

# Cluster health check
if ! kubectl get nodes &>/dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster"
    exit 1
fi

# Namespace oluştur ve security policies uygula
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
apply_security_policies production
