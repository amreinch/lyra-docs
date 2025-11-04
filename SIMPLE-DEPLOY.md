# Simple Deployment Guide

This guide shows you how to deploy Lyra documentation to your web server.

## Overview

The deployment is simple:
1. **Build** documentation locally (converts Markdown to HTML)
2. **Deploy** to your web server (copies HTML files via SSH)

**No server configuration needed** - just have a web server (Nginx/Apache) already set up!

---

## Quick Deploy

### On Your Local Machine:

```bash
cd /home/influ/lyra-docs

# First time only: Set up Python environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Build documentation
./build.sh

# Deploy to server
./deploy.sh --server docs.lyra.ovh --user ubuntu
```

That's it! Your documentation is now live.

---

## Detailed Steps

### 1. Build Documentation

```bash
cd /home/influ/lyra-docs

# Activate Python virtual environment
source venv/bin/activate

# Build static site (creates site/ directory with HTML)
./build.sh
```

**What this does:**
- Converts your Markdown files to HTML
- Applies Material theme styling
- Generates search index
- Creates all necessary CSS/JS files
- Output: `site/` directory with complete static website

### 2. Deploy to Server

```bash
./deploy.sh --server docs.lyra.ovh --user ubuntu
```

**What this does:**
- Creates backup of existing site on server
- Syncs `site/` directory to `/var/www/lyra-docs/` on server
- Sets proper permissions
- Your site is immediately live!

**Deploy Options:**
```bash
# Basic deployment
./deploy.sh --server docs.lyra.ovh --user ubuntu

# With SSH key
./deploy.sh --server docs.lyra.ovh --user ubuntu --key ~/.ssh/id_rsa

# Custom path on server
./deploy.sh --server docs.lyra.ovh --user ubuntu --path /var/www/docs
```

---

## Server Requirements

Your web server needs:
- ✅ Nginx or Apache installed
- ✅ Document root configured (e.g., `/var/www/lyra-docs/`)
- ✅ SSH access for deployment
- ✅ Proper permissions (www-data:www-data)

**That's all!** No special server setup required from this repository.

---

## Update Workflow

Whenever you update documentation:

```bash
cd /home/influ/lyra-docs

# 1. Edit your docs
nano docs/installation/kubernetes.md

# 2. Preview locally (optional)
mkdocs serve  # View at http://localhost:8000

# 3. Build and deploy
./build.sh && ./deploy.sh --server docs.lyra.ovh --user ubuntu
```

---

## Troubleshooting

### Build Fails

**Issue**: `mkdocs: command not found`

**Solution**:
```bash
source venv/bin/activate
```

**Issue**: Missing dependencies

**Solution**:
```bash
pip install -r requirements.txt
```

### Deploy Fails

**Issue**: Permission denied

**Solution**: Ensure your SSH user has sudo access or deploy to user-owned directory

**Issue**: Connection refused

**Solution**: Check SSH access
```bash
ssh ubuntu@docs.lyra.ovh
```

---

## Files Overview

```
lyra-docs/
├── build.sh           # Builds documentation
├── deploy.sh          # Deploys to server
├── mkdocs.yml         # Configuration
├── requirements.txt   # Python dependencies
├── docs/              # Your Markdown documentation
│   ├── index.md
│   ├── installation/
│   ├── admin/
│   └── ...
└── site/              # Generated HTML (after build)
```

---

## That's It!

This repository is focused on documentation only:
- ✅ Write docs in Markdown
- ✅ Build with MkDocs
- ✅ Deploy with one command

**Server configuration is separate** - handle that in your infrastructure setup!

---

**Need help?** Check [README.md](README.md) for full documentation.
