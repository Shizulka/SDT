#!/usr/bin/env bash
set -euo pipefail

sudo apt update
sudo apt install -y docker.io docker-compose-plugin nginx curl

sudo systemctl enable docker
sudo systemctl start docker

sudo mkdir -p /opt/sdt
sudo cp docker-compose.yml /opt/sdt/docker-compose.yml
sudo cp .env.example /opt/sdt/.env
sudo cp systemd/sdt-app.service /etc/systemd/system/sdt-app.service

sudo systemctl daemon-reload
sudo systemctl enable sdt-app

sudo cp nginx.conf /etc/nginx/sites-available/sdt
sudo ln -sf /etc/nginx/sites-available/sdt /etc/nginx/sites-enabled/sdt
sudo nginx -t
sudo systemctl reload nginx