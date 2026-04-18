-- ============================================================
-- Practica Ride Hailing - BBDD Avanazadas
-- Autores: Javier Picazo, Alejandro Bernaldo de Quiros, Pablo Cerdeira y Jaime Ordovás
-- Grupo: 3A
-- ============================================================


-- verificar configuracion binlog
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'binlog_format';
SHOW VARIABLES LIKE 'binlog_expire_logs_seconds';
SHOW BINARY LOGS;


-- verificar integridad post-restore
USE ridehailing;


-- conteo de filas por tabla
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


-- verificar integridad referencial
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


-- verificar FK en information_schema
SELECT TABLE_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA       = 'ridehailing'
  AND REFERENCED_TABLE_NAME IS NOT NULL;





-- comandos de backup y restore:

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
