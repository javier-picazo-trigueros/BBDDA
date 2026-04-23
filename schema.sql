-- ============================================================
-- Practica Ride Hailing - BBDD Avanazadas
-- Autores: Javier Picazo, Alejandro Bernaldo de Quiros,
-- Pablo Cerdeira y Jaime Ordovas
-- Grupo: 3A
-- ============================================================

CREATE DATABASE IF NOT EXISTS ridehailing
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE ridehailing;


-- Tablas maestras

CREATE TABLE company (
  id_company  BIGINT       NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(120) NOT NULL,
  cif         VARCHAR(20)  NOT NULL,
  email       VARCHAR(120) NOT NULL,
  activo      BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                           ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_company),
  UNIQUE KEY uk_company_cif   (cif),
  UNIQUE KEY uk_company_email (email)
) ENGINE=InnoDB;


CREATE TABLE usuario (
  id_usuario  BIGINT       NOT NULL AUTO_INCREMENT,
  tipo        ENUM('rider','conductor') NOT NULL,
  nombre      VARCHAR(80)  NOT NULL,
  apellidos   VARCHAR(120) NOT NULL,
  email       VARCHAR(120) NOT NULL,
  telefono    VARCHAR(20)  NOT NULL,
  dni         VARCHAR(20)  NOT NULL,
  activo      BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                           ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_usuario),
  UNIQUE KEY uk_usuario_email (email),
  UNIQUE KEY uk_usuario_dni   (dni)
) ENGINE=InnoDB;


CREATE TABLE conductor (
  id_conductor  BIGINT       NOT NULL,
  id_company    BIGINT       NOT NULL,
  licencia      VARCHAR(30)  NOT NULL,
  fecha_alta    DATE         NOT NULL DEFAULT (CURRENT_DATE),
  disponible    BOOLEAN      NOT NULL DEFAULT TRUE,
  rating        DECIMAL(3,2)          DEFAULT NULL,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                             ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_conductor),
  UNIQUE KEY uk_conductor_licencia (licencia),
  CONSTRAINT fk_conductor_usuario
    FOREIGN KEY (id_conductor) REFERENCES usuario(id_usuario)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_conductor_company
    FOREIGN KEY (id_company) REFERENCES company(id_company)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

ALTER TABLE conductor
  ADD CONSTRAINT chk_conductor_rating
  CHECK (rating BETWEEN 0 AND 5);


CREATE TABLE vehiculo (
  id_vehiculo  BIGINT      NOT NULL AUTO_INCREMENT,
  matricula    VARCHAR(16) NOT NULL,
  marca        VARCHAR(50) NOT NULL,
  modelo       VARCHAR(50) NOT NULL,
  anio         YEAR        NOT NULL,
  color        VARCHAR(30) NOT NULL,
  activo       BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP
                           ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_vehiculo),
  UNIQUE KEY uk_vehiculo_matricula (matricula)
) ENGINE=InnoDB;


CREATE TABLE conductor_vehiculo (
  id_conductor  BIGINT NOT NULL,
  id_vehiculo   BIGINT NOT NULL,
  fecha_desde   DATE   NOT NULL,
  fecha_hasta   DATE   NULL,
  PRIMARY KEY (id_conductor, id_vehiculo, fecha_desde),
  CONSTRAINT fk_cv_conductor
    FOREIGN KEY (id_conductor) REFERENCES conductor(id_conductor)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_cv_vehiculo
    FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;


-- Tablas transaccionales

CREATE TABLE viaje (
  id_viaje           BIGINT        NOT NULL AUTO_INCREMENT,
  id_rider           BIGINT        NOT NULL,
  id_conductor       BIGINT        NULL,
  id_vehiculo        BIGINT        NULL,
  estado             ENUM('solicitado','aceptado','en_curso','finalizado','cancelado')
                                   NOT NULL DEFAULT 'solicitado',
  origen_lat         DECIMAL(10,7) NOT NULL CHECK (origen_lat BETWEEN -90 AND 90),
  origen_lng         DECIMAL(10,7) NOT NULL CHECK (origen_lng BETWEEN -180 AND 180),
  origen_desc        VARCHAR(200)  NOT NULL,
  destino_lat        DECIMAL(10,7) NOT NULL CHECK (destino_lat BETWEEN -90 AND 90),
  destino_lng        DECIMAL(10,7) NOT NULL CHECK (destino_lng BETWEEN -180 AND 180),
  destino_desc       VARCHAR(200)  NOT NULL,
  distancia_km       DECIMAL(8,3)  NULL CHECK (distancia_km >= 0),
  duracion_min       DECIMAL(8,2)  NULL CHECK (duracion_min >= 0),
  precio_euros       DECIMAL(10,2) NULL CHECK (precio_euros >= 0),
  solicitado_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  aceptado_at        DATETIME      NULL,
  inicio_at          DATETIME      NULL,
  fin_at             DATETIME      NULL,
  cancelado_at       DATETIME      NULL,
  motivo_cancelacion VARCHAR(200)  NULL,
  created_at         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                   ON UPDATE CURRENT_TIMESTAMP,
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
) ENGINE=InnoDB;


CREATE TABLE oferta (
  id_oferta      BIGINT   NOT NULL AUTO_INCREMENT,
  id_viaje       BIGINT   NOT NULL,
  id_conductor   BIGINT   NOT NULL,
  estado         ENUM('pendiente','aceptada','rechazada','expirada')
                          NOT NULL DEFAULT 'pendiente',
  enviada_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  respondida_at  DATETIME NULL,
  PRIMARY KEY (id_oferta),
  UNIQUE KEY uk_oferta_viaje_conductor (id_viaje, id_conductor),
  CONSTRAINT fk_oferta_viaje
    FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_oferta_conductor
    FOREIGN KEY (id_conductor) REFERENCES conductor(id_conductor)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;


CREATE TABLE pago (
  id_pago        BIGINT        NOT NULL AUTO_INCREMENT,
  id_viaje       BIGINT        NOT NULL,
  id_rider       BIGINT        NOT NULL,
  id_conductor   BIGINT        NOT NULL,
  importe_euros  DECIMAL(10,2) NOT NULL CHECK (importe_euros >= 0),
  metodo         ENUM('tarjeta','efectivo','wallet') NOT NULL DEFAULT 'tarjeta',
  estado         ENUM('pendiente','completado','fallido','reembolsado')
                               NOT NULL DEFAULT 'pendiente',
  procesado_at   DATETIME      NULL,
  created_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_pago),
  UNIQUE KEY uk_pago_viaje (id_viaje),
  CONSTRAINT fk_pago_viaje
    FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pago_rider
    FOREIGN KEY (id_rider) REFERENCES usuario(id_usuario)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pago_conductor
    FOREIGN KEY (id_conductor) REFERENCES conductor(id_conductor)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;


CREATE TABLE auditoria (
  id_auditoria  BIGINT       NOT NULL AUTO_INCREMENT,
  tabla         VARCHAR(60)  NOT NULL,
  operacion     ENUM('INSERT','UPDATE','DELETE') NOT NULL,
  id_registro   BIGINT       NOT NULL,
  campo         VARCHAR(60)  NULL,
  valor_old     TEXT         NULL,
  valor_new     TEXT         NULL,
  usuario_bd    VARCHAR(100) NOT NULL,
  fecha         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_auditoria),
  INDEX idx_audit_tabla_id (tabla, id_registro),
  INDEX idx_audit_fecha (fecha)
) ENGINE=InnoDB;


-- Indices

CREATE INDEX idx_viaje_estado         ON viaje(estado);
CREATE INDEX idx_viaje_rider          ON viaje(id_rider);
CREATE INDEX idx_viaje_conductor      ON viaje(id_conductor);
CREATE INDEX idx_viaje_solicitado_at  ON viaje(solicitado_at);
CREATE INDEX idx_viaje_estado_fecha   ON viaje(estado, solicitado_at);

CREATE INDEX idx_oferta_viaje_estado  ON oferta(id_viaje, estado);
CREATE INDEX idx_oferta_conductor     ON oferta(id_conductor);

CREATE INDEX idx_usuario_nombre       ON usuario(nombre, apellidos);
CREATE INDEX idx_usuario_tipo         ON usuario(tipo);
CREATE INDEX idx_conductor_company    ON conductor(id_company);
CREATE INDEX idx_conductor_disponible ON conductor(disponible);

CREATE INDEX idx_pago_conductor       ON pago(id_conductor, estado);
CREATE INDEX idx_pago_rider           ON pago(id_rider);


-- Vistas

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
  r.id_usuario                       AS rider_id,
  CONCAT(r.nombre, ' ', r.apellidos) AS rider_nombre,
  r.email                            AS rider_email,
  c.id_conductor,
  CONCAT(u.nombre, ' ', u.apellidos) AS conductor_nombre,
  co.id_company,
  co.nombre                          AS company_nombre,
  ve.matricula,
  CONCAT(ve.marca, ' ', ve.modelo)   AS vehiculo
FROM viaje v
JOIN usuario r        ON r.id_usuario = v.id_rider
LEFT JOIN conductor c ON c.id_conductor = v.id_conductor
LEFT JOIN usuario u   ON u.id_usuario = v.id_conductor
LEFT JOIN company co  ON co.id_company = c.id_company
LEFT JOIN vehiculo ve ON ve.id_vehiculo = v.id_vehiculo;


CREATE VIEW v_conductor_publico AS
SELECT
  c.id_conductor,
  CONCAT(u.nombre, ' ', u.apellidos) AS nombre,
  co.nombre                          AS company,
  c.rating,
  c.disponible
FROM conductor c
JOIN usuario u  ON u.id_usuario = c.id_conductor
JOIN company co ON co.id_company = c.id_company
WHERE u.activo = TRUE;


CREATE VIEW v_metricas_conductor AS
WITH stats_viaje AS (
  SELECT
    id_conductor,
    COUNT(id_viaje) AS total_viajes,
    SUM(estado = 'finalizado') AS viajes_finalizados,
    SUM(estado = 'cancelado') AS viajes_cancelados,
    ROUND(SUM(CASE WHEN estado = 'finalizado' THEN IFNULL(distancia_km, 0) ELSE 0 END), 2)
      AS km_totales,
    ROUND(SUM(CASE WHEN estado = 'finalizado' THEN IFNULL(duracion_min, 0) ELSE 0 END), 2)
      AS min_totales,
    ROUND(SUM(CASE WHEN estado = 'finalizado' THEN IFNULL(precio_euros, 0) ELSE 0 END), 2)
      AS ingresos_totales
  FROM viaje
  WHERE id_conductor IS NOT NULL
  GROUP BY id_conductor
),
stats_oferta AS (
  SELECT
    id_conductor,
    COUNT(id_oferta) AS ofertas_recibidas,
    SUM(estado = 'aceptada') AS ofertas_aceptadas
  FROM oferta
  GROUP BY id_conductor
)
SELECT
  c.id_conductor,
  co.id_company,
  CONCAT(u.nombre, ' ', u.apellidos) AS conductor_nombre,
  co.nombre                          AS company,
  IFNULL(v.total_viajes, 0)          AS total_viajes,
  IFNULL(v.viajes_finalizados, 0)    AS viajes_finalizados,
  IFNULL(v.viajes_cancelados, 0)     AS viajes_cancelados,
  IFNULL(v.km_totales, 0)            AS km_totales,
  IFNULL(v.min_totales, 0)           AS min_totales,
  IFNULL(v.ingresos_totales, 0)      AS ingresos_totales,
  ROUND(
    IFNULL(v.ingresos_totales, 0) / NULLIF(IFNULL(v.km_totales, 0), 0), 2
  ) AS eur_por_km,
  ROUND(
    IFNULL(v.ingresos_totales, 0) / NULLIF(IFNULL(v.min_totales, 0), 0), 2
  ) AS eur_por_min,
  IFNULL(o.ofertas_recibidas, 0)     AS ofertas_recibidas,
  IFNULL(o.ofertas_aceptadas, 0)     AS ofertas_aceptadas,
  ROUND(
    100.0 * IFNULL(o.ofertas_aceptadas, 0)
    / NULLIF(IFNULL(o.ofertas_recibidas, 0), 0), 1
  ) AS tasa_aceptacion_pct
FROM conductor c
JOIN usuario u      ON u.id_usuario = c.id_conductor
JOIN company co     ON co.id_company = c.id_company
LEFT JOIN stats_viaje v  ON v.id_conductor = c.id_conductor
LEFT JOIN stats_oferta o ON o.id_conductor = c.id_conductor;


CREATE VIEW v_metricas_company AS
WITH base_company AS (
  SELECT id_company, nombre AS company FROM company
)
SELECT
  bc.id_company,
  bc.company,
  COUNT(DISTINCT m.id_conductor) AS num_conductores,
  SUM(IFNULL(m.total_viajes, 0)) AS total_viajes,
  ROUND(SUM(IFNULL(m.ingresos_totales, 0)), 2) AS ingresos_totales,
  ROUND(AVG(m.tasa_aceptacion_pct), 1) AS tasa_media_company
FROM base_company bc
LEFT JOIN v_metricas_conductor m ON m.id_company = bc.id_company
GROUP BY bc.id_company, bc.company;


-- Stored procedures y triggers
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_aceptar_oferta$$
CREATE PROCEDURE sp_aceptar_oferta(
  IN  p_id_oferta    BIGINT,
  IN  p_id_conductor BIGINT,
  OUT p_resultado    VARCHAR(100)
)
proc_label: BEGIN
  DECLARE v_id_viaje      BIGINT;
  DECLARE v_estado_viaje  VARCHAR(20);
  DECLARE v_estado_oferta VARCHAR(20);
  DECLARE v_id_vehiculo   BIGINT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_resultado = 'ERROR: excepcion SQL, transaccion revertida';
  END;

  START TRANSACTION;

  -- Obtener el viaje asociado a la oferta
  SELECT id_viaje INTO v_id_viaje FROM oferta WHERE id_oferta = p_id_oferta;

  IF v_id_viaje IS NULL THEN
    ROLLBACK; SET p_resultado = 'ERROR: Oferta no encontrada'; LEAVE proc_label;
  END IF;

  -- Bloquear el viaje antes de actualizar sus ofertas
  SELECT estado INTO v_estado_viaje FROM viaje WHERE id_viaje = v_id_viaje FOR UPDATE;

  IF v_estado_viaje != 'solicitado' THEN
    ROLLBACK; SET p_resultado = 'ERROR: El viaje ya fue aceptado por otro conductor'; LEAVE proc_label;
  END IF;

  -- Bloquear la oferta del conductor
  SELECT estado INTO v_estado_oferta FROM oferta
  WHERE id_oferta = p_id_oferta AND id_conductor = p_id_conductor FOR UPDATE;

  -- Validar que la oferta pertenezca al conductor y siga pendiente
  IF v_estado_oferta IS NULL OR v_estado_oferta != 'pendiente' THEN
    ROLLBACK;
    SET p_resultado = 'ERROR: La oferta no pertenece al conductor o no está pendiente';
    LEAVE proc_label;
  END IF;

  -- Obtener el vehiculo vigente del conductor
  SELECT id_vehiculo INTO v_id_vehiculo FROM conductor_vehiculo
  WHERE id_conductor = p_id_conductor AND fecha_hasta IS NULL LIMIT 1;

  IF v_id_vehiculo IS NULL THEN
    ROLLBACK; SET p_resultado = 'ERROR: El conductor no tiene vehículo asignado'; LEAVE proc_label;
  END IF;

  -- Confirmar la aceptacion solo sobre la oferta del conductor
  UPDATE oferta
  SET estado = 'aceptada', respondida_at = NOW()
  WHERE id_oferta = p_id_oferta AND id_conductor = p_id_conductor;

  UPDATE oferta
  SET estado = 'rechazada',
      respondida_at = NOW()
  WHERE id_viaje = v_id_viaje
    AND id_conductor != p_id_conductor
    AND estado = 'pendiente';

  UPDATE viaje
  SET estado = 'aceptado',
      id_conductor = p_id_conductor,
      id_vehiculo = v_id_vehiculo,
      aceptado_at = NOW()
  WHERE id_viaje = v_id_viaje;

  COMMIT;
  SET p_resultado = CONCAT('OK: viaje ', v_id_viaje, ' asignado al conductor ', p_id_conductor);
END$$


DROP PROCEDURE IF EXISTS sp_iniciar_viaje$$
CREATE PROCEDURE sp_iniciar_viaje(
  IN  p_id_viaje     BIGINT,
  IN  p_id_conductor BIGINT,
  OUT p_resultado    VARCHAR(100)
)
proc_label: BEGIN
  DECLARE v_id_viaje BIGINT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_resultado = 'ERROR: no se pudo iniciar el viaje';
  END;

  START TRANSACTION;

  SELECT v.id_viaje
  INTO   v_id_viaje
  FROM   viaje v
  WHERE  v.id_viaje = p_id_viaje
    AND  v.id_conductor = p_id_conductor
    AND  v.estado = 'aceptado'
  FOR UPDATE;

  IF v_id_viaje IS NULL THEN
    ROLLBACK;
    SET p_resultado = 'ERROR: viaje no encontrado o no aceptado por ese conductor';
    LEAVE proc_label;
  END IF;

  UPDATE viaje
  SET estado = 'en_curso',
      inicio_at = NOW()
  WHERE id_viaje = p_id_viaje;

  UPDATE conductor
  SET disponible = FALSE
  WHERE id_conductor = p_id_conductor;

  COMMIT;
  SET p_resultado = CONCAT('OK: viaje ', p_id_viaje, ' en curso');
END$$


DROP PROCEDURE IF EXISTS sp_finalizar_viaje$$
CREATE PROCEDURE sp_finalizar_viaje(
  IN  p_id_viaje      BIGINT,
  IN  p_distancia_km  DECIMAL(8,3),
  IN  p_duracion_min  DECIMAL(8,2),
  OUT p_resultado     VARCHAR(100)
)
proc_label: BEGIN
  DECLARE v_conductor BIGINT;
  DECLARE v_rider     BIGINT;
  DECLARE v_precio    DECIMAL(10,2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_resultado = 'ERROR: no se pudo finalizar el viaje';
  END;

  IF p_distancia_km <= 0 OR p_duracion_min <= 0 THEN
    SET p_resultado = 'ERROR: la distancia y duracion deben ser mayores a cero';
    LEAVE proc_label;
  END IF;

  SET v_precio = ROUND(2.50 + p_distancia_km * 1.20 + p_duracion_min * 0.15, 2);

  START TRANSACTION;

  SELECT v.id_conductor, v.id_rider
  INTO   v_conductor, v_rider
  FROM   viaje v
  WHERE  v.id_viaje = p_id_viaje
    AND  v.estado = 'en_curso'
  FOR UPDATE;

  IF v_conductor IS NULL OR v_rider IS NULL THEN
    ROLLBACK;
    SET p_resultado = 'ERROR: viaje no encontrado o no esta en curso';
    LEAVE proc_label;
  END IF;

  UPDATE viaje
  SET estado = 'finalizado',
      distancia_km = p_distancia_km,
      duracion_min = p_duracion_min,
      precio_euros = v_precio,
      fin_at = NOW()
  WHERE id_viaje = p_id_viaje;

  UPDATE conductor
  SET disponible = TRUE
  WHERE id_conductor = v_conductor;

  INSERT INTO pago (
    id_viaje, id_rider, id_conductor, importe_euros, estado, procesado_at
  ) VALUES (
    p_id_viaje, v_rider, v_conductor, v_precio, 'completado', NOW()
  );

  COMMIT;
  SET p_resultado = CONCAT('OK: viaje finalizado. Precio: ', v_precio, ' EUR');
END$$


DROP TRIGGER IF EXISTS trg_viaje_audit_update$$
CREATE TRIGGER trg_viaje_audit_update
AFTER UPDATE ON viaje
FOR EACH ROW
BEGIN
  IF NOT (OLD.estado <=> NEW.estado) THEN
    INSERT INTO auditoria (
      tabla, operacion, id_registro, campo, valor_old, valor_new, usuario_bd
    )
    VALUES ('viaje', 'UPDATE', NEW.id_viaje, 'estado', OLD.estado, NEW.estado, USER());
  END IF;
END$$


DROP TRIGGER IF EXISTS trg_oferta_audit_insert$$
CREATE TRIGGER trg_oferta_audit_insert
AFTER INSERT ON oferta
FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, campo, valor_new, usuario_bd)
  VALUES ('oferta', 'INSERT', NEW.id_oferta, 'estado', NEW.estado, USER());
END$$


DROP TRIGGER IF EXISTS trg_oferta_audit_update$$
CREATE TRIGGER trg_oferta_audit_update
AFTER UPDATE ON oferta
FOR EACH ROW
BEGIN
  IF NOT (OLD.estado <=> NEW.estado) THEN
    INSERT INTO auditoria (
      tabla, operacion, id_registro, campo, valor_old, valor_new, usuario_bd
    )
    VALUES ('oferta', 'UPDATE', NEW.id_oferta, 'estado', OLD.estado, NEW.estado, USER());
  END IF;
END$$

DELIMITER ;
