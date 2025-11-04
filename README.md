# Lyra Documentation

Professional documentation for Lyra Platform built with MkDocs Material theme.

## Quick Start

### Docker Deployment (Recommended)

```bash
# Start documentation
./docker-deploy.sh start

# Or simply
./docker-deploy.sh
```

Documentation available at `http://localhost:8080`

**Other commands:**
```bash
./docker-deploy.sh rebuild   # Rebuild from scratch
./docker-deploy.sh update    # Pull changes and rebuild
./docker-deploy.sh logs      # View logs
./docker-deploy.sh stop      # Stop container
./docker-deploy.sh help      # Show all commands
```

### Alternative: Manual Docker Commands

```bash
# Build and start
docker-compose up -d

# Rebuild without cache
docker-compose build --no-cache && docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

**See deployment guides:**
- **[DOCKER-DEPLOY.md](DOCKER-DEPLOY.md)** - Docker deployment (recommended)
- **[SIMPLE-DEPLOY.md](SIMPLE-DEPLOY.md)** - Traditional deployment

---

## What This Repository Does

This repository contains:
- 📝 **Documentation content** (Markdown files in `docs/`)
- 🏗️ **Build system** (MkDocs with Material theme)
- 🚀 **Deployment script** (One-command deploy to server)

**What this repository does NOT do:**
- ❌ Server configuration (Nginx/Apache)
- ❌ SSL certificate management
- ❌ Firewall setup
- ❌ Infrastructure provisioning

**Server setup is separate** - this repo only handles documentation!

---

## Repository Structure

```
lyra-docs/
├── docs/                    # Documentation source (Markdown)
│   ├── index.md            # Homepage
│   ├── installation/       # Installation guides
│   ├── admin/              # Admin documentation
│   ├── user/               # User guides
│   ├── api/                # API reference
│   ├── troubleshooting/    # Troubleshooting
│   ├── assets/             # Images, screenshots
│   ├── stylesheets/        # Custom CSS
│   └── javascripts/        # Custom JavaScript
├── site/                   # Generated static site (after build)
├── mkdocs.yml              # MkDocs configuration
├── requirements.txt        # Python dependencies
├── build.sh                # Build script
├── deploy.sh               # Deployment script
├── README.md               # This file
└── SIMPLE-DEPLOY.md        # Deployment guide
```

---

## Local Development

### First Time Setup

```bash
# Clone repository
git clone https://github.com/amreinch/lyra-docs.git
cd lyra-docs

# Set up Python environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Preview Documentation

```bash
# Start development server with live reload
mkdocs serve

# Open in browser
open http://localhost:8000
```

Edit any `.md` file and see changes instantly!

### Build Documentation

```bash
./build.sh
```

Generates static HTML in `site/` directory.

---

## Deployment

### Prerequisites

Your web server needs:
- Nginx or Apache configured
- Document root created (e.g., `/var/www/lyra-docs/`)
- SSH access enabled

### Deploy

```bash
./deploy.sh --server docs.lyra.ovh --user ubuntu
```

**Options:**
- `--server SERVER`: Server address (required)
- `--user USER`: SSH user (default: www-data)
- `--path PATH`: Deployment path (default: /var/www/lyra-docs)
- `--key KEY`: SSH private key file

**Example:**
```bash
./deploy.sh --server docs.lyra.ovh --user ubuntu --key ~/.ssh/id_rsa
```

---

## Writing Documentation

### Add New Page

1. Create Markdown file in `docs/`:
   ```bash
   nano docs/installation/kubernetes.md
   ```

2. Add to navigation in `mkdocs.yml`:
   ```yaml
   nav:
     - Installation:
       - Kubernetes: installation/kubernetes.md
   ```

3. Build and deploy:
   ```bash
   ./build.sh && ./deploy.sh --server docs.lyra.ovh --user ubuntu
   ```

### Markdown Features

#### Code Blocks

````markdown
```python
def hello():
    print("Hello, World!")
```
````

#### Admonitions (Info Boxes)

```markdown
!!! note "Optional Title"
    This is a note

!!! warning
    This is a warning

!!! tip
    This is a tip
```

#### Tables

```markdown
| Column 1 | Column 2 |
|----------|----------|
| Value 1  | Value 2  |
```

#### Images

```markdown
![Alt text](assets/screenshot.png)
```

---

## Features

- ✅ **Material Design** theme
- ✅ **Light/dark mode** toggle
- ✅ **Built-in search**
- ✅ **Responsive design** (mobile-ready)
- ✅ **Code syntax highlighting**
- ✅ **Image lightbox**
- ✅ **Copy code buttons**
- ✅ **Table of contents**
- ✅ **Navigation tabs**

---

## Update Workflow

```bash
# 1. Edit documentation
nano docs/admin/user-management.md

# 2. Preview locally (optional)
mkdocs serve

# 3. Build and deploy
./build.sh && ./deploy.sh --server docs.lyra.ovh --user ubuntu
```

---

## Maintenance

### Update Dependencies

```bash
source venv/bin/activate
pip install --upgrade -r requirements.txt
```

### Clean Build

```bash
mkdocs build --clean
```

---

## GitHub Repository

**Repository:** https://github.com/amreinch/lyra-docs

**Clone:**
```bash
git clone https://github.com/amreinch/lyra-docs.git
```

**Update:**
```bash
git pull
```

---

## Documentation

- **[SIMPLE-DEPLOY.md](SIMPLE-DEPLOY.md)** - Deployment guide
- **[MkDocs Documentation](https://www.mkdocs.org/)** - MkDocs official docs
- **[Material Theme](https://squidfunk.github.io/mkdocs-material/)** - Theme documentation

---

## License

Part of the Lyra Platform project.

---

**Happy documenting!** 📚✨
