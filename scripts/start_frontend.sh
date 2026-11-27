#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load .env if present
if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

PORT="${FRONTEND_PORT:-3000}"
echo "Starting EkRide Flutter Web on http://localhost:$PORT..."
python3 "$SCRIPT_DIR/serve_web.py" "$PORT"
