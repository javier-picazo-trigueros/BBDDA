-- ============================================================
-- backup.sql  —  Plan de backup y recuperación
-- Ride-Hailing Database  |  MySQL 8.0
-- ============================================================
-- ESTRATEGIA:
--   RPO = 1 hora  (pérdida máxima tolerable de datos)
--   RTO = 4 horas (tiempo máximo de recuperación)
--
--   1. Backup completo diario (mysqldump, 03:00 AM)
--   2. Binlog continuo para PITR entre backups
--   3. Retención: 7 días de backups completos + 7 días de binlogs
-- ============================================================

-- ============================================================
-- PARTE 1: VERIFICAR QUE EL BINLOG ESTÁ ACTIVADO
-- (necesario para PITR – ya configurado en custom.cnf)
-- ============================================================
SHOW VARIABLES LIKE 'log_bin';               -- Debe ser ON
SHOW VARIABLES LIKE 'binlog_format';         -- Debe ser ROW
SHOW VARIABLES LIKE 'binlog_expire_logs_seconds'; -- 604800 = 7 días
SHOW BINARY LOGS;                            -- Ver binlogs disponibles

-- ============================================================
-- PARTE 2: VERIFICACIÓN RÁPIDA DE INTEGRIDAD POST-RESTORE
-- ============================================================
-- Ejecutar después de restaurar para validar que los datos son coherentes
USE ridehailing;

SELECT 'company'   AS tabla, COUNT(*) AS filas FROM company
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

-- Verificar integridad referencial (no debe devolver filas)
SELECT 'FK viaje→rider rota'     AS problema, COUNT(*) AS n FROM viaje  v LEFT JOIN usuario   u  ON u.id_usuario   = v.id_rider       WHERE u.id_usuario IS NULL
UNION ALL
SELECT 'FK viaje→conductor rota', COUNT(*) FROM viaje  v LEFT JOIN conductor c  ON c.id_conductor = v.id_conductor  WHERE v.id_conductor IS NOT NULL AND c.id_conductor IS NULL
UNION ALL
SELECT 'FK oferta→viaje rota',    COUNT(*) FROM oferta o LEFT JOIN viaje     vj ON vj.id_viaje    = o.id_viaje       WHERE vj.id_viaje IS NULL
UNION ALL
SELECT 'FK pago→viaje rota',      COUNT(*) FROM pago   p LEFT JOIN viaje     vj ON vj.id_viaje    = p.id_viaje       WHERE vj.id_viaje IS NULL;

-- ============================================================
-- PARTE 3: PITR - recuperación a un punto en el tiempo
-- (comandos de shell, documentados aquí como referencia)
-- ============================================================
-- Paso 1: Restaurar el backup completo más reciente
--   cat backups/backup_YYYYMMDD_0300.sql.gz | zcat | docker exec -i mysql8 mysql -uroot -prootpass

-- Paso 2: Localizar el evento problemático en el binlog
--   docker exec mysql8 mysqlbinlog \
--     --start-datetime="YYYY-MM-DD HH:MM:00" \
--     --stop-datetime="YYYY-MM-DD HH:MM:59" \
--     /var/lib/mysql/binlog.000001 | grep -B5 -A5 "DELETE\|DROP"

-- Paso 3: Aplicar binlog hasta el momento justo antes del error
--   docker exec mysql8 mysqlbinlog \
--     --start-datetime="YYYY-MM-DD 03:00:00" \
--     --stop-datetime="YYYY-MM-DD HH:MM:SS" \
--     /var/lib/mysql/binlog.000001 | docker exec -i mysql8 mysql -uroot -prootpass
