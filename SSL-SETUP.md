# SSL/HTTPS Setup Guide

This guide explains how to enable HTTPS for Lyra Documentation.

## Overview

The lyra-docs container includes built-in SSL support with:
- ✅ Self-signed certificate (generated automatically)
- ✅ HTTP to HTTPS redirect
- ✅ Modern TLS 1.2/1.3 support
- ✅ Security headers (HSTS, etc.)
- ✅ Option to use Let's Encrypt certificates

## Port Configuration

**Default ports:**
- **8081**: HTTP (redirects to HTTPS)
- **8444**: HTTPS (using 8444 to avoid conflict with Harbor's 443)

## Option 1: Self-Signed Certificate (Default)

The container automatically generates a self-signed certificate on build.

**Perfect for:**
- Development environments
- Internal networks
- Testing

**Deploy:**
```bash
./docker-deploy.sh rebuild
```

**Access:**
- HTTP: `http://localhost:8081` (redirects to HTTPS)
- HTTPS: `https://localhost:8444`

**Note:** Browsers will show a security warning for self-signed certificates. Click "Advanced" → "Proceed to localhost" to continue.

---

## Option 2: Let's Encrypt Certificates

Use real SSL certificates from Let's Encrypt for production.

### Prerequisites

1. **Domain name** pointing to your server (e.g., `docs.lyra.ovh`)
2. **Certbot** installed on server
3. **Port 80 accessible** for certificate validation

### Step 1: Obtain Let's Encrypt Certificate

```bash
# Install certbot if not already installed
sudo apt update
sudo apt install certbot -y

# Stop lyra-docs temporarily (certbot needs port 80)
cd ~/lyra-docs
./docker-deploy.sh stop

# Obtain certificate
sudo certbot certonly --standalone -d docs.lyra.ovh

# Restart lyra-docs
./docker-deploy.sh start
```

**Certificate files will be created at:**
- Certificate: `/etc/letsencrypt/live/docs.lyra.ovh/fullchain.pem`
- Private Key: `/etc/letsencrypt/live/docs.lyra.ovh/privkey.pem`

### Step 2: Mount Certificates in Container

Edit `docker-compose.yml`:

```yaml
services:
  lyra-docs:
    # ... other settings ...
    volumes:
      # Uncomment these lines:
      - /etc/letsencrypt/live/docs.lyra.ovh/fullchain.pem:/etc/nginx/ssl/nginx.crt:ro
      - /etc/letsencrypt/live/docs.lyra.ovh/privkey.pem:/etc/nginx/ssl/nginx.key:ro
```

### Step 3: Rebuild Container

```bash
./docker-deploy.sh rebuild
```

### Step 4: Verify SSL

```bash
# Test HTTPS connection
curl -v https://localhost:8444

# Or from another machine
curl -v https://docs.lyra.ovh:8444
```

### Certificate Auto-Renewal

Let's Encrypt certificates expire every 90 days. Set up auto-renewal:

```bash
# Create renewal script
sudo nano /usr/local/bin/renew-docs-cert.sh
```

Add:
```bash
#!/bin/bash
# Renew lyra-docs SSL certificate

cd /home/ubuntu/lyra-docs

# Stop container to free port 80
./docker-deploy.sh stop

# Renew certificate
certbot renew --quiet

# Restart container with new certificate
./docker-deploy.sh start
```

Make executable and schedule:
```bash
sudo chmod +x /usr/local/bin/renew-docs-cert.sh

# Add to crontab (runs weekly)
(crontab -l 2>/dev/null; echo "0 3 * * 0 /usr/local/bin/renew-docs-cert.sh") | crontab -
```

---

## Option 3: Reverse Proxy SSL Termination

Use Nginx reverse proxy to handle SSL (recommended for multiple services).

**Benefits:**
- Single SSL certificate for multiple services
- Centralized SSL management
- Can use standard ports (80/443)

### Nginx Reverse Proxy Configuration

Create `/etc/nginx/sites-available/docs-proxy`:

```nginx
upstream docs_backend {
    server 127.0.0.1:8081;
}

# HTTP - Redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name docs.lyra.ovh;

    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name docs.lyra.ovh;

    # SSL certificates
    ssl_certificate /etc/letsencrypt/live/docs.lyra.ovh/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/docs.lyra.ovh/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://docs_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable and reload:
```bash
sudo ln -s /etc/nginx/sites-available/docs-proxy /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

Get SSL certificate:
```bash
sudo certbot --nginx -d docs.lyra.ovh
```

**Access:** `https://docs.lyra.ovh` (standard HTTPS port)

---

## Security Recommendations

1. **Use real certificates** in production (Let's Encrypt)
2. **Enable auto-renewal** for Let's Encrypt certificates
3. **Use reverse proxy** for standard ports and centralized management
4. **Monitor certificate expiration** (certbot sends email warnings)
5. **Keep TLS up to date** (currently using TLS 1.2/1.3)

## Troubleshooting

### Self-Signed Certificate Warning

**Issue:** Browser shows "Your connection is not private"

**Solution:** This is expected with self-signed certificates. For development:
- Click "Advanced" → "Proceed to localhost"
- Or use Let's Encrypt for real certificates

### Certificate Not Found

**Issue:** `nginx: [emerg] cannot load certificate`

**Solution:**
```bash
# Check if certificates exist
ls -la /etc/letsencrypt/live/docs.lyra.ovh/

# Check volume mounts
docker inspect lyra-docs | grep -A 10 Mounts

# Verify file permissions
sudo chmod 644 /etc/letsencrypt/live/docs.lyra.ovh/fullchain.pem
sudo chmod 600 /etc/letsencrypt/live/docs.lyra.ovh/privkey.pem
```

### Port Already in Use

**Issue:** `Bind for 0.0.0.0:8444 failed: port is already allocated`

**Solution:**
```bash
# Check what's using the port
sudo ss -tlnp | grep 8444

# Change port in docker-compose.yml
ports:
  - "8445:443"  # Use different port
```

### HTTPS Not Working After Renewal

**Issue:** Certificate renewed but HTTPS shows old certificate

**Solution:**
```bash
# Container needs restart to reload certificates
./docker-deploy.sh restart
```

## Testing SSL Configuration

```bash
# Test SSL certificate validity
openssl s_client -connect localhost:8444 -servername docs.lyra.ovh

# Check certificate expiration
echo | openssl s_client -connect localhost:8444 2>/dev/null | openssl x509 -noout -dates

# Test TLS versions
nmap --script ssl-enum-ciphers -p 8444 localhost
```

---

## Summary

| Method | Pros | Cons | Best For |
|--------|------|------|----------|
| **Self-Signed** | Easy, no dependencies | Browser warnings | Development, testing |
| **Let's Encrypt (Direct)** | Real certificate, free | Manual renewal setup | Simple deployments |
| **Reverse Proxy** | Centralized, standard ports | Requires Nginx setup | Production, multiple services |

**Recommendation:** Use reverse proxy with Let's Encrypt for production deployments.
