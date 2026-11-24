#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
cd "$PROJECT_DIR"

# Load .env if present
if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

SERVER_PORT="${SERVER_PORT:-8080}"
FRONTEND_PORT="${FRONTEND_PORT:-3000}"
DB_PORT="${DB_PORT:-5434}"
DB_NAME="${DB_NAME:-map_db}"

echo "=================================================="
echo "          🚀 Starting EkRide Full Stack           "
echo "=================================================="

# 1. Start Database if not running
echo "[1/3] Checking Database (PostgreSQL $DB_PORT)..."
"$PROJECT_DIR/scripts/start_db.sh"

# 2. Free ports if occupied
fuser -k "${SERVER_PORT}/tcp" "${FRONTEND_PORT}/tcp" 2>/dev/null || true
sleep 1

mkdir -p "$PROJECT_DIR/logs"

# Check if background mode requested
IS_BG=false
if [ "$1" == "--background" ] || [ "$1" == "-d" ] || [ "$1" == "--bg" ]; then
    IS_BG=true
fi

# 3. Start Backend
echo "[2/3] Starting Spring Boot Backend on http://localhost:${SERVER_PORT}..."
cd "$PROJECT_DIR/backend"
setsid mvn spring-boot:run </dev/null > "$PROJECT_DIR/logs/backend.log" 2>&1 &
BACKEND_PID=$!
echo "Backend process launched (PID: $BACKEND_PID, Log: logs/backend.log)"

# Wait for backend to respond
echo -n "Waiting for backend to be online"
for i in {1..40}; do
    if curl -s -I "http://localhost:${SERVER_PORT}/api/v1/routes/autocomplete?query=test" >/dev/null 2>&1; then
        echo " ✓"
        echo "✓ Backend is online on http://localhost:${SERVER_PORT}"
        break
    fi
    echo -n "."
    sleep 1
done

# 4. Start Frontend
echo "[3/3] Starting Frontend Web Server on http://localhost:${FRONTEND_PORT}..."
cd "$PROJECT_DIR"
if [ "$IS_BG" = true ]; then
    setsid python3 "$PROJECT_DIR/scripts/serve_web.py" "$FRONTEND_PORT" </dev/null > "$PROJECT_DIR/logs/frontend.log" 2>&1 &
    FRONTEND_PID=$!
    echo "Frontend process launched (PID: $FRONTEND_PID, Log: logs/frontend.log)"
    echo ""
    echo "=================================================="
    echo "  🎉 EkRide started in background (Daemon Mode)!"
    echo "  🌐 Frontend:  http://localhost:${FRONTEND_PORT}"
    echo "  ⚙️  Backend:   http://localhost:${SERVER_PORT}"
    echo "  🗄️  Database:  localhost:${DB_PORT} (${DB_NAME})"
    echo "  🛑 Stop with: ./stop.sh"
    echo "=================================================="
    exit 0
else
    cleanup() {
        echo ""
        echo "Stopping EkRide services..."
        fuser -k "${SERVER_PORT}/tcp" "${FRONTEND_PORT}/tcp" 2>/dev/null || true
        pkill -f "serve_web.py" 2>/dev/null || true
        pkill -f "ekride-backend" 2>/dev/null || true
        pkill -f "spring-boot:run" 2>/dev/null || true
        echo "✓ All services stopped."
        exit 0
    }
    trap cleanup SIGINT SIGTERM

    echo ""
    echo "=================================================="
    echo "  🎉 EkRide is running successfully!"
    echo "  🌐 Frontend:  http://localhost:${FRONTEND_PORT}"
    echo "  ⚙️  Backend:   http://localhost:${SERVER_PORT}"
    echo "  🗄️  Database:  localhost:${DB_PORT} (${DB_NAME})"
    echo "  📝 Logs:      $PROJECT_DIR/logs/backend.log"
    echo "=================================================="
    echo "  Press Ctrl + C anytime to stop all services."
    echo "=================================================="
    python3 "$PROJECT_DIR/scripts/serve_web.py" "$FRONTEND_PORT"
fi
