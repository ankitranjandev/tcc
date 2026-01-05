#!/bin/bash
# ===========================================
# TCC Backend - SSL Setup Script
# ===========================================
# Run this script after pointing your domain to the EC2 IP
# Usage: ./setup-ssl.sh api.yourdomain.com
# ===========================================

set -e

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
    echo "Usage: ./setup-ssl.sh <your-domain>"
    echo "Example: ./setup-ssl.sh api.tccapp.com"
    exit 1
fi

echo "=========================================="
echo "Setting up SSL for: $DOMAIN"
echo "=========================================="

# Install Certbot
echo "Installing Certbot..."
sudo dnf install certbot python3-certbot-nginx -y

# Update Nginx config with domain
echo "Updating Nginx configuration..."
sudo tee /etc/nginx/conf.d/tcc-backend.conf > /dev/null << NGINX
server {
    listen 80;
    server_name $DOMAIN;

    # Redirect HTTP to HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    # SSL certificates will be added by Certbot
    # ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Increase client body size for file uploads
    client_max_body_size 10M;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
        proxy_connect_timeout 60;
        proxy_send_timeout 60;
    }

    # Serve uploaded files
    location /uploads {
        alias /home/ec2-user/tcc-backend/uploads;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
NGINX

# Test Nginx config
sudo nginx -t

# Get SSL certificate
echo "Getting SSL certificate from Let's Encrypt..."
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN --redirect

# Reload Nginx
sudo systemctl reload nginx

# Test auto-renewal
echo "Testing certificate auto-renewal..."
sudo certbot renew --dry-run

echo ""
echo "=========================================="
echo "SSL Setup Complete!"
echo "=========================================="
echo ""
echo "Your API is now available at: https://$DOMAIN"
echo ""
echo "Next steps:"
echo "1. Update your Flutter apps to use https://$DOMAIN/v1"
echo "2. Update CORS settings in .env if needed"
echo ""
echo "Certificate will auto-renew before expiration."
echo "=========================================="
