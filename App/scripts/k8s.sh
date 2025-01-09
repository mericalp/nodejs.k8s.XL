#!/bin/bash

# Hata durumunda scripti durdur
set -e

echo "Starting Kubernetes deployment..."

# Minikube durumunu kontrol et
if ! minikube status >/dev/null 2>&1; then
    echo "Starting Minikube..."
    minikube start --memory=2048 --cpus=2
else
    echo "Minikube is already running"
fi

# Eski deployment'ları temizle
echo "Cleaning up old deployments..."
kubectl delete deployment --all 2>/dev/null || true
kubectl delete service --all 2>/dev/null || true
kubectl delete configmap --all 2>/dev/null || true
kubectl delete pvc --all 2>/dev/null || true
sleep 5

# Uygulamaları sırayla deploy et
echo "Deploying MongoDB..."
kubectl apply -f mongodb-deployment.yaml
sleep 10

echo "Deploying Backend..."
kubectl apply -f backend-deployment.yaml
sleep 10

echo "Deploying Frontend..."
kubectl apply -f frontend-deployment.yaml
sleep 10

echo "Deploying NGINX..."
kubectl apply -f nginx-config.yaml
sleep 10

# Durumları kontrol et
echo -e "\nChecking deployment status:"
echo "------------------------"
echo "Pods:"
kubectl get pods
echo -e "\nServices:"
kubectl get services

# Minikube IP'sini al
MINIKUBE_IP=$(minikube ip)
echo -e "\nMinikube IP: ${MINIKUBE_IP}"

# /etc/hosts dosyasını güncelle
echo "Updating /etc/hosts file..."
sudo sed -i '/todo.local/d' /etc/hosts
echo "${MINIKUBE_IP} todo.local" | sudo tee -a /etc/hosts

# Minikube tunnel'ı başlat
echo "Starting Minikube tunnel..."
echo "Please enter your password if prompted."
sudo minikube tunnel &

echo -e "\nWaiting for all pods to be ready..."
kubectl wait --for=condition=ready pod --all --timeout=300s

echo -e "\nDeployment completed!"
echo "You can access the application at:"
echo "http://todo.local:30080"

# Log görüntüleme
echo -e "\nShowing logs for all components..."
echo "------------------------"
echo "Backend Logs:"
kubectl logs -l app=backend --tail=20
echo -e "\nFrontend Logs:"
kubectl logs -l app=frontend --tail=20
echo -e "\nMongoDB Logs:"
kubectl logs -l app=mongodb --tail=20
echo -e "\nNGINX Logs:"
kubectl logs -l app=nginx-proxy --tail=20

echo -e "\nPress Ctrl+C to stop the script..."

