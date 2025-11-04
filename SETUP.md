# Lyra Documentation Setup Guide

Quick reference for setting up and deploying the Lyra documentation site.

## Initial Setup

### 1. Install Dependencies

```bash
cd /home/influ/lyra-docs

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install requirements
pip install -r requirements.txt
```

### 2. Test Locally

```bash
# Start development server
mkdocs serve

# Access at http://localhost:8000
# Changes auto-reload
```

### 3. Build Static Site

```bash
# Run build script
./build.sh

# Or manually
mkdocs build --clean

# Output in ./site/ directory
```

## Web Server Deployment

### Option 1: Nginx

#### 1. Install Nginx

```bash
sudo apt update
sudo apt install nginx -y
```

#### 2. Configure Site

```bash
# Copy configuration
sudo cp nginx.conf /etc/nginx/sites-available/lyra-docs

# Edit configuration
sudo nano /etc/nginx/sites-available/lyra-docs

# Update these values:
# - server_name: Your domain (e.g., docs.lyra.ovh)
# - ssl_certificate: Path to your SSL cert
# - ssl_certificate_key: Path to your SSL key
# - root: /var/www/lyra-docs
```

#### 3. Enable Site

```bash
# Create symlink
sudo ln -s /etc/nginx/sites-available/lyra-docs /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

#### 4. Deploy Documentation

```bash
# From your development machine
./deploy.sh --server your-server.com --user your-user

# Or manually copy files
scp -r site/* user@server:/var/www/lyra-docs/
```

### Option 2: Apache

#### 1. Install Apache

```bash
sudo apt update
sudo apt install apache2 -y
```

#### 2. Enable Required Modules

```bash
sudo a2enmod ssl rewrite headers deflate
```

#### 3. Configure Site

```bash
# Copy configuration
sudo cp apache.conf /etc/apache2/sites-available/lyra-docs.conf

# Edit configuration
sudo nano /etc/apache2/sites-available/lyra-docs.conf

# Update these values:
# - ServerName: Your domain (e.g., docs.lyra.ovh)
# - SSLCertificateFile: Path to your SSL cert
# - SSLCertificateKeyFile: Path to your SSL key
# - DocumentRoot: /var/www/lyra-docs
```

#### 4. Enable Site

```bash
# Enable site
sudo a2ensite lyra-docs

# Test configuration
sudo apache2ctl configtest

# Reload Apache
sudo systemctl reload apache2
```

#### 5. Deploy Documentation

```bash
# From your development machine
./deploy.sh --server your-server.com --user your-user

# Or manually copy files
scp -r site/* user@server:/var/www/lyra-docs/
```

## SSL Certificates

### Option 1: Let's Encrypt (Free)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# For Nginx
sudo certbot --nginx -d docs.lyra.ovh

# For Apache
sudo apt install python3-certbot-apache -y
sudo certbot --apache -d docs.lyra.ovh
```

### Option 2: Custom Certificates

```bash
# Place your certificates
sudo cp your-cert.crt /etc/ssl/certs/lyra-docs.crt
sudo cp your-key.key /etc/ssl/private/lyra-docs.key
sudo chmod 600 /etc/ssl/private/lyra-docs.key

# Update paths in nginx.conf or apache.conf
```

## Automated Deployment

### Using Deploy Script

```bash
# Basic deployment
./deploy.sh --server docs.lyra.ovh --user ubuntu

# With SSH key
./deploy.sh --server docs.lyra.ovh --user ubuntu --key ~/.ssh/id_rsa

# Custom path
./deploy.sh --server docs.lyra.ovh --user ubuntu --path /var/www/docs
```

### Deploy Script Options

- `--server, -s`: Server address (required)
- `--user, -u`: SSH user (default: www-data)
- `--path, -p`: Deployment path (default: /var/www/lyra-docs)
- `--key, -k`: SSH private key file
- `--help, -h`: Show help

## Directory Structure on Server

```bash
/var/www/lyra-docs/          # Document root
├── index.html               # Homepage
├── installation/            # Installation guides
│   └── index.html
├── admin/                   # Admin guides
│   └── index.html
├── css/                     # Stylesheets
├── js/                      # JavaScript
├── assets/                  # Images and media
└── search/                  # Search index
```

## Permissions

Set correct permissions after deployment:

```bash
# On web server
sudo chown -R www-data:www-data /var/www/lyra-docs
sudo chmod -R 755 /var/www/lyra-docs
sudo find /var/www/lyra-docs -type f -exec chmod 644 {} \;
```

## Verification

### 1. Check Web Server Status

```bash
# Nginx
sudo systemctl status nginx

# Apache
sudo systemctl status apache2
```

### 2. Test Configuration

```bash
# Nginx
sudo nginx -t

# Apache
sudo apache2ctl configtest
```

### 3. Check Logs

```bash
# Nginx
sudo tail -f /var/log/nginx/lyra-docs-access.log
sudo tail -f /var/log/nginx/lyra-docs-error.log

# Apache
sudo tail -f /var/log/apache2/lyra-docs-access.log
sudo tail -f /var/log/apache2/lyra-docs-error.log
```

### 4. Test in Browser

Navigate to your domain:
- HTTP: `http://docs.lyra.ovh` (should redirect to HTTPS)
- HTTPS: `https://docs.lyra.ovh`

## Updating Documentation

### 1. Edit Content

```bash
# Edit markdown files in docs/
nano docs/installation/prerequisites.md
```

### 2. Preview Changes

```bash
mkdocs serve
# View at http://localhost:8000
```

### 3. Build and Deploy

```bash
# Build
./build.sh

# Deploy
./deploy.sh --server docs.lyra.ovh --user ubuntu
```

## Troubleshooting

### Build Issues

**Problem**: `mkdocs: command not found`

```bash
# Solution: Activate virtual environment
source venv/bin/activate
```

**Problem**: Missing dependencies

```bash
# Solution: Reinstall requirements
pip install -r requirements.txt
```

### Deployment Issues

**Problem**: Permission denied

```bash
# Solution: Check SSH access and sudo privileges
ssh user@server
sudo -l
```

**Problem**: Files not updating

```bash
# Solution: Clear cache and force sync
./deploy.sh --server docs.lyra.ovh --user ubuntu
```

### Web Server Issues

**Problem**: 403 Forbidden

```bash
# Solution: Check file permissions
sudo chmod -R 755 /var/www/lyra-docs
sudo chown -R www-data:www-data /var/www/lyra-docs
```

**Problem**: SSL certificate error

```bash
# Solution: Check certificate paths and validity
sudo openssl x509 -in /etc/ssl/certs/lyra-docs.crt -text -noout
```

## Maintenance

### Regular Updates

```bash
# Update dependencies
source venv/bin/activate
pip install --upgrade -r requirements.txt

# Update MkDocs Material theme
pip install --upgrade mkdocs-material
```

### Backup

```bash
# Backup documentation source
tar -czf lyra-docs-backup-$(date +%Y%m%d).tar.gz docs/ mkdocs.yml

# Backup web server files
ssh user@server "sudo tar -czf /tmp/lyra-docs-$(date +%Y%m%d).tar.gz /var/www/lyra-docs"
```

## Quick Reference

### Common Commands

```bash
# Local development
mkdocs serve

# Build site
./build.sh

# Deploy to server
./deploy.sh --server SERVER --user USER

# Test Nginx config
sudo nginx -t

# Test Apache config
sudo apache2ctl configtest

# Reload Nginx
sudo systemctl reload nginx

# Reload Apache
sudo systemctl reload apache2

# View logs (Nginx)
sudo tail -f /var/log/nginx/lyra-docs-error.log

# View logs (Apache)
sudo tail -f /var/log/apache2/lyra-docs-error.log
```

## Support

For issues:
1. Check this guide
2. Review [README.md](README.md)
3. Check MkDocs Material documentation: https://squidfunk.github.io/mkdocs-material/
4. Contact Lyra team
