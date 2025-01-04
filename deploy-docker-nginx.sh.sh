#!/bin/bash

echo "Starting deployment at $(date)"

# Nginx kurulumu
echo "Installing and configuring Nginx..."
sudo apt-get update
sudo apt-get install -y nginx

# Nginx konfigürasyonu oluştur
echo "Creating Nginx configuration..."
cat << 'EOF' | sudo tee /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;

    upstream frontend {
        server 127.0.0.1:3100;
    }

    upstream backend {
        server 127.0.0.1:5100;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://frontend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }

        location /api/ {
            rewrite ^/api/(.*) /$1 break;
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }
}
EOF

# Nginx'i yeniden başlat
sudo systemctl restart nginx

# Docker ağı oluştur
echo "Creating Docker network..."
sudo docker network create todo-network || true

# Mevcut container'ları durdur ve sil
echo "Stopping and removing existing containers..."
sudo docker stop mongodb frontend backend || true
sudo docker rm mongodb frontend backend || true

# MongoDB container'ını başlat
echo "Starting MongoDB container..."
sudo docker run -d --name mongodb \
    --network todo-network \
    -p 27017:27017 \
    mongo:4.4

# Docker Hub'a giriş yap
echo "Logging into Docker Hub..."
sudo docker login --username mericalpp --password dckr_pat_Pm4C8z9sEwC9kdTEYbXrMZldtuU

# Backend için Docker build ve run
echo "Building and running backend..."
cd /opt/App/mern-todo-main
sudo docker build -t mericalpp/mern-todo-backend:v1 .
sudo docker push mericalpp/mern-todo-backend:v1
sudo docker run -d --name backend \
    --network todo-network \
    -p 5100:5001 \
    -e MONGODB_URI=mongodb://mongodb:27017/mern-todo \
    mericalpp/mern-todo-backend:v1

# Frontend için Docker build ve run
echo "Building and running frontend..."
cd /opt/App/mern-todo-main/client
sudo docker build -t mericalpp/mern-todo-frontend:v1 .
sudo docker push mericalpp/mern-todo-frontend:v1
sudo docker run -d --name frontend \
    --network todo-network \
    -p 3100:3000 \
    -e REACT_APP_API_URL=http://localhost:5100 \
    mericalpp/mern-todo-frontend:v1

# Container'ların durumunu kontrol et
echo "Checking container status..."
sudo docker ps

# Nginx durumunu kontrol et
echo "Checking Nginx status..."
sudo systemctl status nginx

echo "Deployment completed at $(date)"
echo "You can access the application at:"
echo "- Via Nginx: http://localhost:8080"
echo "- Direct Frontend: http://localhost:3100"
echo "- Direct Backend: http://localhost:5100"

# Log kontrol komutları
echo "To check logs, use:"
echo "Frontend logs: sudo docker logs frontend"
echo "Backend logs: sudo docker logs backend"
echo "MongoDB logs: sudo docker logs mongodb"
echo "Nginx logs: sudo tail -f /var/log/nginx/access.log"

# Container IP adreslerini görüntüle
echo "Container network details:"
sudo docker network inspect todo-network