-- ============================================================
-- permissions.sql  —  Usuarios y permisos
-- Ride-Hailing Database  |  MySQL 8.0
-- Principio: mínimo privilegio necesario por rol
-- ============================================================

-- ============================================================
-- ROLES
-- ============================================================
CREATE ROLE IF NOT EXISTS 'rol_app';        -- API backend (operativa)
CREATE ROLE IF NOT EXISTS 'rol_analytics';  -- BI / reporting (solo lectura)
CREATE ROLE IF NOT EXISTS 'rol_backup';     -- Proceso de backup
CREATE ROLE IF NOT EXISTS 'rol_monitor';    -- Monitorización (mysqld_exporter)
CREATE ROLE IF NOT EXISTS 'rol_dba';        -- DBA (administración)

-- ============================================================
-- PERMISOS POR ROL
-- ============================================================

-- rol_app: CRUD sobre todas las tablas de ridehailing, sin DDL
GRANT SELECT, INSERT, UPDATE ON ridehailing.* TO 'rol_app';
-- El borrado es lógico (activo=FALSE), no se concede DELETE a la app
-- Se concede explícitamente DELETE solo en oferta (expiración de ofertas)
GRANT DELETE ON ridehailing.oferta TO 'rol_app';
-- Puede llamar a los stored procedures
GRANT EXECUTE ON ridehailing.* TO 'rol_app';

-- rol_analytics: solo lectura sobre vistas y tablas
GRANT SELECT ON ridehailing.* TO 'rol_analytics';

-- rol_backup: necesita SELECT global + RELOAD + LOCK TABLES + REPLICATION CLIENT
GRANT SELECT, RELOAD, LOCK TABLES, REPLICATION CLIENT, SHOW VIEW, EVENT
  ON *.* TO 'rol_backup';

-- rol_monitor: acceso mínimo para mysqld_exporter
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'rol_monitor';

-- rol_dba: administración completa de ridehailing (no global)
GRANT ALL PRIVILEGES ON ridehailing.* TO 'rol_dba';
GRANT PROCESS, RELOAD, REPLICATION CLIENT ON *.* TO 'rol_dba';

-- ============================================================
-- USUARIOS
-- ============================================================

-- Usuario de la API backend (se conecta desde la red interna Docker)
CREATE USER IF NOT EXISTS 'api_app'@'%'
  IDENTIFIED WITH caching_sha2_password BY 'ApiApp_S3cur3!';
GRANT 'rol_app' TO 'api_app'@'%';
SET DEFAULT ROLE 'rol_app' TO 'api_app'@'%';

-- Usuario de analytics / BI (solo lectura, solo puede ver vistas)
CREATE USER IF NOT EXISTS 'bi_reports'@'%'
  IDENTIFIED WITH caching_sha2_password BY 'BiReports_R3ad0nly!';
GRANT 'rol_analytics' TO 'bi_reports'@'%';
-- Limitar a vistas para evitar que acceda a tablas directamente
REVOKE SELECT ON ridehailing.* FROM 'rol_analytics';
GRANT SELECT ON ridehailing.v_viajes_detalle      TO 'bi_reports'@'%';
GRANT SELECT ON ridehailing.v_conductor_publico   TO 'bi_reports'@'%';
GRANT SELECT ON ridehailing.v_metricas_conductor  TO 'bi_reports'@'%';
GRANT SELECT ON ridehailing.v_metricas_company    TO 'bi_reports'@'%';
SET DEFAULT ROLE 'rol_analytics' TO 'bi_reports'@'%';

-- Usuario de backup (solo desde localhost/red interna)
CREATE USER IF NOT EXISTS 'backup_user'@'localhost'
  IDENTIFIED WITH caching_sha2_password BY 'Backup_Str0ng!';
GRANT 'rol_backup' TO 'backup_user'@'localhost';
SET DEFAULT ROLE 'rol_backup' TO 'backup_user'@'localhost';

-- Usuario del exporter de métricas (Prometheus/mysqld_exporter)
CREATE USER IF NOT EXISTS 'exporter'@'%'
  IDENTIFIED WITH caching_sha2_password BY 'Exporter_M3tr1c5!';
GRANT 'rol_monitor' TO 'exporter'@'%';
SET DEFAULT ROLE 'rol_monitor' TO 'exporter'@'%';

-- Usuario DBA (solo desde localhost)
CREATE USER IF NOT EXISTS 'dba_admin'@'localhost'
  IDENTIFIED WITH caching_sha2_password BY 'Dba_Adm1n_S3cur3!';
GRANT 'rol_dba' TO 'dba_admin'@'localhost';
SET DEFAULT ROLE 'rol_dba' TO 'dba_admin'@'localhost';

FLUSH PRIVILEGES;

-- ============================================================
-- VERIFICACIÓN
-- ============================================================
-- SHOW GRANTS FOR 'api_app'@'%';
-- SHOW GRANTS FOR 'bi_reports'@'%';
-- SHOW GRANTS FOR 'backup_user'@'localhost';
-- SHOW GRANTS FOR 'exporter'@'%';
-- SHOW GRANTS FOR 'dba_admin'@'localhost';

-- ============================================================
-- JUSTIFICACIÓN (comentario)
-- ============================================================
-- api_app    : INSERT/UPDATE/SELECT + DELETE en oferta. Sin DDL ni DROP.
--              Principio de mínimo privilegio: la app no necesita alterar esquema.
-- bi_reports : Acceso SOLO a vistas. No puede ver tablas con datos sensibles (DNI, email).
-- backup_user: Necesita LOCK TABLES y SELECT global para mysqldump consistente.
-- exporter   : Solo PROCESS + REPLICATION CLIENT + SELECT para leer métricas.
-- dba_admin  : Solo desde localhost. Nunca exponer root directamente.
