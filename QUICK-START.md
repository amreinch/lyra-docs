# Quick Start Guide - Lyra Documentation

Get your professional documentation site up and running in minutes!

## 🚀 30-Second Overview

This is a **complete documentation system** built with MkDocs Material theme, ready to deploy to your **Nginx or Apache web server**.

## ⚡ Quick Commands

```bash
# 1. Install dependencies (first time only)
cd /home/influ/lyra-docs
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 2. Preview locally
mkdocs serve
# → Open http://localhost:8000

# 3. Build for production
./build.sh

# 4. Deploy to server
./deploy.sh --server docs.lyra.ovh --user ubuntu
```

## 📋 What You Got

### ✅ Complete Setup
- **MkDocs** with **Material Theme** (professional look)
- **Build system** (automated scripts)
- **Deployment system** (one-command deploy)
- **Web server configs** (Nginx + Apache templates)
- **Custom styling** (ready to customize)

### ✅ Documentation Structure
```
Homepage ─┬─ Installation Guide (11 sections)
          ├─ Administration Guide (9 sections)
          ├─ User Guide (3 sections)
          ├─ API Reference (4 sections)
          ├─ Troubleshooting (5 sections)
          └─ Development (3 sections)
```

### ✅ Professional Features
- 🎨 Light/dark mode toggle
- 🔍 Built-in search
- 📱 Responsive design (mobile-ready)
- 🖼️ Image lightbox
- 📋 Code copy buttons
- 🔗 Breadcrumb navigation
- ⚡ Fast loading (static site)

## 🎯 Three Usage Paths

### Path 1: Local Preview (2 minutes)

Perfect for: Writing and previewing documentation

```bash
cd /home/influ/lyra-docs
source venv/bin/activate  # If not already activated
mkdocs serve
```

→ Opens http://localhost:8000 with **live reload**
→ Edit any `.md` file and see changes instantly

### Path 2: Build Static Site (5 minutes)

Perfect for: Testing production build

```bash
./build.sh
```

→ Creates `site/` directory with static HTML
→ Ready to copy to any web server

### Path 3: Full Deployment (15 minutes)

Perfect for: Production deployment

```bash
# On web server: Set up Nginx/Apache (one-time)
# See: SETUP.md section "Web Server Deployment"

# On your machine: Build and deploy
./build.sh
./deploy.sh --server docs.lyra.ovh --user ubuntu
```

→ Live at https://docs.lyra.ovh

## 📝 Adding Your Content

### 1. Edit Existing Pages

```bash
# Edit homepage
nano docs/index.md

# Edit installation guide
nano docs/installation/index.md

# Preview changes
mkdocs serve
```

### 2. Add New Pages

```bash
# Create new page
nano docs/installation/prerequisites.md

# Add to navigation in mkdocs.yml
nano mkdocs.yml
```

### 3. Add Images

```bash
# Place image in assets
cp ~/screenshot.png docs/assets/

# Reference in markdown
# ![Screenshot](assets/screenshot.png)
```

## 🌐 Deploy to Web Server

### Option A: Nginx (Recommended)

```bash
# 1. On server: Install Nginx
sudo apt install nginx -y

# 2. Copy and configure
sudo cp nginx.conf /etc/nginx/sites-available/lyra-docs
sudo nano /etc/nginx/sites-available/lyra-docs
# Update: server_name, SSL paths

# 3. Enable
sudo ln -s /etc/nginx/sites-available/lyra-docs /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# 4. Deploy from your machine
./deploy.sh --server docs.lyra.ovh --user ubuntu
```

### Option B: Apache

```bash
# 1. On server: Install Apache
sudo apt install apache2 -y
sudo a2enmod ssl rewrite headers deflate

# 2. Copy and configure
sudo cp apache.conf /etc/apache2/sites-available/lyra-docs.conf
sudo nano /etc/apache2/sites-available/lyra-docs.conf
# Update: ServerName, SSL paths

# 3. Enable
sudo a2ensite lyra-docs
sudo apache2ctl configtest
sudo systemctl reload apache2

# 4. Deploy from your machine
./deploy.sh --server docs.lyra.ovh --user ubuntu
```

## 🔐 SSL Setup (HTTPS)

### Quick SSL with Let's Encrypt (Free)

```bash
# On server
sudo apt install certbot python3-certbot-nginx -y

# For Nginx
sudo certbot --nginx -d docs.lyra.ovh

# For Apache
sudo certbot --apache -d docs.lyra.ovh
```

→ Automatic HTTPS with auto-renewal!

## 🎨 Customization

### Change Colors

Edit `docs/stylesheets/extra.css`:

```css
:root {
    --md-primary-fg-color: #YOUR_COLOR;
    --md-accent-fg-color: #YOUR_COLOR;
}
```

### Add Logo

1. Place logo: `docs/assets/logo.png`
2. Edit `mkdocs.yml`:
   ```yaml
   theme:
     logo: assets/logo.png
   ```

### Update Site Name

Edit `mkdocs.yml`:
```yaml
site_name: Your Company Documentation
site_url: https://docs.yourcompany.com
```

## 📊 Documentation Workflow

```
1. Write Content          2. Preview          3. Build          4. Deploy
   ↓                         ↓                    ↓                ↓
Edit .md files  →  mkdocs serve  →  ./build.sh  →  ./deploy.sh
   ↓                         ↓                    ↓                ↓
Save file        →  Auto-reload  →  site/ dir   →  Live website
```

## 🆘 Troubleshooting

### "mkdocs: command not found"

```bash
source venv/bin/activate
```

### Build fails

```bash
# Reinstall dependencies
pip install -r requirements.txt
```

### Deployment fails

```bash
# Check SSH access
ssh ubuntu@docs.lyra.ovh

# Check file permissions
ls -la /var/www/lyra-docs
```

### Website not loading

```bash
# Check web server status
sudo systemctl status nginx  # or apache2

# Check logs
sudo tail -f /var/log/nginx/lyra-docs-error.log
```

## 📚 Next Steps

1. **Read the docs**:
   - [README.md](README.md) - Complete documentation
   - [SETUP.md](SETUP.md) - Detailed setup guide
   - [PROJECT-SUMMARY.md](PROJECT-SUMMARY.md) - Full project overview

2. **Start writing**:
   - Fill in installation guides
   - Add administration documentation
   - Write user guides
   - Document your API

3. **Add visuals**:
   - Screenshots of your application
   - Architecture diagrams
   - Process flowcharts

4. **Deploy to production**:
   - Set up SSL certificates
   - Configure web server
   - Deploy and test

## 🎯 Common Use Cases

### Daily Documentation Updates

```bash
# Edit content
nano docs/admin/user-management.md

# Preview
mkdocs serve

# When ready, deploy
./build.sh && ./deploy.sh --server docs.lyra.ovh --user ubuntu
```

### Adding Screenshots

```bash
# Take screenshot → save to docs/assets/screenshots/
# Reference in markdown:
# ![User Management](assets/screenshots/user-management.png)
```

### Creating Step-by-Step Guides

```markdown
## Installation Steps

1. **Install Kubernetes**
   ```bash
   kubeadm init
   ```

2. **Deploy application**
   ```bash
   helm install lyra ./chart
   ```

3. **Verify installation**
   ```bash
   kubectl get pods -n lyra
   ```
```

## 💡 Pro Tips

1. **Preview before deploying**: Always use `mkdocs serve` to check changes
2. **Use admonitions**: Make important info stand out with `!!! note`
3. **Add code examples**: Include working code snippets
4. **Link between pages**: Use relative links like `[link](../other-page.md)`
5. **Optimize images**: Compress large screenshots before adding
6. **Keep it updated**: Documentation should evolve with your product

## 🌟 Features to Explore

- **Tabs**: Group related content
- **Admonitions**: Info boxes, warnings, tips
- **Tables**: Organize data
- **Code blocks**: Syntax highlighting
- **Mermaid diagrams**: Flow charts and diagrams
- **Icons**: Material Design icons
- **Search**: Full-text search built-in

## 📞 Need Help?

- **Technical Issues**: Check [SETUP.md](SETUP.md)
- **Writing Docs**: Check [README.md](README.md)
- **MkDocs Help**: https://www.mkdocs.org/
- **Material Theme**: https://squidfunk.github.io/mkdocs-material/

---

**Ready to start? Run `mkdocs serve` and start writing!** ✨

**Questions?** Check the other documentation files:
- [README.md](README.md) - Full documentation
- [SETUP.md](SETUP.md) - Setup guide
- [PROJECT-SUMMARY.md](PROJECT-SUMMARY.md) - Project overview
