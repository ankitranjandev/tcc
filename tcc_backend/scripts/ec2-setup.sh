#!/bin/bash
# ===========================================
# TCC Backend - EC2 Free Tier Setup Script
# ===========================================
# Run this script on a fresh Amazon Linux 2023 EC2 instance
# Usage: chmod +x ec2-setup.sh && ./ec2-setup.sh

set -e

echo "=========================================="
echo "TCC Backend - EC2 Setup for Free Tier"
echo "=========================================="

# Update system
echo "Updating system packages..."
sudo dnf update -y

# Install Node.js 18
echo "Installing Node.js 18..."
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo dnf install nodejs -y

# Install Git
echo "Installing Git..."
sudo dnf install git -y

# Install Nginx
echo "Installing Nginx..."
sudo dnf install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

# Install PM2
echo "Installing PM2..."
sudo npm install -g pm2

# Create swap space (important for t2.micro)
echo "Creating 2GB swap space..."
if [ ! -f /swapfile ]; then
    sudo dd if=/dev/zero of=/swapfile bs=128M count=16
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab
fi

# Create app directory
echo "Creating application directory..."
mkdir -p /home/ec2-user/tcc-backend
cd /home/ec2-user/tcc-backend

echo "=========================================="
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Clone your repository:"
echo "   git clone YOUR_REPO_URL ."
echo ""
echo "2. Create .env file:"
echo "   nano .env"
echo ""
echo "3. Install dependencies and build:"
echo "   npm ci --only=production"
echo "   npm run build"
echo ""
echo "4. Run database migrations:"
echo "   npm run migrate"
echo ""
echo "5. Start with PM2:"
echo "   pm2 start dist/server.js --name tcc-backend"
echo "   pm2 save"
echo "   pm2 startup"
echo ""
echo "6. Configure Nginx (see documentation)"
echo "=========================================="
