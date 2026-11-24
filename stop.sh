#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

SERVER_PORT="${SERVER_PORT:-8080}"
FRONTEND_PORT="${FRONTEND_PORT:-3000}"

echo "Stopping all EkRide services..."
fuser -k "${SERVER_PORT}/tcp" "${FRONTEND_PORT}/tcp" 2>/dev/null || true
pkill -f "serve_web.py" 2>/dev/null || true
pkill -f "ekride-backend" 2>/dev/null || true
pkill -f "spring-boot:run" 2>/dev/null || true
echo "✓ Ports ${SERVER_PORT} (backend) and ${FRONTEND_PORT} (frontend) released."
echo "✓ All EkRide services stopped."
