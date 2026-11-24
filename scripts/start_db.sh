#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load .env if present
if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5434}"
DB_NAME="${DB_NAME:-map_db}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"

echo "Checking PostgreSQL connection on $DB_HOST:$DB_PORT ($DB_NAME)..."

# Helper function to test DB connection
check_db_ready() {
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1
}

# 1. Already running?
if check_db_ready; then
    echo "✓ PostgreSQL is already running and ready on $DB_HOST:$DB_PORT ($DB_NAME)."
    exit 0
fi

# 2. Try Docker Compose if docker daemon is reachable
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    echo "PostgreSQL not running. Attempting to start via Docker Compose..."
    if (cd "$PROJECT_DIR" && docker compose up -d postgres 2>/dev/null) || (cd "$PROJECT_DIR" && docker-compose up -d postgres 2>/dev/null); then
        # Wait for Docker container to be ready
        for i in {1..15}; do
            if check_db_ready; then
                echo "✓ PostgreSQL container ready on port $DB_PORT ($DB_NAME)."
                exit 0
            fi
            sleep 1
        done
    fi
fi

# 3. Try local pg_ctl if path exists (e.g. host user data dir)
LOCAL_PG_DATA="$HOME/.local/share/ekride_postgres/data"
LOCAL_PG_LOG="$HOME/.local/share/ekride_postgres/logfile"
if [ -d "$LOCAL_PG_DATA" ]; then
    echo "Found local PostgreSQL data cluster at $LOCAL_PG_DATA. Attempting pg_ctl start..."
    PG_CTL=$(command -v pg_ctl || find /usr/lib/postgresql/ -name pg_ctl 2>/dev/null | sort -V | tail -n 1)
    if [ -n "$PG_CTL" ] && [ -x "$PG_CTL" ]; then
        "$PG_CTL" -D "$LOCAL_PG_DATA" -l "$LOCAL_PG_LOG" start 2>/dev/null || true
        sleep 2
        if check_db_ready; then
            echo "✓ Local PostgreSQL started on port $DB_PORT ($DB_NAME)."
            exit 0
        fi
    fi
fi

# 4. If neither worked, inform user
echo "⚠️  Could not automatically start PostgreSQL on $DB_HOST:$DB_PORT."
echo "Please start PostgreSQL using one of the following options:"
echo "  Option A (Docker):  docker compose up -d"
echo "  Option B (System):  Ensure PostgreSQL is running on port $DB_PORT with database '$DB_NAME' and user '$DB_USER'"
exit 1
