#!/bin/bash

# Lyra Documentation Deployment Script
# This script deploys the built documentation to your web server

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
WEB_SERVER=""
WEB_USER="www-data"
WEB_PATH="/var/www/lyra-docs"
SSH_KEY=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--server)
            WEB_SERVER="$2"
            shift 2
            ;;
        -u|--user)
            WEB_USER="$2"
            shift 2
            ;;
        -p|--path)
            WEB_PATH="$2"
            shift 2
            ;;
        -k|--key)
            SSH_KEY="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -s, --server SERVER    Web server address (required)"
            echo "  -u, --user USER        SSH user (default: www-data)"
            echo "  -p, --path PATH        Deployment path (default: /var/www/lyra-docs)"
            echo "  -k, --key KEY          SSH private key file"
            echo "  -h, --help             Show this help message"
            echo ""
            echo "Example:"
            echo "  $0 --server docs.lyra.ovh --user ubuntu --path /var/www/lyra-docs"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$WEB_SERVER" ]; then
    echo -e "${RED}ERROR: Web server address is required${NC}"
    echo "Usage: $0 --server SERVER [OPTIONS]"
    echo "Use --help for more information"
    exit 1
fi

echo "=========================================="
echo "Deploying Lyra Documentation"
echo "=========================================="
echo "Server: $WEB_SERVER"
echo "User: $WEB_USER"
echo "Path: $WEB_PATH"
echo "=========================================="

# Check if site directory exists
if [ ! -d "site" ]; then
    echo -e "${RED}ERROR: Built site not found!${NC}"
    echo "Run ./build.sh first to build the documentation"
    exit 1
fi

# Build SSH command options
SSH_OPTS=""
if [ -n "$SSH_KEY" ]; then
    SSH_OPTS="-i $SSH_KEY"
fi

# Create backup of existing site on server
echo -e "${YELLOW}Creating backup of existing site...${NC}"
ssh $SSH_OPTS ${WEB_USER}@${WEB_SERVER} "if [ -d '$WEB_PATH' ]; then sudo tar -czf ${WEB_PATH}.backup-\$(date +%Y%m%d-%H%M%S).tar.gz -C $WEB_PATH . 2>/dev/null || true; fi"

# Create target directory if it doesn't exist
echo -e "${YELLOW}Preparing target directory...${NC}"
ssh $SSH_OPTS ${WEB_USER}@${WEB_SERVER} "sudo mkdir -p $WEB_PATH"

# Sync files to web server
echo -e "${YELLOW}Syncing files to web server...${NC}"
if [ -n "$SSH_KEY" ]; then
    rsync -avz --delete -e "ssh $SSH_OPTS" site/ ${WEB_USER}@${WEB_SERVER}:~/lyra-docs-temp/
else
    rsync -avz --delete site/ ${WEB_USER}@${WEB_SERVER}:~/lyra-docs-temp/
fi

# Move files to final location with proper permissions
echo -e "${YELLOW}Setting permissions and moving to final location...${NC}"
ssh $SSH_OPTS ${WEB_USER}@${WEB_SERVER} "
    sudo rm -rf $WEB_PATH/*
    sudo mv ~/lyra-docs-temp/* $WEB_PATH/
    sudo chown -R www-data:www-data $WEB_PATH
    sudo chmod -R 755 $WEB_PATH
    sudo find $WEB_PATH -type f -exec chmod 644 {} \;
    rm -rf ~/lyra-docs-temp
"

# Test web server configuration (if nginx)
echo -e "${YELLOW}Testing web server configuration...${NC}"
ssh $SSH_OPTS ${WEB_USER}@${WEB_SERVER} "
    if command -v nginx &> /dev/null; then
        sudo nginx -t && echo 'Nginx configuration OK'
    elif command -v apache2ctl &> /dev/null; then
        sudo apache2ctl configtest && echo 'Apache configuration OK'
    fi
" || echo -e "${YELLOW}Web server configuration test not available${NC}"

echo -e "${GREEN}=========================================="
echo -e "Deployment completed successfully!"
echo -e "==========================================${NC}"
echo ""
echo "Documentation is now available at: https://$WEB_SERVER"
echo ""
echo "To rollback if needed, backups are stored on the server:"
echo "  ssh $WEB_USER@$WEB_SERVER 'ls -lh ${WEB_PATH}.backup-*'"
