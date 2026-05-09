#!/bin/bash
# =============================================================================
# 顺时 ShunShi — 数据库自动备份脚本
# =============================================================================
set -e

BACKUP_DIR="${BACKUP_DIR:-/opt/backups/shunshi}"
DB_TYPE="${DB_TYPE:-sqlite}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
SQLITE_DB="${SQLITE_DB:-/opt/shunshi/backend/data/shunshi.db}"
PG_HOST="${PG_HOST:-localhost}"
PG_PORT="${PG_PORT:-5432}"
PG_DB="${PG_DB:-shunshi}"
PG_USER="${PG_USER:-shunshi}"
PG_PASSWORD="${PG_PASSWORD:-}"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

backup_sqlite() {
    BACKUP_FILE="$BACKUP_DIR/shunshi_${TIMESTAMP}.db.gz"
    sqlite3 "$SQLITE_DB" ".backup '${BACKUP_DIR}/shunshi_${TIMESTAMP}.tmp'"
    gzip -c "${BACKUP_DIR}/shunshi_${TIMESTAMP}.tmp" > "$BACKUP_FILE"
    rm -f "${BACKUP_DIR}/shunshi_${TIMESTAMP}.tmp"
    echo "$BACKUP_FILE"
}

backup_postgresql() {
    BACKUP_FILE="$BACKUP_DIR/shunshi_${TIMESTAMP}.sql.gz"
    export PGPASSWORD="$PG_PASSWORD"
    pg_dump -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" --clean | gzip > "$BACKUP_FILE"
    echo "$BACKUP_FILE"
}

main() {
    log "========== 数据库备份开始 =========="
    case "$DB_TYPE" in
        sqlite) BACKUP_FILE=$(backup_sqlite) ;;
        postgresql) BACKUP_FILE=$(backup_postgresql) ;;
        *) log "错误: 不支持的数据库类型: $DB_TYPE"; exit 1 ;;
    esac
    
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log "备份完成: $(basename $BACKUP_FILE) ($SIZE)"
    
    # 清理旧备份
    DELETED=$(find "$BACKUP_DIR" -name "shunshi_*.gz" -mtime +$RETENTION_DAYS -delete -print | wc -l)
    log "已删除 $DELETED 个旧备份"
    
    log "========== 备份完成 =========="
}

main "$@"
