#!/bin/bash
# backup-db.sh — PostgreSQL/MySQL backup with rotation
# Usage: ./backup-db.sh [--postgres|--mysql] [connection_string]
# Cron example: 0 2 * * * /usr/local/bin/backup-db.sh --postgres

set -euo pipefail

# Config
BACKUP_DIR="/var/backups/databases"
RETENTION_DAYS=30
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_TYPE="${1:---postgres}"
COMPRESS=true

# PostgreSQL defaults
PG_HOST="${PG_HOST:-localhost}"
PG_PORT="${PG_PORT:-5432}"
PG_USER="${PG_USER:-postgres}"

# MySQL defaults
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"

mkdir -p "$BACKUP_DIR"

backup_postgres() {
    local dbs
    dbs=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;" 2>/dev/null | sed 's/ //g')

    for db in $dbs; do
        local file="${BACKUP_DIR}/${db}_${TIMESTAMP}.sql"
        log "Backing up PostgreSQL: $db"
        pg_dump -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" "$db" > "$file"
        [[ "$COMPRESS" == true ]] && gzip "$file"
        log "  → ${file}.gz"
    done
}

backup_mysql() {
    local dbs
    dbs=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e "SHOW DATABASES;" -s 2>/dev/null | grep -v -E "Database|information_schema|performance_schema|sys")

    for db in $dbs; do
        local file="${BACKUP_DIR}/${db}_${TIMESTAMP}.sql"
        log "Backing up MySQL: $db"
        mysqldump -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" "$db" > "$file"
        [[ "$COMPRESS" == true ]] && gzip "$file"
        log "  → ${file}.gz"
    done
}

cleanup_old() {
    log "Cleaning backups older than $RETENTION_DAYS days..."
    find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete
    find "$BACKUP_DIR" -name "*.sql" -mtime +$RETENTION_DAYS -delete
}

log() { echo "[$(date +%H:%M:%S)] $1"; }

# Main
case "$DB_TYPE" in
    --postgres) backup_postgres ;;
    --mysql)    backup_mysql ;;
    *)          echo "Usage: $0 [--postgres|--mysql]"; exit 1 ;;
esac

cleanup_old
log "Backup complete"