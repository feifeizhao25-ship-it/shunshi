#!/usr/bin/env bash
# ShunShi Database Backup Script
# Cron: 0 3 * * * /opt/shunshi/deploy/backup.sh >> /var/log/shunshi-backup.log 2>&1

set -euo pipefail

# --- Config ---
DB_DIR="/opt/shunshi/backend"
SQLITE_DB="${DB_DIR}/shunshi.db"
BACKUP_DIR="/opt/shunshi/backups"
RETENTION_DAYS=7
LOG_FILE="/var/log/shunshi-backup.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_DIR=$(date +%Y-%m-%d)

# PostgreSQL config (override via env or .env file)
PG_DB="${SHUNSHI_PG_DB:-shunshi}"
PG_USER="${SHUNSHI_PG_USER:-shunshi}"
PG_HOST="${SHUNSHI_PG_HOST:-localhost}"
PG_PORT="${SHUNSHI_PG_PORT:-5432}"

# Load .env if present
ENV_FILE="${DB_DIR}/.env"
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

mkdir -p "$BACKUP_DIR" "$(dirname "$LOG_FILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

cleanup() {
    log "Cleaning backups older than ${RETENTION_DAYS} days"
    find "$BACKUP_DIR" -type f -name "*.gz" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true
    find "$BACKUP_DIR" -type d -empty -delete 2>/dev/null || true
}

# --- SQLite Backup ---
backup_sqlite() {
    if [[ ! -f "$SQLITE_DB" ]]; then
        log "SQLite: database not found at $SQLITE_DB, skipping"
        return 0
    fi

    local dest="${BACKUP_DIR}/${DATE_DIR}/sqlite"
    mkdir -p "$dest"
    local file="${dest}/shunshi_${TIMESTAMP}.db"

    # Use sqlite3 backup API for consistency
    if command -v sqlite3 &>/dev/null; then
        sqlite3 "$SQLITE_DB" ".backup '${file}'"
    else
        cp "$SQLITE_DB" "$file"
    fi

    gzip "$file"
    log "SQLite: backed up -> ${file}.gz ($(du -h "${file}.gz" | cut -f1))"
}

# --- PostgreSQL Backup ---
backup_postgres() {
    if ! command -v pg_dump &>/dev/null; then
        log "PostgreSQL: pg_dump not found, skipping"
        return 0
    fi

    # Check if DB is accessible
    if ! PGPASSWORD="${SHUNSHI_PG_PASSWORD:-}" pg_isready -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" &>/dev/null; then
        log "PostgreSQL: not reachable, skipping"
        return 0
    fi

    local dest="${BACKUP_DIR}/${DATE_DIR}/postgres"
    mkdir -p "$dest"
    local file="${dest}/shunshi_${TIMESTAMP}.sql.gz"

    PGPASSWORD="${SHUNSHI_PG_PASSWORD:-}" pg_dump \
        -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" "$PG_DB" \
        --no-owner --no-privileges | gzip > "$file"

    log "PostgreSQL: backed up -> $file ($(du -h "$file" | cut -f1))"
}

# --- Main ---
log "=== ShunShi backup started ==="
backup_sqlite
backup_postgres
cleanup
log "=== ShunShi backup completed ==="
