-- ============================================================
-- schema.sql  —  Ride-Hailing Database
-- Motor: MySQL 8.0  |  Engine: InnoDB
-- ============================================================

-- ------------------------------------------------------------
-- 1. Base de datos
-- ------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS ridehailing
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE ridehailing;

-- ------------------------------------------------------------
-- 2. Tablas de catálogo / maestros
-- ------------------------------------------------------------

-- 2.1. Compañías de conductores
CREATE TABLE company (
  id_company    BIGINT       NOT NULL AUTO_INCREMENT,
  nombre        VARCHAR(120) NOT NULL,
  cif           VARCHAR(20)  NOT NULL,
  email         VARCHAR(120) NOT NULL,
  activo        BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_company),
  UNIQUE KEY uk_company_cif   (cif),
  UNIQUE KEY uk_company_email (email)
) ENGINE=InnoDB COMMENT='Empresas propietarias de flotas de conductores';

-- 2.2. Usuarios (riders y conductores comparten tabla base)
CREATE TABLE usuario (
  id_usuario    BIGINT       NOT NULL AUTO_INCREMENT,
  tipo          ENUM('rider','conductor') NOT NULL,
  nombre        VARCHAR(80)  NOT NULL,
  apellidos     VARCHAR(120) NOT NULL,
  email         VARCHAR(120) NOT NULL,
  telefono      VARCHAR(20)  NOT NULL,
  dni           VARCHAR(20)  NOT NULL,
  activo        BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_usuario),
  UNIQUE KEY uk_usuario_email (email),
  UNIQUE KEY uk_usuario_dni   (dni)
) ENGINE=InnoDB COMMENT='Riders y conductores del sistema';

-- 2.3. Perfil adicional del conductor
CREATE TABLE conductor (
  id_conductor      BIGINT      NOT NULL,           -- FK → usuario
  id_company        BIGINT      NOT NULL,           -- FK → company
  licencia          VARCHAR(30) NOT NULL,
  fecha_alta        DATE        NOT NULL DEFAULT (CURRENT_DATE),
  disponible        BOOLEAN     NOT NULL DEFAULT TRUE,
  rating            DECIMAL(3,2)         DEFAULT NULL,
  created_at        DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_conductor),
  UNIQUE KEY uk_conductor_licencia (licencia),
  CONSTRAINT fk_conductor_usuario
    FOREIGN KEY (id_conductor) REFERENCES usuario(id_usuario)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_conductor_company
    FOREIGN KEY (id_company) REFERENCES company(id_company)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Datos extra del conductor: empresa, licencia, disponibilidad';

-- 2.4. Vehículos
CREATE TABLE vehiculo (
  id_vehiculo   BIGINT      NOT NULL AUTO_INCREMENT,
  matricula     VARCHAR(16) NOT NULL,
  marca         VARCHAR(50) NOT NULL,
  modelo        VARCHAR(50) NOT NULL,
  anio          YEAR        NOT NULL,
  color         VARCHAR(30) NOT NULL,
  activo        BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at    DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_vehiculo),
  UNIQUE KEY uk_vehiculo_matricula (matricula)
) ENGINE=InnoDB COMMENT='Flota de vehículos';

-- 2.5. Asignación conductor ↔ vehículo (N:N con vigencia)
CREATE TABLE conductor_vehiculo (
  id_conductor  BIGINT   NOT NULL,
  id_vehiculo   BIGINT   NOT NULL,
  fecha_desde   DATE     NOT NULL,
  fecha_hasta   DATE     NULL COMMENT 'NULL = asignación vigente',
  PRIMARY KEY (id_conductor, id_vehiculo, fecha_desde),
  CONSTRAINT fk_cv_conductor
    FOREIGN KEY (id_conductor) REFERENCES conductor(id_conductor)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_cv_vehiculo
    FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Qué vehículo usa cada conductor y desde cuándo';

-- ------------------------------------------------------------
-- 3. Tablas transaccionales
-- ------------------------------------------------------------

-- 3.1. Viajes
CREATE TABLE viaje (
  id_viaje          BIGINT        NOT NULL AUTO_INCREMENT,
  id_rider          BIGINT        NOT NULL,
  id_conductor      BIGINT        NULL COMMENT 'NULL hasta que un conductor acepta',
  id_vehiculo       BIGINT        NULL,
  estado            ENUM('solicitado','aceptado','en_curso','finalizado','cancelado') NOT NULL DEFAULT 'solicitado',

  -- Origen / destino (geolocalización simplificada)
  origen_lat        DECIMAL(10,7) NOT NULL,
  origen_lng        DECIMAL(10,7) NOT NULL,
  origen_desc       VARCHAR(200)  NOT NULL,
  destino_lat       DECIMAL(10,7) NOT NULL,
  destino_lng       DECIMAL(10,7) NOT NULL,
  destino_desc      VARCHAR(200)  NOT NULL,

  -- Métricas del viaje
  distancia_km      DECIMAL(8,3)  NULL COMMENT 'Calculado al finalizar',
  duracion_min      DECIMAL(8,2)  NULL COMMENT 'Calculado al finalizar',
  precio_euros      DECIMAL(10,2) NULL COMMENT 'Calculado al finalizar',

  -- Timestamps de ciclo de vida
  solicitado_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  aceptado_at       DATETIME      NULL,
  inicio_at         DATETIME      NULL,
  fin_at            DATETIME      NULL,
  cancelado_at      DATETIME      NULL,
  motivo_cancelacion VARCHAR(200) NULL,

  created_at        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id_viaje),
  CONSTRAINT fk_viaje_rider
    FOREIGN KEY (id_rider) REFERENCES usuario(id_usuario)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_viaje_conductor
    FOREIGN KEY (id_conductor) REFERENCES conductor(id_conductor)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_viaje_vehiculo
    FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Viajes: ciclo de vida completo';

-- 3.2. Ofertas enviadas a conductores
CREATE TABLE oferta (
  id_oferta       BIGINT    NOT NULL AUTO_INCREMENT,
  id_viaje        BIGINT    NOT NULL,
  id_conductor    BIGINT    NOT NULL,
  estado          ENUM('pendiente','aceptada','rechazada','expirada') NOT NULL DEFAULT 'pendiente',
  enviada_at      DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  respondida_at   DATETIME  NULL,
  PRIMARY KEY (id_oferta),
  UNIQUE KEY uk_oferta_viaje_conductor (id_viaje, id_conductor),  -- Un conductor recibe la oferta de un viaje solo 1 vez
  CONSTRAINT fk_oferta_viaje
    FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_oferta_conductor
    FOREIGN KEY (id_conductor) REFERENCES conductor(id_conductor)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Ofertas de viaje enviadas a conductores';

-- 3.3. Pagos
CREATE TABLE pago (
  id_pago         BIGINT        NOT NULL AUTO_INCREMENT,
  id_viaje        BIGINT        NOT NULL,
  id_rider        BIGINT        NOT NULL,
  id_conductor    BIGINT        NOT NULL,
  importe_euros   DECIMAL(10,2) NOT NULL,
  metodo          ENUM('tarjeta','efectivo','wallet') NOT NULL DEFAULT 'tarjeta',
  estado          ENUM('pendiente','completado','fallido','reembolsado') NOT NULL DEFAULT 'pendiente',
  procesado_at    DATETIME      NULL,
  created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_pago),
  UNIQUE KEY uk_pago_viaje (id_viaje),   -- Un viaje → un pago
  CONSTRAINT fk_pago_viaje
    FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pago_rider
    FOREIGN KEY (id_rider) REFERENCES usuario(id_usuario)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pago_conductor
    FOREIGN KEY (id_conductor) REFERENCES conductor(id_conductor)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Pagos de viajes';

-- ------------------------------------------------------------
-- 4. Auditoría
-- ------------------------------------------------------------
CREATE TABLE auditoria (
  id_auditoria  BIGINT       NOT NULL AUTO_INCREMENT,
  tabla         VARCHAR(60)  NOT NULL,
  operacion     ENUM('INSERT','UPDATE','DELETE') NOT NULL,
  id_registro   BIGINT       NOT NULL COMMENT 'PK del registro afectado',
  campo         VARCHAR(60)  NULL,
  valor_old     TEXT         NULL,
  valor_new     TEXT         NULL,
  usuario_bd    VARCHAR(100) NOT NULL,
  ip            VARCHAR(45)  NULL,
  fecha         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_auditoria),
  INDEX idx_audit_tabla_id (tabla, id_registro),
  INDEX idx_audit_fecha    (fecha)
) ENGINE=InnoDB COMMENT='Historial de operaciones para auditoría';

-- ------------------------------------------------------------
-- 5. Índices de rendimiento
-- ------------------------------------------------------------

-- Viajes: filtros frecuentes
CREATE INDEX idx_viaje_estado          ON viaje(estado);
CREATE INDEX idx_viaje_rider           ON viaje(id_rider);
CREATE INDEX idx_viaje_conductor       ON viaje(id_conductor);
CREATE INDEX idx_viaje_solicitado_at   ON viaje(solicitado_at);
CREATE INDEX idx_viaje_estado_fecha    ON viaje(estado, solicitado_at);

-- Ofertas: obtener las ofertas pendientes de un viaje rápidamente
CREATE INDEX idx_oferta_viaje_estado   ON oferta(id_viaje, estado);
CREATE INDEX idx_oferta_conductor      ON oferta(id_conductor);

-- Usuario: búsqueda por nombre
CREATE INDEX idx_usuario_nombre        ON usuario(nombre, apellidos);
CREATE INDEX idx_usuario_tipo          ON usuario(tipo);

-- Conductor: filtrar disponibles de una company
CREATE INDEX idx_conductor_company     ON conductor(id_company);
CREATE INDEX idx_conductor_disponible  ON conductor(disponible);

-- Pago: por conductor (ingresos) y por estado
CREATE INDEX idx_pago_conductor_estado ON pago(id_conductor, estado);
CREATE INDEX idx_pago_rider            ON pago(id_rider);

-- ------------------------------------------------------------
-- 6. Vistas
-- ------------------------------------------------------------

-- Vista de viajes con toda la información desnormalizada
CREATE VIEW v_viajes_detalle AS
SELECT
  v.id_viaje,
  v.estado,
  v.solicitado_at,
  v.aceptado_at,
  v.inicio_at,
  v.fin_at,
  v.distancia_km,
  v.duracion_min,
  v.precio_euros,
  v.origen_desc,
  v.destino_desc,
  -- Rider
  r.id_usuario   AS rider_id,
  CONCAT(r.nombre, ' ', r.apellidos) AS rider_nombre,
  r.email        AS rider_email,
  -- Conductor
  c.id_conductor,
  CONCAT(u.nombre, ' ', u.apellidos) AS conductor_nombre,
  u.email        AS conductor_email,
  -- Company
  co.id_company,
  co.nombre      AS company_nombre,
  -- Vehículo
  ve.matricula,
  CONCAT(ve.marca, ' ', ve.modelo) AS vehiculo
FROM viaje v
JOIN  usuario   r  ON r.id_usuario   = v.id_rider
LEFT JOIN conductor c  ON c.id_conductor = v.id_conductor
LEFT JOIN usuario   u  ON u.id_usuario   = v.id_conductor
LEFT JOIN company   co ON co.id_company  = c.id_company
LEFT JOIN vehiculo  ve ON ve.id_vehiculo = v.id_vehiculo;


-- Vista pública del conductor (sin datos sensibles)
CREATE VIEW v_conductor_publico AS
SELECT
  c.id_conductor,
  CONCAT(u.nombre, ' ', u.apellidos) AS nombre,
  co.nombre  AS company,
  c.rating,
  c.disponible
FROM conductor c
JOIN usuario u  ON u.id_usuario  = c.id_conductor
JOIN company co ON co.id_company = c.id_company
WHERE u.activo = TRUE;


-- Vista de métricas por conductor
CREATE VIEW v_metricas_conductor AS
SELECT
  c.id_conductor,
  CONCAT(u.nombre, ' ', u.apellidos) AS conductor_nombre,
  co.nombre AS company,
  COUNT(v.id_viaje)                                                AS total_viajes,
  COUNT(CASE WHEN v.estado = 'finalizado' THEN 1 END)             AS viajes_finalizados,
  COUNT(CASE WHEN v.estado = 'cancelado'  THEN 1 END)             AS viajes_cancelados,
  ROUND(AVG(v.distancia_km),  2)                                   AS km_medio,
  ROUND(AVG(v.duracion_min),  2)                                   AS min_medio,
  ROUND(SUM(v.precio_euros),  2)                                   AS ingresos_totales,
  ROUND(AVG(v.precio_euros / NULLIF(v.distancia_km, 0)), 2)        AS eur_por_km,
  ROUND(AVG(v.precio_euros / NULLIF(v.duracion_min, 0)), 2)        AS eur_por_min,
  -- Tasa de aceptación
  COUNT(o.id_oferta)                                               AS ofertas_recibidas,
  COUNT(CASE WHEN o.estado = 'aceptada' THEN 1 END)               AS ofertas_aceptadas,
  ROUND(
    100.0 * COUNT(CASE WHEN o.estado = 'aceptada' THEN 1 END)
    / NULLIF(COUNT(o.id_oferta), 0), 1
  )                                                                AS tasa_aceptacion_pct
FROM conductor c
JOIN usuario u  ON u.id_usuario  = c.id_conductor
JOIN company co ON co.id_company = c.id_company
LEFT JOIN viaje  v ON v.id_conductor = c.id_conductor
LEFT JOIN oferta o ON o.id_conductor = c.id_conductor
GROUP BY c.id_conductor, conductor_nombre, company;


-- Vista de métricas por company
CREATE VIEW v_metricas_company AS
SELECT
  co.id_company,
  co.nombre AS company,
  COUNT(DISTINCT c.id_conductor)                                   AS num_conductores,
  COUNT(v.id_viaje)                                                AS total_viajes,
  COUNT(CASE WHEN v.estado = 'finalizado' THEN 1 END)             AS viajes_finalizados,
  ROUND(SUM(v.precio_euros), 2)                                    AS ingresos_totales,
  ROUND(AVG(v.precio_euros / NULLIF(v.distancia_km, 0)), 2)        AS eur_por_km,
  ROUND(
    100.0 * COUNT(CASE WHEN o.estado = 'aceptada' THEN 1 END)
    / NULLIF(COUNT(o.id_oferta), 0), 1
  )                                                                AS tasa_aceptacion_pct
FROM company co
LEFT JOIN conductor c ON c.id_company   = co.id_company
LEFT JOIN viaje    v ON v.id_conductor  = c.id_conductor
LEFT JOIN oferta   o ON o.id_conductor  = c.id_conductor
GROUP BY co.id_company, co.nombre;
