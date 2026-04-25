#!/bin/bash
# backup_mysql.sh — Backup diario de ridehailing con rotación 7 días
# Cron: 0 3 * * * /ruta/proyecto/scripts/backup_mysql.sh >> /var/log/ridehailing_backup.log 2>&1

FECHA=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups"
RETENTION_DAYS=7

mkdir -p "${BACKUP_DIR}"

echo "[$(date)] Iniciando backup ridehailing..."

docker exec ridehailing-db mysqldump \
  -ubackup_user -p'Backup_Str0ng!' \
  --databases ridehailing \
  --single-transaction \
  --routines --triggers --events \
  --set-gtid-purged=OFF \
  | gzip > "${BACKUP_DIR}/backup_${FECHA}.sql.gz"

if [ $? -eq 0 ]; then
  echo "[$(date)] OK: backup_${FECHA}.sql.gz creado"
else
  echo "[$(date)] ERROR: backup fallido" >&2
  exit 1
fi

find "${BACKUP_DIR}" -name "backup_*.sql.gz" -mtime +${RETENTION_DAYS} -delete
echo "[$(date)] Backups con más de ${RETENTION_DAYS} días eliminados"
