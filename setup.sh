#!/bin/bash

# Docker'ı kur
sudo apt-get update
sudo apt-get install -y docker.io

# Docker'ı başlat ve enable et
sudo systemctl start docker
sudo systemctl enable docker

# Kullanıcıyı docker grubuna ekle
sudo usermod -aG docker $USER

# NodeJS'i kur
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs

# Proje bağımlılıklarını yükle
cd /opt/App/mern-todo-main
sudo npm install

cd client
sudo npm install

# Docker ağı oluştur
sudo docker network create todo-network

# MongoDB için Docker container başlat
sudo docker run -d --name mongodb --network todo-network -p 27017:27017 mongo

# Servis dosyalarını oluştur
backend_service="[Unit]
Description=MERN Todo Backend Application
After=network.target

[Service]
Type=simple
Environment=PORT=5001
Environment=MONGODB_URI=mongodb://172.18.0.2:27017/mern-todo
ExecStart=/usr/bin/node /opt/App/mern-todo-main/server.js
Restart=always
User=vagrant
Group=vagrant
WorkingDirectory=/opt/App/mern-todo-main

[Install]
WantedBy=multi-user.target"

client_service="[Unit]
Description=MERN Todo Client Application
After=network.target

[Service]
Type=simple
Environment=PORT=3000
Environment=REACT_APP_BACKEND_URL=http://localhost:5001
ExecStart=/usr/bin/npm start
Restart=always
User=vagrant
Group=vagrant
WorkingDirectory=/opt/App/mern-todo-main/client

[Install]
WantedBy=multi-user.target"

# Servis dosyalarını yaz
echo "$backend_service" | sudo tee /etc/systemd/system/mern-todo-backend.service
echo "$client_service" | sudo tee /etc/systemd/system/mern-todo-client.service

# Servisleri başlat ve enable et
sudo systemctl daemon-reload
sudo systemctl enable mern-todo-backend.service
sudo systemctl enable mern-todo-client.service
sudo systemctl start mern-todo-backend.service
sudo systemctl start mern-todo-client.service

echo "Kurulum tamamlandı. Uygulamanız şu adreslerden erişilebilir:"
echo "Frontend (React): http://localhost:3000"
echo "Backend API: http://localhost:5001"