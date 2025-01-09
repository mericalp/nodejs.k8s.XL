#!/bin/bash
# scripts/create-talos-cluster.sh

# Değişkenler
CLUSTER_NAME="mern-production"
CONTROL_PLANE_IP="192.168.1.10"
WORKER_NODES=("192.168.1.11" "192.168.1.12" "192.168.1.13")

# Cluster yapılandırması oluştur
talosctl gen config $CLUSTER_NAME https://$CONTROL_PLANE_IP:6443

# Control plane başlat
talosctl apply-config \
  --insecure \
  --nodes $CONTROL_PLANE_IP \
  --file controlplane.yaml

# Worker node'ları başlat
for node in "${WORKER_NODES[@]}"; do
  talosctl apply-config \
    --insecure \
    --nodes $node \
    --file worker.yaml
done

# Kubeconfig al
talosctl kubeconfig --nodes $CONTROL_PLANE_IP -f