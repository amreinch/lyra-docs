#!/bin/bash

################################################################################
# Lyra Documentation - Nginx Reverse Proxy Installation
################################################################################
#
# This script sets up Nginx as a reverse proxy to handle multiple domains:
# - registry.lyra.ovh → Harbor (Docker container)
# - docs.lyra.ovh → Documentation (static files)
#
# Usage:
#   ./install-nginx-proxy.sh --docs-domain docs.lyra.ovh --registry-domain registry.lyra.ovh --email admin@lyra.ovh
#
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
DOCS_DOMAIN=""
REGISTRY_DOMAIN=""
EMAIL=""
DOCS_WEBROOT="/var/www/lyra-docs"
SKIP_SSL=false

print_header() {
    echo -e "${BLUE}=========================================="
    echo "$1"
    echo "==========================================${NC}"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ ERROR: $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ WARNING: $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
}

show_help() {
    cat << EOF
Lyra - Nginx Reverse Proxy Installation Script

Usage: sudo $0 [OPTIONS]

Required Options:
    --docs-domain DOMAIN         Documentation domain (e.g., docs.lyra.ovh)
    --registry-domain DOMAIN     Harbor registry domain (e.g., registry.lyra.ovh)
    -e, --email EMAIL            Email for Let's Encrypt

Optional Options:
    --docs-webroot PATH          Documentation root (default: /var/www/lyra-docs)
    --skip-ssl                   Skip SSL setup (HTTP only)
    -h, --help                   Show this help

Examples:
    # Full setup with SSL
    sudo $0 --docs-domain docs.lyra.ovh --registry-domain registry.lyra.ovh --email admin@lyra.ovh

    # Without SSL
    sudo $0 --docs-domain docs.lyra.ovh --registry-domain registry.lyra.ovh --email admin@lyra.ovh --skip-ssl

EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --docs-domain)
            DOCS_DOMAIN="$2"
            shift 2
            ;;
        --registry-domain)
            REGISTRY_DOMAIN="$2"
            shift 2
            ;;
        -e|--email)
            EMAIL="$2"
            shift 2
            ;;
        --docs-webroot)
            DOCS_WEBROOT="$2"
            shift 2
            ;;
        --skip-ssl)
            SKIP_SSL=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

check_root

# Validate arguments
if [ -z "$DOCS_DOMAIN" ] || [ -z "$REGISTRY_DOMAIN" ]; then
    print_error "Both --docs-domain and --registry-domain are required"
    exit 1
fi

if [ -z "$EMAIL" ] && [ "$SKIP_SSL" = false ]; then
    print_error "Email is required for SSL setup (or use --skip-ssl)"
    exit 1
fi

print_header "Installation Configuration"
echo "Documentation Domain: $DOCS_DOMAIN"
echo "Registry Domain:      $REGISTRY_DOMAIN"
echo "Email:                $EMAIL"
echo "Docs Root:            $DOCS_WEBROOT"
echo "SSL Setup:            $([ "$SKIP_SSL" = false ] && echo "Yes" || echo "No")"
echo ""
read -p "Proceed? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

print_header "Installing Nginx"

# Stop Docker's Nginx temporarily to free port 80
print_info "Detecting Docker container on port 80..."
DOCKER_CONTAINER=$(docker ps --filter "publish=80" --format "{{.Names}}" | head -1)
if [ -n "$DOCKER_CONTAINER" ]; then
    print_info "Found Docker container: $DOCKER_CONTAINER"
    print_warning "We need to reconfigure Docker to use a different port"
    print_info "Docker container will be accessible via Nginx reverse proxy"
    echo ""
    read -p "Stop Docker container temporarily? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker stop "$DOCKER_CONTAINER"
        print_success "Docker container stopped (will be restarted after setup)"
    else
        print_error "Cannot proceed with port 80 occupied"
        exit 1
    fi
fi

apt-get update -qq
if ! command -v nginx &> /dev/null; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
    print_success "Nginx installed"
else
    print_success "Nginx already installed"
fi

print_header "Creating Documentation Root"

mkdir -p "$DOCS_WEBROOT"
cat > "$DOCS_WEBROOT/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Lyra Documentation</title>
    <meta charset="utf-8">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            max-width: 800px;
            margin: 80px auto;
            padding: 40px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        h1 { color: #3949ab; margin-top: 0; }
        .info {
            background: #e3f2fd;
            padding: 20px;
            border-radius: 5px;
            border-left: 4px solid #3949ab;
            margin: 20px 0;
        }
        code {
            background: #f5f5f5;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Lyra Documentation</h1>
        <div class="info">
            <p><strong>Server is ready!</strong></p>
            <p>Deploy your documentation using:</p>
            <code>./deploy.sh --server YOUR_SERVER --user YOUR_USER</code>
        </div>
        <p>This is a placeholder page. Your documentation will appear here after deployment.</p>
    </div>
</body>
</html>
EOF

chown -R www-data:www-data "$DOCS_WEBROOT"
chmod -R 755 "$DOCS_WEBROOT"
print_success "Created $DOCS_WEBROOT"

print_header "Configuring Nginx Reverse Proxy"

# Remove default site
rm -f /etc/nginx/sites-enabled/default

# Registry configuration (Harbor proxy)
cat > /etc/nginx/sites-available/registry-proxy << EOF
# Harbor Registry - Nginx Reverse Proxy
upstream harbor_backend {
    server 127.0.0.1:8080;
}

server {
    listen 80;
    listen [::]:80;
    server_name $REGISTRY_DOMAIN;

    client_max_body_size 0;
    chunked_transfer_encoding on;

    access_log /var/log/nginx/registry-access.log;
    error_log /var/log/nginx/registry-error.log;

    location / {
        proxy_pass http://harbor_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # For Docker registry
        proxy_buffering off;
        proxy_request_buffering off;
    }

    location /v2/ {
        proxy_pass http://harbor_backend/v2/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Docker registry specifics
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_read_timeout 900s;
    }
}
EOF

# Documentation configuration
cat > /etc/nginx/sites-available/docs << EOF
# Lyra Documentation - Static Site
server {
    listen 80;
    listen [::]:80;
    server_name $DOCS_DOMAIN;

    root $DOCS_WEBROOT;
    index index.html;

    access_log /var/log/nginx/docs-access.log;
    error_log /var/log/nginx/docs-error.log;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss;

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ /\. {
        deny all;
    }
}
EOF

# Enable sites
ln -sf /etc/nginx/sites-available/registry-proxy /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/docs /etc/nginx/sites-enabled/

print_success "Nginx configurations created"

print_info "Testing Nginx configuration..."
if nginx -t; then
    print_success "Configuration valid"
else
    print_error "Configuration test failed"
    exit 1
fi

systemctl enable nginx
systemctl start nginx
print_success "Nginx started"

print_header "Reconfiguring Docker Harbor"

print_info "Harbor needs to be reconfigured to use port 8080"
print_warning "Please update your Harbor docker-compose.yml:"
echo ""
echo "Change:"
echo "  ports:"
echo "    - \"80:8080\""
echo ""
echo "To:"
echo "  ports:"
echo "    - \"8080:8080\""
echo ""
read -p "Press Enter when you've updated docker-compose.yml..."

if [ -n "$DOCKER_CONTAINER" ]; then
    print_info "Please restart Harbor with the new configuration"
    echo "Run: docker-compose up -d"
fi

if [ "$SKIP_SSL" = false ]; then
    print_header "Setting Up SSL"

    if ! command -v certbot &> /dev/null; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y certbot python3-certbot-nginx
        print_success "Certbot installed"
    fi

    print_info "Obtaining SSL certificates..."

    if certbot --nginx -d "$DOCS_DOMAIN" -d "$REGISTRY_DOMAIN" --non-interactive --agree-tos --email "$EMAIL" --redirect; then
        print_success "SSL certificates obtained"
    else
        print_warning "SSL setup failed - continuing with HTTP"
        print_info "Retry later with: sudo certbot --nginx -d $DOCS_DOMAIN -d $REGISTRY_DOMAIN"
    fi

    systemctl enable certbot.timer
fi

# Firewall
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    ufw allow 'Nginx Full'
    print_success "Firewall configured"
fi

print_header "Installation Complete!"

echo -e "${GREEN}✓ Nginx reverse proxy configured"
echo "✓ Documentation site: $DOCS_DOMAIN"
echo "✓ Registry proxy: $REGISTRY_DOMAIN → localhost:8080"
echo -e "${NC}"
echo ""
print_warning "Next Steps:"
echo "1. Update Harbor's docker-compose.yml to use port 8080"
echo "2. Restart Harbor: docker-compose down && docker-compose up -d"
echo "3. Deploy documentation: ./deploy.sh --server $DOCS_DOMAIN --user \$(whoami)"
echo ""
print_info "Access:"
if [ "$SKIP_SSL" = false ]; then
    echo "  Documentation: https://$DOCS_DOMAIN"
    echo "  Registry:      https://$REGISTRY_DOMAIN"
else
    echo "  Documentation: http://$DOCS_DOMAIN"
    echo "  Registry:      http://$REGISTRY_DOMAIN"
fi
