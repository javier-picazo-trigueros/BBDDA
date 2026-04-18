-- ============================================================
-- Practica Ride Hailing - BBDD Avanazadas
-- Autores: Javier Picazo, Alejandro Bernaldo de Quiros, Pablo Cerdeira y Jaime Ordovás
-- Grupo: 3A
-- ============================================================

USE ridehailing;



-- SECCION 1: OPERATIVA BASICA — INSERT, UPDATE, DELETE

-- Registrar un nuevo rider
INSERT INTO usuario (tipo, nombre, apellidos, email, telefono, dni)
VALUES ('rider', 'Nuevo', 'Rider Ejemplo', 'nuevo.rider@mail.es', '699000099', '99000099Z');


-- Registrar un conductor: primero el usuario, luego el perfil
START TRANSACTION;

  INSERT INTO usuario (tipo, nombre, apellidos, email, telefono, dni)
  VALUES ('conductor', 'Nuevo', 'Conductor Ejemplo', 'nuevo.conductor@driver.es', '688000088', '98000088Y');

  SET @nuevo_conductor_id = LAST_INSERT_ID();

  INSERT INTO conductor (id_conductor, id_company, licencia, fecha_alta)
  VALUES (@nuevo_conductor_id, 1, 'LIC-2024-9999', CURRENT_DATE);

COMMIT;


-- Solicitar un viaje (INSERT en viaje)
INSERT INTO viaje (
  id_rider,
  origen_lat,  origen_lng,  origen_desc,
  destino_lat, destino_lng, destino_desc
) VALUES (
  1,
  40.4168, -3.7038, 'Puerta del Sol, Madrid',
  40.4530, -3.6883, 'Estadio Bernabéu, Madrid'
);

SET @id_viaje_nuevo = LAST_INSERT_ID();


-- Enviar oferta a conductores disponibles
INSERT INTO oferta (id_viaje, id_conductor, enviada_at)
SELECT @id_viaje_nuevo, c.id_conductor, NOW()
FROM conductor c
WHERE c.disponible = TRUE
LIMIT 5;


-- Borrado lógico de un usuario (UPDATE activo = FALSE)
UPDATE usuario
SET activo = FALSE
WHERE id_usuario = 99;


-- Expirar ofertas pendientes de hace más de 5 minutos
-- Un UPDATE sin WHERE afecta todas las filas — siempre usar condición
UPDATE oferta
SET estado = 'expirada'
WHERE estado     = 'pendiente'
  AND enviada_at < DATE_SUB(NOW(), INTERVAL 5 MINUTE);




-- SECCIÓN 2: TRANSACCIONES + LOCKS (CONCURRENCIA)
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_aceptar_oferta$$
CREATE PROCEDURE sp_aceptar_oferta(
  IN  p_id_oferta    BIGINT,
  IN  p_id_conductor BIGINT,
  OUT p_resultado    VARCHAR(100)
)
BEGIN
  DECLARE v_id_viaje     BIGINT;
  DECLARE v_estado_viaje  ENUM('solicitado','aceptado','en_curso','finalizado','cancelado');
  DECLARE v_estado_oferta ENUM('pendiente','aceptada','rechazada','expirada');
  DECLARE v_id_vehiculo  BIGINT;


  -- Handler: si ocurre cualquier error SQL, hace ROLLBACK automático
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_resultado = 'ERROR: excepción SQL, transacción revertida';
  END;

  START TRANSACTION;


  -- bloqueo exclusivo sobre la oferta (FOR UPDATE)
  SELECT o.id_viaje, o.estado
  INTO   v_id_viaje, v_estado_oferta
  FROM   oferta o
  WHERE  o.id_oferta    = p_id_oferta
    AND  o.id_conductor = p_id_conductor
  FOR UPDATE;

  IF v_estado_oferta != 'pendiente' THEN
    ROLLBACK;
    SET p_resultado = 'ERROR: la oferta ya no está pendiente';
    LEAVE sp_aceptar_oferta;
  END IF;


  -- bloqueo exclusivo sobre el viaje
  SELECT estado INTO v_estado_viaje
  FROM viaje
  WHERE id_viaje = v_id_viaje
  FOR UPDATE;

  IF v_estado_viaje != 'solicitado' THEN
    ROLLBACK;
    SET p_resultado = 'ERROR: el viaje ya fue aceptado por otro conductor';
    LEAVE sp_aceptar_oferta;
  END IF;


  -- obtener vehículo vigente del conductor
  SELECT id_vehiculo INTO v_id_vehiculo
  FROM conductor_vehiculo
  WHERE id_conductor = p_id_conductor
    AND fecha_hasta IS NULL
  LIMIT 1;


  -- marcar esta oferta como aceptada
  UPDATE oferta
  SET estado = 'aceptada', respondida_at = NOW()
  WHERE id_oferta = p_id_oferta;


  -- rechazar el resto de ofertas pendientes del mismo viaje
  UPDATE oferta
  SET estado = 'rechazada', respondida_at = NOW()
  WHERE id_viaje     = v_id_viaje
    AND id_conductor != p_id_conductor
    AND estado       = 'pendiente';


  -- actualizar el viaje con el conductor asignado
  UPDATE viaje
  SET estado       = 'aceptado',
      id_conductor = p_id_conductor,
      id_vehiculo  = v_id_vehiculo,
      aceptado_at  = NOW()
  WHERE id_viaje = v_id_viaje;

  COMMIT;
  SET p_resultado = CONCAT('OK: viaje ', v_id_viaje, ' asignado al conductor ', p_id_conductor);
END$$


-- Stored procedure: iniciar viaje
DROP PROCEDURE IF EXISTS sp_iniciar_viaje$$
CREATE PROCEDURE sp_iniciar_viaje(
  IN  p_id_viaje    BIGINT,
  IN  p_id_conductor BIGINT,
  OUT p_resultado   VARCHAR(100)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_resultado = 'ERROR: no se pudo iniciar el viaje';
  END;

  START TRANSACTION;
    SELECT id_viaje FROM viaje
    WHERE id_viaje = p_id_viaje AND id_conductor = p_id_conductor AND estado = 'aceptado'
    FOR UPDATE;

    UPDATE viaje
    SET estado = 'en_curso', inicio_at = NOW()
    WHERE id_viaje = p_id_viaje;

    UPDATE conductor
    SET disponible = FALSE
    WHERE id_conductor = p_id_conductor;
  COMMIT;

  SET p_resultado = CONCAT('OK: viaje ', p_id_viaje, ' en curso');
END$$


-- Stored procedure: finalizar viaje y crear pago
-- Tarifa: 2.50 base + 1.20 €/km + 0.15 €/min
DROP PROCEDURE IF EXISTS sp_finalizar_viaje$$
CREATE PROCEDURE sp_finalizar_viaje(
  IN  p_id_viaje     BIGINT,
  IN  p_distancia_km DECIMAL(8,3),
  IN  p_duracion_min DECIMAL(8,2),
  OUT p_resultado    VARCHAR(100)
)
BEGIN
  DECLARE v_conductor BIGINT;
  DECLARE v_rider     BIGINT;
  DECLARE v_precio    DECIMAL(10,2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_resultado = 'ERROR: no se pudo finalizar el viaje';
  END;

  SET v_precio = ROUND(2.50 + p_distancia_km * 1.20 + p_duracion_min * 0.15, 2);

  START TRANSACTION;
    SELECT id_conductor, id_rider
    INTO   v_conductor,  v_rider
    FROM   viaje
    WHERE  id_viaje = p_id_viaje AND estado = 'en_curso'
    FOR UPDATE;

    UPDATE viaje
    SET estado       = 'finalizado',
        distancia_km = p_distancia_km,
        duracion_min = p_duracion_min,
        precio_euros = v_precio,
        fin_at       = NOW()
    WHERE id_viaje = p_id_viaje;

    UPDATE conductor
    SET disponible = TRUE
    WHERE id_conductor = v_conductor;

    -- Crear el pago asociado al viaje
    INSERT INTO pago (id_viaje, id_rider, id_conductor, importe_euros, estado, procesado_at)
    VALUES (p_id_viaje, v_rider, v_conductor, v_precio, 'completado', NOW());
  COMMIT;

  SET p_resultado = CONCAT('OK: viaje finalizado. Precio: ', v_precio, ' EUR');
END$$

DELIMITER ;




-- SECCIÓN 3: CONSULTAS CON JOIN

-- Historial de viajes de un rider con nombre del conductor
SELECT
  v.id_viaje,
  v.estado,
  v.origen_desc,
  v.destino_desc,
  v.distancia_km,
  v.duracion_min,
  v.precio_euros,
  v.solicitado_at,
  CONCAT(u.nombre, ' ', u.apellidos) AS conductor,
  co.nombre                          AS company
FROM viaje v
JOIN  usuario   r  ON r.id_usuario   = v.id_rider
LEFT JOIN conductor c  ON c.id_conductor = v.id_conductor
LEFT JOIN usuario   u  ON u.id_usuario   = v.id_conductor
LEFT JOIN company   co ON co.id_company  = c.id_company
WHERE v.id_rider = 1
ORDER BY v.solicitado_at DESC;


-- Viajes activos ahora mismo
SELECT
  v.id_viaje,
  v.estado,
  CONCAT(r.nombre, ' ', r.apellidos) AS rider,
  CONCAT(u.nombre, ' ', u.apellidos) AS conductor,
  ve.matricula,
  v.origen_desc,
  v.destino_desc,
  TIMESTAMPDIFF(MINUTE, v.solicitado_at, NOW()) AS minutos_desde_solicitud
FROM viaje v
JOIN  usuario   r  ON r.id_usuario   = v.id_rider
LEFT JOIN conductor c  ON c.id_conductor = v.id_conductor
LEFT JOIN usuario   u  ON u.id_usuario   = v.id_conductor
LEFT JOIN vehiculo  ve ON ve.id_vehiculo = v.id_vehiculo
WHERE v.estado IN ('solicitado', 'aceptado', 'en_curso')
ORDER BY v.solicitado_at;


-- Conductores disponibles con su vehículo actual
SELECT
  c.id_conductor,
  CONCAT(u.nombre, ' ', u.apellidos) AS conductor,
  c.rating,
  co.nombre                          AS company,
  ve.matricula,
  CONCAT(ve.marca, ' ', ve.modelo)   AS vehiculo
FROM conductor c
JOIN usuario u   ON u.id_usuario  = c.id_conductor
JOIN company co  ON co.id_company = c.id_company
LEFT JOIN conductor_vehiculo cv ON cv.id_conductor = c.id_conductor
                                AND cv.fecha_hasta IS NULL
LEFT JOIN vehiculo ve ON ve.id_vehiculo = cv.id_vehiculo
WHERE c.disponible = TRUE
  AND u.activo    = TRUE
ORDER BY c.rating DESC;


-- Ingresos por conductor (últimos 30 días)
-- GROUP BY con agregaciones: COUNT, SUM, AVG
SELECT
  CONCAT(u.nombre, ' ', u.apellidos)                                AS conductor,
  co.nombre                                                         AS company,
  COUNT(v.id_viaje)                                                 AS viajes,
  ROUND(SUM(v.precio_euros), 2)                                     AS ingresos_eur,
  ROUND(AVG(v.distancia_km), 2)                                     AS km_medio,
  ROUND(SUM(v.precio_euros) / NULLIF(SUM(v.distancia_km), 0), 2)   AS eur_por_km
FROM viaje v
JOIN conductor c ON c.id_conductor = v.id_conductor
JOIN usuario   u ON u.id_usuario   = v.id_conductor
JOIN company  co ON co.id_company  = c.id_company
WHERE v.estado = 'finalizado'
  AND v.fin_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY v.id_conductor, conductor, company
ORDER BY ingresos_eur DESC;


-- Tasa de aceptación por conductor
SELECT
  CONCAT(u.nombre, ' ', u.apellidos)                                          AS conductor,
  co.nombre                                                                   AS company,
  COUNT(o.id_oferta)                                                          AS total_ofertas,
  SUM(o.estado = 'aceptada')                                                  AS aceptadas,
  SUM(o.estado = 'rechazada')                                                 AS rechazadas,
  ROUND(100 * SUM(o.estado = 'aceptada') / NULLIF(COUNT(o.id_oferta), 0), 1) AS tasa_pct
FROM oferta o
JOIN conductor c ON c.id_conductor = o.id_conductor
JOIN usuario   u ON u.id_usuario   = o.id_conductor
JOIN company  co ON co.id_company  = c.id_company
GROUP BY o.id_conductor, conductor, company
ORDER BY tasa_pct DESC;


-- Ingresos por company
SELECT
  co.nombre                                                          AS company,
  COUNT(DISTINCT c.id_conductor)                                     AS conductores,
  COUNT(v.id_viaje)                                                  AS viajes_finalizados,
  ROUND(SUM(v.precio_euros), 2)                                      AS ingresos_total,
  ROUND(AVG(v.precio_euros), 2)                                      AS ticket_medio,
  ROUND(SUM(v.precio_euros) / NULLIF(SUM(v.distancia_km), 0), 2)   AS eur_por_km
FROM company co
LEFT JOIN conductor c ON c.id_company   = co.id_company
LEFT JOIN viaje     v ON v.id_conductor = c.id_conductor
                      AND v.estado = 'finalizado'
GROUP BY co.id_company, co.nombre
ORDER BY ingresos_total DESC;




-- SECCION 4: SUBCONSULTAS

-- Riders que nunca han completado un viaje
SELECT id_usuario, nombre, apellidos, email
FROM usuario
WHERE tipo = 'rider'
  AND id_usuario NOT IN (
    SELECT id_rider
    FROM viaje
    WHERE estado = 'finalizado'
  );


-- Conductor con más ingresos en los últimos 90 días
SELECT
  CONCAT(u.nombre, ' ', u.apellidos) AS conductor,
  ROUND(SUM(v.precio_euros), 2)      AS ingresos_total
FROM viaje v
JOIN conductor c ON c.id_conductor = v.id_conductor
JOIN usuario   u ON u.id_usuario   = v.id_conductor
WHERE v.estado = 'finalizado'
  AND v.fin_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)
GROUP BY v.id_conductor
ORDER BY ingresos_total DESC
LIMIT 1;
