-- ============================================================
-- Practica Ride Hailing - BBDD Avanazadas
-- Autores: Javier Picazo, Alejandro Bernaldo de Quiros, Pablo Cerdeira y Jaime Ordovas
-- Grupo: 3A
-- ============================================================


-- Roles
CREATE ROLE IF NOT EXISTS 'rol_app';       -- API backend: operativa diaria
CREATE ROLE IF NOT EXISTS 'rol_analytics'; -- Reporting: solo lectura
CREATE ROLE IF NOT EXISTS 'rol_backup';    -- Proceso de backup
CREATE ROLE IF NOT EXISTS 'rol_dba';       -- Administracion



-- Permisos por rol
-- rol_app: SELECT/INSERT/UPDATE en toda la BD, sin DDL
GRANT SELECT, INSERT, UPDATE ON ridehailing.* TO 'rol_app';
-- Excepción: DELETE en oferta para expirar ofertas antiguas
GRANT DELETE ON ridehailing.oferta TO 'rol_app';
-- Puede llamar a los stored procedures
GRANT EXECUTE ON ridehailing.* TO 'rol_app';

-- rol_analytics: lectura a traves de vistas
-- Exponer unicamente vistas de reporting
GRANT SELECT ON ridehailing.v_viajes_detalle     TO 'rol_analytics';
GRANT SELECT ON ridehailing.v_conductor_publico  TO 'rol_analytics';
GRANT SELECT ON ridehailing.v_metricas_conductor TO 'rol_analytics';
GRANT SELECT ON ridehailing.v_metricas_company   TO 'rol_analytics';

-- rol_backup: privilegios necesarios para backup
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON ridehailing.* TO 'rol_backup';
GRANT RELOAD, REPLICATION CLIENT ON *.* TO 'rol_backup';

-- rol_dba: administracion completa sobre ridehailing
GRANT ALL PRIVILEGES ON ridehailing.* TO 'rol_dba';
GRANT PROCESS, RELOAD, REPLICATION CLIENT ON *.* TO 'rol_dba';



-- Usuarios
-- El host restringe el origen de conexion

-- api_app: acceso de la aplicacion
-- Acceso desde la red del servicio
CREATE USER IF NOT EXISTS 'api_app'@'%'
  IDENTIFIED WITH caching_sha2_password BY 'ApiApp_S3cur3!';
GRANT 'rol_app' TO 'api_app'@'%';
SET DEFAULT ROLE 'rol_app' TO 'api_app'@'%';

-- bi_reports: usuario de reporting, acceso solo a vistas
CREATE USER IF NOT EXISTS 'bi_reports'@'%'
  IDENTIFIED WITH caching_sha2_password BY 'BiReports_R3ad0nly!';
GRANT 'rol_analytics' TO 'bi_reports'@'%';
SET DEFAULT ROLE 'rol_analytics' TO 'bi_reports'@'%';

-- backup_user: acceso local para procesos de backup
CREATE USER IF NOT EXISTS 'backup_user'@'localhost'
  IDENTIFIED WITH caching_sha2_password BY 'Backup_Str0ng!';
GRANT 'rol_backup' TO 'backup_user'@'localhost';
SET DEFAULT ROLE 'rol_backup' TO 'backup_user'@'localhost';

-- dba_admin: acceso administrativo local
CREATE USER IF NOT EXISTS 'dba_admin'@'localhost'
  IDENTIFIED WITH caching_sha2_password BY 'Dba_Adm1n_S3cur3!';
GRANT 'rol_dba' TO 'dba_admin'@'localhost';
SET DEFAULT ROLE 'rol_dba' TO 'dba_admin'@'localhost';

-- rol_monitor: permisos mínimos para mysqld_exporter (Prometheus)
-- PROCESS: ver procesos activos
-- REPLICATION CLIENT: leer estado del binlog
-- SELECT *.*: métricas de performance_schema e information_schema
CREATE ROLE IF NOT EXISTS 'rol_monitor';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'rol_monitor';

-- exporter: usuario para mysqld_exporter, se conecta desde otro contenedor
CREATE USER IF NOT EXISTS 'exporter'@'%'
  IDENTIFIED WITH caching_sha2_password BY 'Exporter_M0n1tor!';
GRANT 'rol_monitor' TO 'exporter'@'%';
SET DEFAULT ROLE 'rol_monitor' TO 'exporter'@'%';

FLUSH PRIVILEGES;



-- Verificacion:

-- SHOW GRANTS FOR 'api_app'@'%';
-- SHOW GRANTS FOR 'bi_reports'@'%';
-- SHOW GRANTS FOR 'backup_user'@'localhost';
-- SHOW GRANTS FOR 'dba_admin'@'localhost';
-- SHOW GRANTS FOR 'exporter'@'%';
-- SELECT user, host, plugin, account_locked FROM mysql.user ORDER BY user;
