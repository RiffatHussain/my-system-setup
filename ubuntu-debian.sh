#!/bin/bash

set -e  # Exit on any error

echo "====================================="
echo "   Docker Installation on Ubuntu     "
echo "====================================="

# Step 1: Update packages
echo "[1/7] Updating package index..."
sudo apt update -y && sudo apt upgrade -y

# Step 2: Install prerequisites
echo "[2/7] Installing prerequisites..."
sudo apt install -y ca-certificates curl gnupg lsb-release

# Step 3: Add Docker's GPG key
echo "[3/7] Adding Docker's GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Step 4: Add Docker repository
echo "[4/7] Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Step 5: Install Docker Engine
echo "[5/7] Installing Docker Engine..."
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Step 6: Enable & start Docker
echo "[6/7] Enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Step 7: Add current user to docker group
echo "[7/7] Adding '$USER' to docker group..."
sudo usermod -aG docker $USER

# Verify installation
echo ""
echo "✅ Docker installed successfully!"
docker --version
docker compose version

echo ""
echo "⚠️  NOTE: Log out and back in (or run 'newgrp docker') to use Docker without sudo."

echo "Installing the advanced tools to improve productivity"

echo "Installing glances for better monit (upgraded version of htop)"
sudo apt install glances

echo "Installing ncdu (Best file size check interactively)"
sudo apt install ncdu
