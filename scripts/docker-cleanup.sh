#!/bin/bash
# docker-cleanup.sh — Safe Docker system cleanup
# Removes unused images, stopped containers, build cache, and dangling volumes
# Does NOT remove running containers or named volumes in use

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# Check docker access
docker info &>/dev/null || { echo "Docker not accessible"; exit 1; }

AUTO_YES=false
for arg in "$@"; do
    case "$arg" in
        -y|--yes) AUTO_YES=true ;;
    esac
done

# Show before
log "Current Docker disk usage:"
docker system df

echo ""
warn "This will remove:"
echo "  - Stopped containers"
echo "  - Unused images (dangling + unreferenced)"
echo "  - Build cache"
echo "  - Unused networks"
echo "  - Dangling (unnamed) volumes"
echo ""
if [[ "$AUTO_YES" != true ]]; then
    read -p "Continue? [y/N] " -n 1 -r
    echo ""
    [[ ! $REPLY =~ ^[Yy]$ ]] && { echo "Aborted"; exit 0; }
fi

# Cleanup
log "Removing stopped containers..."
docker container prune -f

log "Removing unused images..."
docker image prune -a -f

log "Removing build cache..."
docker builder prune -f

log "Removing unused networks..."
docker network prune -f

log "Removing dangling volumes..."
docker volume prune -f

# Show after
echo ""
log "Docker disk usage after cleanup:"
docker system df