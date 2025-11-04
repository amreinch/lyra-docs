#!/bin/bash

################################################################################
# Lyra Documentation - Nginx Web Server Installation Script
################################################################################
#
# This script automates the complete installation and configuration of Nginx
# for hosting the Lyra documentation site.
#
# Usage:
#   ./install-nginx.sh --domain docs.lyra.ovh --email admin@lyra.ovh
#
# What this script does:
#   1. Installs Nginx web server
#   2. Creates document root directory
#   3. Configures Nginx site
#   4. Sets up SSL with Let's Encrypt
#   5. Configures firewall (if ufw is active)
#   6. Sets proper permissions
#   7. Tests and enables the site
#
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DOMAIN=""
EMAIL=""
WEBROOT="/var/www/lyra-docs"
SKIP_SSL=false
SKIP_FIREWALL=false

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "$1"
    echo "=========================================="
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root or with sudo"
        echo "Usage: sudo $0 --domain DOMAIN --email EMAIL"
        exit 1
    fi
}

################################################################################
# Parse Command Line Arguments
################################################################################

show_help() {
    cat << EOF
Lyra Documentation - Nginx Installation Script

Usage: sudo $0 [OPTIONS]

Required Options:
    -d, --domain DOMAIN         Domain name (e.g., docs.lyra.ovh)
    -e, --email EMAIL           Email for Let's Encrypt notifications

Optional Options:
    -w, --webroot PATH          Document root path (default: /var/www/lyra-docs)
    --skip-ssl                  Skip SSL/Let's Encrypt setup
    --skip-firewall             Skip firewall configuration
    -h, --help                  Show this help message

Examples:
    # Full installation with SSL
    sudo $0 --domain docs.lyra.ovh --email admin@lyra.ovh

    # Installation without SSL (HTTP only)
    sudo $0 --domain docs.lyra.ovh --email admin@lyra.ovh --skip-ssl

    # Custom document root
    sudo $0 --domain docs.lyra.ovh --email admin@lyra.ovh --webroot /opt/docs

EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -e|--email)
            EMAIL="$2"
            shift 2
            ;;
        -w|--webroot)
            WEBROOT="$2"
            shift 2
            ;;
        --skip-ssl)
            SKIP_SSL=true
            shift
            ;;
        --skip-firewall)
            SKIP_FIREWALL=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

################################################################################
# Validate Arguments
################################################################################

validate_args() {
    if [ -z "$DOMAIN" ]; then
        print_error "Domain is required"
        echo "Usage: sudo $0 --domain DOMAIN --email EMAIL"
        exit 1
    fi

    if [ -z "$EMAIL" ] && [ "$SKIP_SSL" = false ]; then
        print_error "Email is required for SSL setup"
        echo "Usage: sudo $0 --domain DOMAIN --email EMAIL"
        echo "Or use --skip-ssl to skip SSL setup"
        exit 1
    fi

    # Validate domain format (allow subdomains and various TLDs)
    if ! [[ "$DOMAIN" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
        print_error "Invalid domain format: $DOMAIN"
        exit 1
    fi

    # Validate email format (if not skipping SSL)
    if [ "$SKIP_SSL" = false ]; then
        if ! [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            print_error "Invalid email format: $EMAIL"
            exit 1
        fi
    fi
}

################################################################################
# System Checks
################################################################################

check_system() {
    print_header "System Checks"

    # Check if running on Ubuntu/Debian
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        print_info "Operating System: $NAME $VERSION"

        if [[ ! "$ID" =~ ^(ubuntu|debian)$ ]]; then
            print_warning "This script is designed for Ubuntu/Debian"
            print_info "It may work on other systems but is not tested"
            read -p "Continue anyway? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi

    # Check if Nginx is already installed
    if command -v nginx &> /dev/null; then
        NGINX_VERSION=$(nginx -v 2>&1 | grep -oP '(?<=nginx/)[0-9.]+')
        print_info "Nginx is already installed (version: $NGINX_VERSION)"
    else
        print_info "Nginx is not installed - will be installed"
    fi

    # Check if domain resolves
    print_info "Checking DNS resolution for $DOMAIN..."
    if host "$DOMAIN" &> /dev/null; then
        RESOLVED_IP=$(host "$DOMAIN" | grep "has address" | awk '{print $4}' | head -1)
        print_success "Domain resolves to: $RESOLVED_IP"
    else
        print_warning "Domain $DOMAIN does not resolve to an IP address"
        print_warning "SSL setup may fail if DNS is not properly configured"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    echo ""
}

################################################################################
# Installation Steps
################################################################################

install_nginx() {
    print_header "Installing Nginx"

    # Update package list
    print_info "Updating package list..."
    apt-get update -qq

    # Install Nginx
    if ! command -v nginx &> /dev/null; then
        print_info "Installing Nginx..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
        print_success "Nginx installed successfully"
    else
        print_success "Nginx already installed"
    fi

    # Ensure Nginx is enabled and started
    systemctl enable nginx
    systemctl start nginx
    print_success "Nginx service enabled and started"

    echo ""
}

create_webroot() {
    print_header "Creating Document Root"

    # Create document root directory
    if [ ! -d "$WEBROOT" ]; then
        mkdir -p "$WEBROOT"
        print_success "Created directory: $WEBROOT"
    else
        print_success "Directory already exists: $WEBROOT"
    fi

    # Create a temporary index.html
    cat > "$WEBROOT/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Lyra Documentation</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            text-align: center;
        }
        h1 { color: #3949ab; }
        p { color: #666; }
        .info { background: #e3f2fd; padding: 15px; border-radius: 5px; margin: 20px 0; }
    </style>
</head>
<body>
    <h1>Lyra Documentation</h1>
    <div class="info">
        <p><strong>Server is ready!</strong></p>
        <p>Deploy your documentation using the deploy script:</p>
        <code>./deploy.sh --server YOUR_DOMAIN --user YOUR_USER</code>
    </div>
    <p>This is a placeholder page. Your documentation will appear here after deployment.</p>
</body>
</html>
EOF

    # Set proper ownership and permissions
    chown -R www-data:www-data "$WEBROOT"
    chmod -R 755 "$WEBROOT"
    find "$WEBROOT" -type f -exec chmod 644 {} \;
    print_success "Set proper permissions on $WEBROOT"

    echo ""
}

configure_nginx() {
    print_header "Configuring Nginx"

    # Backup existing configuration if it exists
    if [ -f "/etc/nginx/sites-available/lyra-docs" ]; then
        cp "/etc/nginx/sites-available/lyra-docs" "/etc/nginx/sites-available/lyra-docs.backup.$(date +%Y%m%d-%H%M%S)"
        print_info "Backed up existing configuration"
    fi

    # Create Nginx configuration
    cat > /etc/nginx/sites-available/lyra-docs << EOF
# Lyra Documentation - Nginx Configuration
# Generated: $(date)
# Domain: $DOMAIN

server {
    listen 80;
    listen [::]:80;

    server_name $DOMAIN;

    # Document root
    root $WEBROOT;
    index index.html;

    # Logging
    access_log /var/log/nginx/lyra-docs-access.log;
    error_log /var/log/nginx/lyra-docs-error.log;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/rss+xml
        font/truetype
        font/opentype
        application/vnd.ms-fontobject
        image/svg+xml;

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Main location block
    location / {
        try_files \$uri \$uri/ =404;
    }

    # Handle 404 errors
    error_page 404 /404.html;
    location = /404.html {
        internal;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }

    # Deny access to backup files
    location ~ ~$ {
        deny all;
    }
}
EOF

    print_success "Created Nginx configuration"

    # Enable site
    if [ ! -L "/etc/nginx/sites-enabled/lyra-docs" ]; then
        ln -s /etc/nginx/sites-available/lyra-docs /etc/nginx/sites-enabled/lyra-docs
        print_success "Enabled site"
    else
        print_success "Site already enabled"
    fi

    # Test Nginx configuration
    print_info "Testing Nginx configuration..."
    if nginx -t 2>&1 | grep -q "successful"; then
        print_success "Nginx configuration is valid"
    else
        print_error "Nginx configuration test failed"
        nginx -t
        exit 1
    fi

    # Reload Nginx
    systemctl reload nginx
    print_success "Nginx reloaded"

    echo ""
}

setup_ssl() {
    if [ "$SKIP_SSL" = true ]; then
        print_header "Skipping SSL Setup"
        print_warning "SSL setup skipped - site will only be available via HTTP"
        print_warning "To add SSL later, run: certbot --nginx -d $DOMAIN"
        echo ""
        return
    fi

    print_header "Setting Up SSL with Let's Encrypt"

    # Install certbot
    if ! command -v certbot &> /dev/null; then
        print_info "Installing certbot..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y certbot python3-certbot-nginx
        print_success "Certbot installed"
    else
        print_success "Certbot already installed"
    fi

    # Run certbot
    print_info "Obtaining SSL certificate from Let's Encrypt..."
    print_warning "This requires that $DOMAIN points to this server's IP address"

    if certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL" --redirect; then
        print_success "SSL certificate obtained and configured"
        print_success "Your site is now available at https://$DOMAIN"
    else
        print_error "Failed to obtain SSL certificate"
        print_warning "Common reasons:"
        print_warning "  - Domain does not point to this server"
        print_warning "  - Port 80 is not accessible from the internet"
        print_warning "  - Firewall blocking HTTP traffic"
        print_info "You can manually retry later with:"
        print_info "  sudo certbot --nginx -d $DOMAIN"
    fi

    # Set up automatic renewal
    if command -v certbot &> /dev/null; then
        systemctl enable certbot.timer
        print_success "Automatic SSL renewal enabled"
    fi

    echo ""
}

configure_firewall() {
    if [ "$SKIP_FIREWALL" = true ]; then
        print_header "Skipping Firewall Configuration"
        print_warning "Firewall configuration skipped"
        echo ""
        return
    fi

    print_header "Configuring Firewall"

    # Check if ufw is installed and active
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "Status: active"; then
            print_info "UFW firewall is active - configuring rules..."

            # Allow SSH (to prevent lockout)
            ufw allow OpenSSH

            # Allow HTTP and HTTPS
            ufw allow 'Nginx Full'

            print_success "Firewall rules configured"
            print_info "Allowed: SSH, HTTP (80), HTTPS (443)"
        else
            print_info "UFW is installed but not active"
            print_warning "Enable it with: sudo ufw enable"
        fi
    else
        print_info "UFW firewall not installed - skipping firewall configuration"
    fi

    echo ""
}

################################################################################
# Final Summary
################################################################################

print_summary() {
    print_header "Installation Complete!"

    echo -e "${GREEN}"
    echo "✓ Nginx web server installed and configured"
    echo "✓ Document root created: $WEBROOT"
    echo "✓ Site configuration created"
    echo "✓ Proper permissions set"

    if [ "$SKIP_SSL" = false ]; then
        echo "✓ SSL/HTTPS configured with Let's Encrypt"
    fi

    if [ "$SKIP_FIREWALL" = false ]; then
        echo "✓ Firewall configured"
    fi
    echo -e "${NC}"

    echo ""
    print_info "Next Steps:"
    echo ""
    echo "1. Test your site:"
    if [ "$SKIP_SSL" = false ]; then
        echo "   https://$DOMAIN"
    else
        echo "   http://$DOMAIN"
    fi
    echo ""
    echo "2. Deploy your documentation:"
    echo "   cd /path/to/lyra-docs"
    echo "   ./build.sh"
    echo "   ./deploy.sh --server $DOMAIN --user \$(whoami)"
    echo ""
    echo "3. View logs:"
    echo "   sudo tail -f /var/log/nginx/lyra-docs-access.log"
    echo "   sudo tail -f /var/log/nginx/lyra-docs-error.log"
    echo ""

    if [ "$SKIP_SSL" = true ]; then
        print_warning "To add SSL/HTTPS later:"
        echo "   sudo certbot --nginx -d $DOMAIN"
        echo ""
    fi

    print_success "Your documentation server is ready!"
    echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
    # Check if running as root
    check_root

    # Validate arguments
    validate_args

    # Show configuration
    print_header "Installation Configuration"
    echo "Domain:          $DOMAIN"
    echo "Email:           $EMAIL"
    echo "Document Root:   $WEBROOT"
    echo "SSL Setup:       $([ "$SKIP_SSL" = false ] && echo "Yes" || echo "No")"
    echo "Firewall Setup:  $([ "$SKIP_FIREWALL" = false ] && echo "Yes" || echo "No")"
    echo ""
    read -p "Proceed with installation? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
    echo ""

    # Run installation steps
    check_system
    install_nginx
    create_webroot
    configure_nginx
    setup_ssl
    configure_firewall

    # Show summary
    print_summary
}

# Run main function
main "$@"
