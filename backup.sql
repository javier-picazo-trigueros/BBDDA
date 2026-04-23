-- ============================================================
-- Practica Ride Hailing - BBDD Avanazadas
-- Autores: Javier Picazo, Alejandro Bernaldo de Quiros, Pablo Cerdeira y Jaime Ordovás
-- Grupo: 3A
-- ============================================================


-- Verificar configuracion de binlog
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'binlog_format';
SHOW VARIABLES LIKE 'binlog_expire_logs_seconds';
SHOW BINARY LOGS;


-- Verificar integridad tras la restauracion
USE ridehailing;


-- Conteo de filas por tabla
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


-- Verificar integridad referencial
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


-- Verificar claves foraneas registradas
SELECT TABLE_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA       = 'ridehailing'
  AND REFERENCED_TABLE_NAME IS NOT NULL;





-- Comandos de backup y restore

-- Backup completo (ejecutar desde el host):
--
--   docker exec ridehailing-db mysqldump \
--     -uroot -prootpass \
--     --databases ridehailing \
--     --single-transaction \
--     --routines --triggers --events \
--     --set-gtid-purged=OFF \
--     | gzip > backups/backup_$(date +%Y%m%d_%H%M%S).sql.gz
--
-- Restore:
--
--   zcat backups/backup_YYYYMMDD.sql.gz | \
--     docker exec -i ridehailing-db mysql -uroot -prootpass

-- Recuperacion hasta un punto en el tiempo:
--
-- Paso 1: restaurar el backup completo mas reciente
--
-- Paso 2: localizar el evento problematico en el binlog
--   docker exec ridehailing-db mysqlbinlog \
--     --start-datetime="YYYY-MM-DD HH:MM:00" \
--     --stop-datetime="YYYY-MM-DD HH:MM:59" \
--     /var/lib/mysql/mysql-bin.000001 | grep -B5 -A5 "DELETE\|DROP"
--
-- Paso 3: aplicar binlog hasta el momento previo al error
--   docker exec ridehailing-db mysqlbinlog \
--     --start-datetime="YYYY-MM-DD 03:00:00" \
--     --stop-datetime="YYYY-MM-DD HH:MM:SS" \
--     /var/lib/mysql/mysql-bin.000001 | \
--     docker exec -i ridehailing-db mysql -uroot -prootpass
