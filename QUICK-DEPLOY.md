# Quick Deploy - Cheat Sheet

Ultra-quick reference for deploying Lyra documentation.

---

## 🚀 Complete Deployment (From Scratch)

### Step 1: Server Setup (5 minutes, one-time)

```bash
# Copy installation script to your server
scp install-nginx.sh ubuntu@docs.lyra.ovh:/tmp/

# SSH and run installation
ssh ubuntu@docs.lyra.ovh
sudo /tmp/install-nginx.sh --domain docs.lyra.ovh --email admin@lyra.ovh
```

**Done!** Your server is now ready with:
- ✅ Nginx installed and configured
- ✅ SSL/HTTPS enabled (Let's Encrypt)
- ✅ Firewall configured
- ✅ Document root created
- ✅ Auto-renewal set up

### Step 2: Deploy Documentation (2 minutes)

```bash
# On your machine
cd /home/influ/lyra-docs
./build.sh && ./deploy.sh --server docs.lyra.ovh --user ubuntu
```

**Done!** Visit https://docs.lyra.ovh

---

## 📝 Update Documentation

```bash
# Edit your docs
cd /home/influ/lyra-docs
nano docs/installation/prerequisites.md

# Build and deploy
./build.sh && ./deploy.sh --server docs.lyra.ovh --user ubuntu
```

---

## 🔍 Common Commands

### Build Documentation
```bash
cd /home/influ/lyra-docs
./build.sh
```

### Deploy to Server
```bash
./deploy.sh --server docs.lyra.ovh --user ubuntu
```

### Preview Locally
```bash
cd /home/influ/lyra-docs
source venv/bin/activate
mkdocs serve
# Open http://localhost:8000
```

### Check Server Status
```bash
ssh ubuntu@docs.lyra.ovh "sudo systemctl status nginx"
```

### View Logs
```bash
ssh ubuntu@docs.lyra.ovh "sudo tail -f /var/log/nginx/lyra-docs-error.log"
```

---

## ⚙️ Installation Script Options

```bash
# Full installation (recommended)
sudo ./install-nginx.sh --domain DOMAIN --email EMAIL

# Skip SSL (HTTP only)
sudo ./install-nginx.sh --domain DOMAIN --email EMAIL --skip-ssl

# Custom document root
sudo ./install-nginx.sh --domain DOMAIN --email EMAIL --webroot /custom/path

# Help
sudo ./install-nginx.sh --help
```

---

## 🔧 Troubleshooting

### SSL Failed?
```bash
# Check DNS
nslookup docs.lyra.ovh

# Manually retry SSL
sudo certbot --nginx -d docs.lyra.ovh
```

### Permission Denied?
```bash
# On server
sudo chown -R www-data:www-data /var/www/lyra-docs
sudo chmod -R 755 /var/www/lyra-docs
```

### Nginx Error?
```bash
# Test configuration
sudo nginx -t

# View errors
sudo tail -f /var/log/nginx/error.log

# Restart
sudo systemctl restart nginx
```

---

## 📦 Complete Example

```bash
# ONE-TIME SERVER SETUP
scp install-nginx.sh ubuntu@docs.lyra.ovh:/tmp/
ssh ubuntu@docs.lyra.ovh "sudo /tmp/install-nginx.sh --domain docs.lyra.ovh --email admin@lyra.ovh"

# DEPLOY DOCUMENTATION (repeatable)
cd /home/influ/lyra-docs
./build.sh && ./deploy.sh --server docs.lyra.ovh --user ubuntu

# VERIFY
curl -I https://docs.lyra.ovh
```

---

## 📚 More Information

- **Complete Guide**: [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)
- **Setup Details**: [SETUP.md](SETUP.md)
- **Full Docs**: [README.md](README.md)
- **Getting Started**: [START-HERE.md](START-HERE.md)

---

**That's it!** Two commands and you're deployed! 🎉
