# Docker Deployment Guide

Run Lyra documentation as a Docker container alongside Harbor.

## Quick Start

### Using Deployment Script (Recommended)

```bash
# Start documentation
./docker-deploy.sh start

# View available commands
./docker-deploy.sh help
```

### Using Docker Compose Directly

```bash
# Build and start container
docker-compose up -d

# Access documentation
curl http://localhost:8080
```

Documentation is now available at `http://your-server:8080`

---

## Deployment Options

### Option 1: Docker Compose (Recommended)

**Simple standalone deployment:**

```bash
cd /home/influ/lyra-docs

# Build and start
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

**Configuration:**
- Runs on port `8080` (configurable in `docker-compose.yml`)
- Auto-restarts on failure
- Health checks enabled

### Option 2: Docker Build & Run

**Manual Docker commands:**

```bash
# Build image
docker build -t lyra-docs:latest .

# Run container
docker run -d \
  --name lyra-docs \
  -p 8080:80 \
  --restart unless-stopped \
  lyra-docs:latest

# View logs
docker logs -f lyra-docs

# Stop and remove
docker stop lyra-docs
docker rm lyra-docs
```

---

## Integration with Nginx Reverse Proxy

Since you have Nginx reverse proxy for Harbor, add the docs to the same setup:

### Update Nginx Configuration

Edit your Nginx configuration to proxy `docs.lyra.ovh`:

```nginx
# /etc/nginx/sites-available/docs-proxy

upstream docs_backend {
    server 127.0.0.1:8080;
}

server {
    listen 80;
    listen [::]:80;
    server_name docs.lyra.ovh;

    location / {
        proxy_pass http://docs_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Enable and reload:**

```bash
sudo ln -s /etc/nginx/sites-available/docs-proxy /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

**Add SSL:**

```bash
sudo certbot --nginx -d docs.lyra.ovh
```

Now you have:
- 🐳 **Harbor**: `https://registry.lyra.ovh` → Docker (port 8080)
- 📚 **Docs**: `https://docs.lyra.ovh` → Docker (port 8081 or another port)

---

## Update Workflow

When you update documentation:

### Using Deployment Script (Easiest)

```bash
cd /home/influ/lyra-docs

# 1. Edit documentation
nano docs/installation/kubernetes.md

# 2. Update and rebuild (pulls git changes if repo, rebuilds, restarts)
./docker-deploy.sh update

# Or just rebuild if no git pull needed
./docker-deploy.sh rebuild
```

### Manual Docker Compose

```bash
cd /home/influ/lyra-docs

# 1. Edit documentation
nano docs/installation/kubernetes.md

# 2. Rebuild container
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# 3. Verify
curl http://localhost:8080
```

**Or use a one-liner:**

```bash
docker-compose down && docker-compose build --no-cache && docker-compose up -d
```

---

## Port Configuration

By default, the container runs on port `8080`. To change:

**Edit `docker-compose.yml`:**

```yaml
ports:
  - "9000:80"  # Change 9000 to your desired port
```

Then restart:

```bash
docker-compose down && docker-compose up -d
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs

# Check if port is in use
sudo ss -tlnp | grep 8080

# Try different port in docker-compose.yml
```

### Can't Access Documentation

```bash
# Check container status
docker-compose ps

# Check container logs
docker-compose logs lyra-docs

# Test from inside server
curl http://localhost:8080

# Check firewall
sudo ufw status
```

### Update Not Showing

```bash
# Force rebuild without cache
docker-compose build --no-cache
docker-compose up -d

# Clear browser cache (Ctrl+Shift+R)
```

---

## Multi-Container Setup

Run docs alongside Harbor and other services:

**Create a shared `docker-compose.yml` or use Docker networks:**

```yaml
version: '3.8'

services:
  harbor-nginx:
    # ... your Harbor config
    ports:
      - "80:8080"
    networks:
      - lyra-network

  lyra-docs:
    build: ./lyra-docs
    ports:
      - "8081:80"
    networks:
      - lyra-network

networks:
  lyra-network:
    driver: bridge
```

---

## Production Best Practices

1. **Use specific image tags:**
   ```yaml
   image: lyra-docs:1.0.0
   ```

2. **Set resource limits:**
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '0.5'
         memory: 256M
   ```

3. **Enable logging:**
   ```yaml
   logging:
     driver: "json-file"
     options:
       max-size: "10m"
       max-file: "3"
   ```

4. **Use environment variables:**
   ```yaml
   environment:
     - TZ=Europe/Berlin
   ```

---

## Advantages of Docker Deployment

✅ **Consistency**: Same environment everywhere
✅ **Isolation**: No conflicts with other services
✅ **Portability**: Easy to move between servers
✅ **Rollback**: Quick rollback with previous images
✅ **Scaling**: Easy to scale horizontally
✅ **Integration**: Works with your existing Docker setup

---

## Quick Reference

### Using Deployment Script

```bash
# Start
./docker-deploy.sh start

# Stop
./docker-deploy.sh stop

# Restart
./docker-deploy.sh restart

# Rebuild (no cache)
./docker-deploy.sh rebuild

# Update (git pull + rebuild)
./docker-deploy.sh update

# View logs
./docker-deploy.sh logs

# Check status
./docker-deploy.sh status

# Access shell
./docker-deploy.sh shell

# Clean up completely
./docker-deploy.sh clean

# Show help
./docker-deploy.sh help
```

### Using Docker Compose Directly

```bash
# Build and start
docker-compose up -d

# View logs
docker-compose logs -f

# Restart
docker-compose restart

# Stop
docker-compose down

# Rebuild
docker-compose build --no-cache

# Update
docker-compose down && docker-compose build && docker-compose up -d

# Check status
docker-compose ps

# Access shell
docker-compose exec lyra-docs sh
```

---

**Your documentation is now containerized!** 🐳📚
