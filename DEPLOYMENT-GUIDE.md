# Complete Deployment Guide

This guide covers the complete process of deploying your Lyra documentation from scratch.

## Overview

The deployment process consists of two main steps:

1. **Server Setup** (one-time) - Install and configure Nginx web server
2. **Documentation Deployment** (repeatable) - Deploy/update your documentation

---

## Step 1: Server Setup (One-Time)

### Prerequisites

Before running the installation script, ensure:

- ✅ You have **root/sudo access** to your web server
- ✅ Your **domain DNS** is configured (points to your server IP)
- ✅ **Port 80 and 443** are accessible from the internet
- ✅ Server is running **Ubuntu 20.04+** or **Debian 10+**

### Installation Methods

#### Method A: Full Automated Installation (Recommended)

This installs Nginx, configures SSL, and sets up everything automatically:

```bash
# Copy the script to your server
scp install-nginx.sh user@your-server.com:/tmp/

# SSH to your server
ssh user@your-server.com

# Run the installation script
cd /tmp
sudo ./install-nginx.sh --domain docs.lyra.ovh --email admin@lyra.ovh
```

**What this does:**
- ✅ Installs Nginx web server
- ✅ Creates document root (`/var/www/lyra-docs`)
- ✅ Configures Nginx site
- ✅ Sets up SSL with Let's Encrypt (automatic HTTPS)
- ✅ Configures firewall rules
- ✅ Sets proper permissions
- ✅ Tests and enables the site

**Installation time:** ~5 minutes

#### Method B: Installation Without SSL

If you want to set up SSL manually later:

```bash
sudo ./install-nginx.sh --domain docs.lyra.ovh --email admin@lyra.ovh --skip-ssl
```

You can add SSL later with:
```bash
sudo certbot --nginx -d docs.lyra.ovh
```

#### Method C: Custom Document Root

To use a different location for your documentation:

```bash
sudo ./install-nginx.sh --domain docs.lyra.ovh --email admin@lyra.ovh --webroot /opt/docs
```

### Script Options

```bash
Usage: sudo ./install-nginx.sh [OPTIONS]

Required Options:
    -d, --domain DOMAIN         Domain name (e.g., docs.lyra.ovh)
    -e, --email EMAIL           Email for Let's Encrypt notifications

Optional Options:
    -w, --webroot PATH          Document root path (default: /var/www/lyra-docs)
    --skip-ssl                  Skip SSL/Let's Encrypt setup
    --skip-firewall             Skip firewall configuration
    -h, --help                  Show help message

Examples:
    # Full installation with SSL
    sudo ./install-nginx.sh --domain docs.lyra.ovh --email admin@lyra.ovh

    # Installation without SSL
    sudo ./install-nginx.sh --domain docs.lyra.ovh --email admin@lyra.ovh --skip-ssl

    # Custom document root
    sudo ./install-nginx.sh --domain docs.lyra.ovh --email admin@lyra.ovh --webroot /opt/docs
```

### Verification

After installation, verify your setup:

```bash
# Check Nginx status
sudo systemctl status nginx

# Test Nginx configuration
sudo nginx -t

# View logs
sudo tail -f /var/log/nginx/lyra-docs-access.log
sudo tail -f /var/log/nginx/lyra-docs-error.log

# Test in browser
curl http://docs.lyra.ovh  # or https://docs.lyra.ovh if SSL enabled
```

You should see a placeholder page confirming the server is ready.

---

## Step 2: Deploy Documentation

Now that your server is set up, you can deploy your documentation.

### First Deployment

```bash
# On your development machine (where lyra-docs is located)
cd /home/influ/lyra-docs

# 1. Ensure dependencies are installed
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 2. Build the documentation
./build.sh

# 3. Deploy to your server
./deploy.sh --server docs.lyra.ovh --user ubuntu

# Or with SSH key
./deploy.sh --server docs.lyra.ovh --user ubuntu --key ~/.ssh/id_rsa
```

**Deployment time:** ~2 minutes

### Updating Documentation

Whenever you make changes to your documentation:

```bash
cd /home/influ/lyra-docs

# 1. Edit your documentation files
nano docs/installation/prerequisites.md

# 2. Preview locally (optional)
mkdocs serve  # View at http://localhost:8000

# 3. Build and deploy
./build.sh && ./deploy.sh --server docs.lyra.ovh --user ubuntu
```

### Deploy Script Options

```bash
Usage: ./deploy.sh [OPTIONS]

Required:
    -s, --server SERVER    Web server address

Optional:
    -u, --user USER        SSH user (default: www-data)
    -p, --path PATH        Deployment path (default: /var/www/lyra-docs)
    -k, --key KEY          SSH private key file
    -h, --help             Show help

Examples:
    # Basic deployment
    ./deploy.sh --server docs.lyra.ovh --user ubuntu

    # With SSH key
    ./deploy.sh --server docs.lyra.ovh --user ubuntu --key ~/.ssh/id_rsa

    # Custom path
    ./deploy.sh --server docs.lyra.ovh --user ubuntu --path /opt/docs
```

---

## Complete Workflow Example

Here's a complete example from scratch:

### On Your Web Server (One-Time Setup)

```bash
# 1. Copy installation script
scp install-nginx.sh ubuntu@docs.lyra.ovh:/tmp/

# 2. SSH to server
ssh ubuntu@docs.lyra.ovh

# 3. Run installation
cd /tmp
sudo ./install-nginx.sh --domain docs.lyra.ovh --email admin@lyra.ovh

# 4. Verify installation
curl https://docs.lyra.ovh
```

### On Your Development Machine (Repeatable)

```bash
# 1. Clone repository (first time only)
git clone https://github.com/amreinch/lyra-docs.git
cd lyra-docs

# 2. Set up Python environment (first time only)
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 3. Edit documentation
nano docs/installation/kubernetes.md

# 4. Preview locally
mkdocs serve  # Optional: view at http://localhost:8000

# 5. Build and deploy
./build.sh
./deploy.sh --server docs.lyra.ovh --user ubuntu

# Done! View at https://docs.lyra.ovh
```

---

## Troubleshooting

### SSL Certificate Issues

**Problem:** SSL certificate installation fails

**Solution:**
1. Verify domain DNS points to server:
   ```bash
   nslookup docs.lyra.ovh
   ```

2. Check port 80 is accessible:
   ```bash
   sudo ufw status
   sudo netstat -tlnp | grep :80
   ```

3. Manually retry SSL setup:
   ```bash
   sudo certbot --nginx -d docs.lyra.ovh
   ```

### Deployment Permission Issues

**Problem:** "Permission denied" during deployment

**Solution:**
```bash
# On web server, ensure proper SSH access
sudo usermod -aG www-data ubuntu
sudo chmod g+w /var/www/lyra-docs

# Or deploy as root (not recommended)
./deploy.sh --server docs.lyra.ovh --user root
```

### Nginx Configuration Issues

**Problem:** Nginx fails to start

**Solution:**
```bash
# Test configuration
sudo nginx -t

# View error logs
sudo tail -f /var/log/nginx/error.log

# Restart Nginx
sudo systemctl restart nginx
```

### Build Issues

**Problem:** `mkdocs: command not found`

**Solution:**
```bash
# Activate virtual environment
cd /home/influ/lyra-docs
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

---

## Rollback Procedure

If something goes wrong after deployment, you can rollback:

```bash
# SSH to your server
ssh ubuntu@docs.lyra.ovh

# List available backups
ls -lh /var/www/lyra-docs.backup-*

# Restore from backup
sudo tar -xzf /var/www/lyra-docs.backup-20241104-120000.tar.gz -C /var/www/lyra-docs/

# Restart Nginx
sudo systemctl reload nginx
```

---

## Automation with CI/CD

You can automate deployment using GitHub Actions:

```yaml
# .github/workflows/deploy-docs.yml
name: Deploy Documentation

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: actions/setup-python@v4
        with:
          python-version: '3.x'

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Build documentation
        run: mkdocs build

      - name: Deploy to server
        run: |
          ./deploy.sh --server ${{ secrets.SERVER }} \
                      --user ${{ secrets.SSH_USER }} \
                      --key <(echo "${{ secrets.SSH_KEY }}")
```

---

## Monitoring

### Check Site Status

```bash
# Check if site is accessible
curl -I https://docs.lyra.ovh

# View real-time access logs
ssh ubuntu@docs.lyra.ovh "sudo tail -f /var/log/nginx/lyra-docs-access.log"

# Check SSL certificate expiry
echo | openssl s_client -servername docs.lyra.ovh -connect docs.lyra.ovh:443 2>/dev/null | openssl x509 -noout -dates
```

### Performance Monitoring

```bash
# Check Nginx status
ssh ubuntu@docs.lyra.ovh "sudo systemctl status nginx"

# View server resources
ssh ubuntu@docs.lyra.ovh "htop"

# Analyze access logs
ssh ubuntu@docs.lyra.ovh "sudo goaccess /var/log/nginx/lyra-docs-access.log"
```

---

## Maintenance

### Update SSL Certificate

Certificates auto-renew, but to manually renew:

```bash
ssh ubuntu@docs.lyra.ovh
sudo certbot renew
sudo systemctl reload nginx
```

### Update Nginx

```bash
ssh ubuntu@docs.lyra.ovh
sudo apt update
sudo apt upgrade nginx
sudo systemctl restart nginx
```

### Backup Configuration

```bash
# Backup Nginx configuration
ssh ubuntu@docs.lyra.ovh "sudo tar -czf /tmp/nginx-backup.tar.gz /etc/nginx/sites-available/lyra-docs /var/www/lyra-docs"

# Download backup
scp ubuntu@docs.lyra.ovh:/tmp/nginx-backup.tar.gz ./backups/
```

---

## Security Best Practices

1. **Keep software updated:**
   ```bash
   sudo apt update && sudo apt upgrade
   ```

2. **Use SSH keys** instead of passwords

3. **Configure fail2ban** to prevent brute-force attacks:
   ```bash
   sudo apt install fail2ban
   ```

4. **Regular backups** of documentation and configuration

5. **Monitor SSL certificate expiry** (Let's Encrypt auto-renews)

---

## Quick Reference

### One-Time Server Setup
```bash
scp install-nginx.sh user@server:/tmp/
ssh user@server
sudo /tmp/install-nginx.sh --domain docs.lyra.ovh --email admin@lyra.ovh
```

### Deploy/Update Documentation
```bash
cd /home/influ/lyra-docs
./build.sh && ./deploy.sh --server docs.lyra.ovh --user ubuntu
```

### Check Logs
```bash
ssh user@server "sudo tail -f /var/log/nginx/lyra-docs-error.log"
```

### Rollback
```bash
ssh user@server "sudo tar -xzf /var/www/lyra-docs.backup-*.tar.gz -C /var/www/lyra-docs/"
```

---

**Need help?** Check [README.md](README.md) or [SETUP.md](SETUP.md) for more information.
