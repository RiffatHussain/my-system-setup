#!/bin/bash

set -e  # Exit if any command fails

echo "======================================"
echo "   Docker Installation (Rocky/CentOS)  "
echo "======================================"

# Step 1: Remove old versions (if any)
echo "[1/6] Removing old Docker versions..."
sudo dnf remove -y docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-engine || true

# Step 2: Install required packages
echo "[2/6] Installing required packages..."
sudo dnf install -y dnf-plugins-core

# Step 3: Add Docker repository
echo "[3/6] Adding Docker repository..."
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Step 4: Install Docker Engine
echo "[4/6] Installing Docker Engine..."
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Step 5: Enable and start Docker
echo "[5/6] Starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Step 6: Add user to docker group
echo "[6/6] Adding user '$USER' to docker group..."
sudo usermod -aG docker $USER

# Verification
echo ""
echo "✅ Docker installed successfully!"
docker --version
docker compose version

echo ""
echo "⚠️  IMPORTANT: Logout & login again (or run 'newgrp docker') to use Docker without sudo"

# Optional tools
echo ""
echo "📊 Installing productivity tools..."
sudo dnf install -y glances ncdu curl htop vim 

echo "🎉 Setup complete!"


