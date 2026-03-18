-- ============================================================
-- backup.sql  —  Plan de backup y recuperación
-- Ride-Hailing Database  |  MySQL 8.0
-- (Tema 6 — Recuperación y Continuidad del Servicio)
-- ============================================================
-- ESTRATEGIA:
--   RPO = 1 hora  → binlog captura todos los cambios entre backups
--   RTO = 4 horas → restore completo + replay de binlog
--
--   1. Backup completo diario con mysqldump a las 03:00
--   2. Binlog continuo (ROW) para PITR entre backups
--   3. Retención: 7 días de backups + 7 días de binlogs
-- ============================================================

-- ------------------------------------------------------------
-- PARTE 1: VERIFICAR CONFIGURACIÓN DEL BINLOG
-- Necesario para PITR (Tema 6 — Point-in-Time Recovery)
-- Configurado en mysql/conf.d/custom.cnf
-- ------------------------------------------------------------
SHOW VARIABLES LIKE 'log_bin';                    -- debe ser ON
SHOW VARIABLES LIKE 'binlog_format';              -- debe ser ROW
SHOW VARIABLES LIKE 'binlog_expire_logs_seconds'; -- 604800 = 7 días
SHOW BINARY LOGS;                                 -- binlogs disponibles

-- ------------------------------------------------------------
-- PARTE 2: VERIFICACIÓN DE INTEGRIDAD POST-RESTORE
-- Ejecutar después de restaurar un backup para validar coherencia
-- (Tema 6 — Verificación post-restore)
-- ------------------------------------------------------------
USE ridehailing;

-- 2.1. Conteo de filas por tabla
SELECT 'company'    AS tabla, COUNT(*) AS filas FROM company
UNION ALL
SELECT 'usuario',   COUNT(*) FROM usuario
UNION ALL
SELECT 'conductor', COUNT(*) FROM conductor
UNION ALL
SELECT 'vehiculo',  COUNT(*) FROM vehiculo
UNION ALL
SELECT 'viaje',     COUNT(*) FROM viaje
UNION ALL
SELECT 'oferta',    COUNT(*) FROM oferta
UNION ALL
SELECT 'pago',      COUNT(*) FROM pago
UNION ALL
SELECT 'auditoria', COUNT(*) FROM auditoria;

-- 2.2. Verificar integridad referencial
-- No debe devolver ninguna fila con n > 0
SELECT 'FK viaje→rider rota' AS problema, COUNT(*) AS n
FROM viaje v
LEFT JOIN usuario u ON u.id_usuario = v.id_rider
WHERE u.id_usuario IS NULL

UNION ALL
SELECT 'FK viaje→conductor rota', COUNT(*)
FROM viaje v
LEFT JOIN conductor c ON c.id_conductor = v.id_conductor
WHERE v.id_conductor IS NOT NULL AND c.id_conductor IS NULL

UNION ALL
SELECT 'FK oferta→viaje rota', COUNT(*)
FROM oferta o
LEFT JOIN viaje v ON v.id_viaje = o.id_viaje
WHERE v.id_viaje IS NULL

UNION ALL
SELECT 'FK pago→viaje rota', COUNT(*)
FROM pago p
LEFT JOIN viaje v ON v.id_viaje = p.id_viaje
WHERE v.id_viaje IS NULL;

-- 2.3. Verificar FK en information_schema
-- (Tema 6 — Verificar integridad de FKs)
SELECT TABLE_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA       = 'ridehailing'
  AND REFERENCED_TABLE_NAME IS NOT NULL;

-- ------------------------------------------------------------
-- PARTE 3: COMANDOS DE BACKUP Y RESTORE
-- (Tema 6 — mysqldump; comandos documentados como referencia)
-- ------------------------------------------------------------

-- BACKUP COMPLETO (ejecutar desde el host, no dentro de MySQL):
--
--   docker exec mysql8 mysqldump \
--     -uroot -prootpass \
--     --databases ridehailing \
--     --single-transaction \
--     --routines --triggers --events \
--     --set-gtid-purged=OFF \
--     | gzip > backups/backup_$(date +%Y%m%d_%H%M%S).sql.gz
--
-- --single-transaction: snapshot consistente sin bloquear (InnoDB)
-- --routines:           incluye stored procedures
-- --triggers:           incluye triggers
-- --set-gtid-purged=OFF: no incluir info GTID (no usamos replicación)

-- RESTORE:
--
--   zcat backups/backup_YYYYMMDD.sql.gz | \
--     docker exec -i mysql8 mysql -uroot -prootpass

-- PITR — recuperar hasta un punto en el tiempo:
-- (Tema 6 — Point-in-Time Recovery con mysqlbinlog)
--
-- Paso 1: restaurar el backup completo más reciente (ver RESTORE arriba)
--
-- Paso 2: localizar el evento problemático en el binlog
--   docker exec mysql8 mysqlbinlog \
--     --start-datetime="YYYY-MM-DD HH:MM:00" \
--     --stop-datetime="YYYY-MM-DD HH:MM:59" \
--     /var/lib/mysql/mysql-bin.000001 | grep -B5 -A5 "DELETE\|DROP"
--
-- Paso 3: aplicar binlog hasta el momento justo antes del error
--   docker exec mysql8 mysqlbinlog \
--     --start-datetime="YYYY-MM-DD 03:00:00" \
--     --stop-datetime="YYYY-MM-DD HH:MM:SS" \
--     /var/lib/mysql/mysql-bin.000001 | \
--     docker exec -i mysql8 mysql -uroot -prootpass
