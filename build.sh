#!/bin/bash

# Lyra Documentation Build Script
# This script builds the MkDocs static site

set -e

echo "=========================================="
echo "Building Lyra Documentation"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Python and pip are installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}ERROR: Python 3 is not installed${NC}"
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Creating Python virtual environment...${NC}"
    python3 -m venv venv
fi

# Activate virtual environment
echo -e "${YELLOW}Activating virtual environment...${NC}"
source venv/bin/activate

# Install/upgrade dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
pip install --upgrade pip
pip install -r requirements.txt

# Build the site
echo -e "${YELLOW}Building MkDocs site...${NC}"
mkdocs build --clean --strict

# Check if build was successful
if [ -d "site" ]; then
    echo -e "${GREEN}=========================================="
    echo -e "Build completed successfully!"
    echo -e "==========================================${NC}"
    echo ""
    echo "Static files generated in: ./site/"
    echo ""
    echo "Next steps:"
    echo "  1. Review the generated site locally:"
    echo "     mkdocs serve"
    echo ""
    echo "  2. Deploy to web server:"
    echo "     ./deploy.sh [server-address]"
    echo ""
else
    echo -e "${RED}Build failed! Check the errors above.${NC}"
    exit 1
fi

# Deactivate virtual environment
deactivate
