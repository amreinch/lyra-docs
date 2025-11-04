#!/bin/bash
# Docker deployment script for Lyra Documentation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    # Check for docker-compose (standalone) or docker compose (plugin)
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
    elif docker compose version &> /dev/null 2>&1; then
        DOCKER_COMPOSE="docker compose"
    else
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
}

show_usage() {
    cat << EOF
Lyra Documentation - Docker Deployment Script

Usage: ./docker-deploy.sh [COMMAND]

Commands:
    start       Build and start the documentation container (default)
    stop        Stop the documentation container
    restart     Restart the documentation container
    rebuild     Rebuild the container from scratch (no cache)
    update      Pull latest changes, rebuild, and restart
    logs        Show container logs (follow mode)
    status      Show container status
    shell       Open a shell inside the container
    clean       Stop and remove container and images
    help        Show this help message

Examples:
    ./docker-deploy.sh              # Start the documentation
    ./docker-deploy.sh rebuild      # Rebuild from scratch
    ./docker-deploy.sh logs         # View logs
    ./docker-deploy.sh update       # Update documentation

EOF
}

cmd_start() {
    log_info "Starting Lyra Documentation container..."
    $DOCKER_COMPOSE up -d
    log_info "Documentation is now running at http://localhost:8081"
}

cmd_stop() {
    log_info "Stopping Lyra Documentation container..."
    $DOCKER_COMPOSE down
    log_info "Container stopped"
}

cmd_restart() {
    log_info "Restarting Lyra Documentation container..."
    $DOCKER_COMPOSE restart
    log_info "Container restarted"
}

cmd_rebuild() {
    log_info "Rebuilding Lyra Documentation container (no cache)..."
    $DOCKER_COMPOSE down
    $DOCKER_COMPOSE build --no-cache
    $DOCKER_COMPOSE up -d
    log_info "Container rebuilt and started"
}

cmd_update() {
    log_info "Updating Lyra Documentation..."

    # Check if git repo
    if [ -d .git ]; then
        log_info "Pulling latest changes from git..."
        git pull
    else
        log_warn "Not a git repository, skipping git pull"
    fi

    log_info "Rebuilding container..."
    $DOCKER_COMPOSE down
    $DOCKER_COMPOSE build --no-cache
    $DOCKER_COMPOSE up -d
    log_info "Documentation updated and restarted"
}

cmd_logs() {
    log_info "Showing container logs (Ctrl+C to exit)..."
    $DOCKER_COMPOSE logs -f
}

cmd_status() {
    log_info "Container status:"
    $DOCKER_COMPOSE ps
}

cmd_shell() {
    log_info "Opening shell in container..."
    $DOCKER_COMPOSE exec lyra-docs sh
}

cmd_clean() {
    log_warn "This will stop and remove the container and images. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Cleaning up..."
        $DOCKER_COMPOSE down
        docker rmi lyra-docs:latest 2>/dev/null || true
        log_info "Cleanup complete"
    else
        log_info "Cleanup cancelled"
    fi
}

# Main
check_docker

COMMAND="${1:-start}"

case "$COMMAND" in
    start)
        cmd_start
        ;;
    stop)
        cmd_stop
        ;;
    restart)
        cmd_restart
        ;;
    rebuild)
        cmd_rebuild
        ;;
    update)
        cmd_update
        ;;
    logs)
        cmd_logs
        ;;
    status)
        cmd_status
        ;;
    shell)
        cmd_shell
        ;;
    clean)
        cmd_clean
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac
