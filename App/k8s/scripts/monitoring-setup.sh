#!/bin/bash

#  Prometheus Operator
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --values /opt/App/monitoring/prometheus/values.yaml

#  Grafana
helm upgrade --install grafana grafana/grafana \
    --namespace monitoring \
    --set persistence.enabled=true \
    --set adminPassword=admin \
    --values /opt/App/monitoring/grafana/values.yaml

#  custom dashboards
kubectl apply -f /opt/App/monitoring/grafana/dashboards/

echo "Monitoring setup completed!"