-- ============================================================
-- Practica Ride Hailing - BBDD Avanazadas
-- Autores: Javier Picazo, Alejandro Bernaldo de Quiros, Pablo Cerdeira y Jaime Ordovás
-- Grupo: 3A
-- ============================================================


-- Roles
CREATE ROLE IF NOT EXISTS 'rol_app';       -- API backend: operativa diaria
CREATE ROLE IF NOT EXISTS 'rol_analytics'; -- Reporting: solo lectura
CREATE ROLE IF NOT EXISTS 'rol_backup';    -- Proceso de backup
CREATE ROLE IF NOT EXISTS 'rol_dba';       -- Administración



-- Permisos por rol
GRANT SELECT, INSERT, UPDATE ON ridehailing.* TO 'rol_app';
-- Excepción: DELETE en oferta para expirar ofertas antiguas
GRANT DELETE ON ridehailing.oferta TO 'rol_app';
-- Puede llamar a los stored procedures
GRANT EXECUTE ON ridehailing.* TO 'rol_app';

-- rol_analytics: solo lectura, y solo a través de vistas (sin tablas directas)
-- Patrón de seguridad: exponer vistas en lugar de tablas (Tema 3 y Tema 4)
GRANT SELECT ON ridehailing.v_viajes_detalle     TO 'rol_analytics';
GRANT SELECT ON ridehailing.v_conductor_publico  TO 'rol_analytics';
GRANT SELECT ON ridehailing.v_metricas_conductor TO 'rol_analytics';
GRANT SELECT ON ridehailing.v_metricas_company   TO 'rol_analytics';

-- rol_backup: necesita SELECT + RELOAD + LOCK TABLES para mysqldump consistente
-- --single-transaction requiere que el usuario pueda hacer LOCK TABLES
GRANT SELECT, RELOAD, LOCK TABLES, REPLICATION CLIENT, SHOW VIEW, EVENT
  ON *.* TO 'rol_backup';

-- rol_dba: administración completa de ridehailing (no privilegios globales)
GRANT ALL PRIVILEGES ON ridehailing.* TO 'rol_dba';
GRANT PROCESS, RELOAD, REPLICATION CLIENT ON *.* TO 'rol_dba';



-- Usuarios
-- Formato: 'usuario'@'host' — el host restringe el origen

-- api_app: usuario de la aplicación backend
-- '%' porque se conecta desde dentro de la red Docker
CREATE USER IF NOT EXISTS 'api_app'@'%'
  IDENTIFIED WITH caching_sha2_password BY 'ApiApp_S3cur3!';
GRANT 'rol_app' TO 'api_app'@'%';
SET DEFAULT ROLE 'rol_app' TO 'api_app'@'%';

-- bi_reports: usuario de reporting, acceso solo a vistas
CREATE USER IF NOT EXISTS 'bi_reports'@'%'
  IDENTIFIED WITH caching_sha2_password BY 'BiReports_R3ad0nly!';
GRANT 'rol_analytics' TO 'bi_reports'@'%';
SET DEFAULT ROLE 'rol_analytics' TO 'bi_reports'@'%';

-- backup_user: solo desde localhost (el backup se ejecuta en el mismo servidor)
CREATE USER IF NOT EXISTS 'backup_user'@'localhost'
  IDENTIFIED WITH caching_sha2_password BY 'Backup_Str0ng!';
GRANT 'rol_backup' TO 'backup_user'@'localhost';
SET DEFAULT ROLE 'rol_backup' TO 'backup_user'@'localhost';

-- dba_admin: solo desde localhost, nunca exponer root directamente
CREATE USER IF NOT EXISTS 'dba_admin'@'localhost'
  IDENTIFIED WITH caching_sha2_password BY 'Dba_Adm1n_S3cur3!';
GRANT 'rol_dba' TO 'dba_admin'@'localhost';
SET DEFAULT ROLE 'rol_dba' TO 'dba_admin'@'localhost';

FLUSH PRIVILEGES;



-- Verificación:

-- SHOW GRANTS FOR 'api_app'@'%';
-- SHOW GRANTS FOR 'bi_reports'@'%';
-- SHOW GRANTS FOR 'backup_user'@'localhost';
-- SHOW GRANTS FOR 'dba_admin'@'localhost';
-- SELECT user, host, plugin, account_locked FROM mysql.user ORDER BY user;
