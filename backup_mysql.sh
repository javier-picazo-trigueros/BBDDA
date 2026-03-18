#!/bin/bash
# backup_mysql.sh — Backup diario de ridehailing con rotación 7 días

FECHA=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups"
RETENTION_DAYS=7

mkdir -p "${BACKUP_DIR}"

echo "[$(date)] Iniciando backup ridehailing..."

docker exec mysql8 mysqldump \
  -uroot -prootpass \
  --databases ridehailing \
  --single-transaction \
  --routines --triggers --events \
  --set-gtid-purged=OFF \
  | gzip > "${BACKUP_DIR}/backup_${FECHA}.sql.gz"

if [ $? -eq 0 ]; then
  echo "[$(date)] Backup OK: backup_${FECHA}.sql.gz"
else
  echo "[$(date)] ERROR: backup fallido" >&2
  exit 1
fi

# Rotar backups antiguos
find "${BACKUP_DIR}" -name "backup_*.sql.gz" -mtime +${RETENTION_DAYS} -delete
echo "[$(date)] Backups con más de ${RETENTION_DAYS} días eliminados"
