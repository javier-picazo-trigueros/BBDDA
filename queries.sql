-- ============================================================
-- Practica Ride Hailing - BBDD Avanazadas
-- Consultas operativas
-- ============================================================

USE ridehailing;


-- SECCION 1: OPERATIVA BASICA - INSERT, UPDATE, DELETE

INSERT INTO usuario (tipo, nombre, apellidos, email, telefono, dni)
VALUES ('rider', 'Nuevo', 'Rider Ejemplo', 'nuevo.rider@mail.es', '699000099', '99000099Z');


START TRANSACTION;

  INSERT INTO usuario (tipo, nombre, apellidos, email, telefono, dni)
  VALUES ('conductor', 'Nuevo', 'Conductor Ejemplo', 'nuevo.conductor@driver.es', '688000088', '98000088Y');

  SET @nuevo_conductor_id = LAST_INSERT_ID();

  INSERT INTO conductor (id_conductor, id_company, licencia, fecha_alta)
  VALUES (@nuevo_conductor_id, 1, 'LIC-2024-9999', CURRENT_DATE);

COMMIT;


INSERT INTO viaje (
  id_rider,
  origen_lat, origen_lng, origen_desc,
  destino_lat, destino_lng, destino_desc
) VALUES (
  1,
  40.4168, -3.7038, 'Puerta del Sol, Madrid',
  40.4530, -3.6883, 'Estadio Bernabeu, Madrid'
);

SET @id_viaje_nuevo = LAST_INSERT_ID();


INSERT INTO oferta (id_viaje, id_conductor, enviada_at)
SELECT @id_viaje_nuevo, c.id_conductor, NOW()
FROM conductor c
WHERE c.disponible = TRUE
LIMIT 5;


UPDATE usuario
SET activo = FALSE
WHERE id_usuario = 99;


UPDATE oferta
SET estado = 'expirada'
WHERE estado = 'pendiente'
  AND enviada_at < DATE_SUB(NOW(), INTERVAL 5 MINUTE);


-- SECCION 2: OPERACIONES TRANSACCIONALES
-- Estas llamadas asumen una base recien cargada con data.sql.

CALL sp_aceptar_oferta(1, 22, @resultado);
SELECT @resultado AS resultado_aceptacion;

CALL sp_iniciar_viaje(61, 22, @resultado);
SELECT @resultado AS resultado_inicio;

CALL sp_finalizar_viaje(61, 8.500, 18.25, @resultado);
SELECT @resultado AS resultado_fin;


-- SECCION 3: CONSULTAS CON JOIN

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
JOIN usuario r        ON r.id_usuario = v.id_rider
LEFT JOIN conductor c ON c.id_conductor = v.id_conductor
LEFT JOIN usuario u   ON u.id_usuario = v.id_conductor
LEFT JOIN company co  ON co.id_company = c.id_company
WHERE v.id_rider = 1
ORDER BY v.solicitado_at DESC;


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
JOIN usuario r        ON r.id_usuario = v.id_rider
LEFT JOIN conductor c ON c.id_conductor = v.id_conductor
LEFT JOIN usuario u   ON u.id_usuario = v.id_conductor
LEFT JOIN vehiculo ve ON ve.id_vehiculo = v.id_vehiculo
WHERE v.estado IN ('solicitado', 'aceptado', 'en_curso')
ORDER BY v.solicitado_at;


SELECT
  c.id_conductor,
  CONCAT(u.nombre, ' ', u.apellidos) AS conductor,
  c.rating,
  co.nombre                          AS company,
  ve.matricula,
  CONCAT(ve.marca, ' ', ve.modelo)   AS vehiculo
FROM conductor c
JOIN usuario u           ON u.id_usuario = c.id_conductor
JOIN company co          ON co.id_company = c.id_company
LEFT JOIN conductor_vehiculo cv
  ON cv.id_conductor = c.id_conductor
 AND cv.fecha_hasta IS NULL
LEFT JOIN vehiculo ve ON ve.id_vehiculo = cv.id_vehiculo
WHERE c.disponible = TRUE
  AND u.activo = TRUE
ORDER BY c.rating DESC;


SELECT
  CONCAT(u.nombre, ' ', u.apellidos)                              AS conductor,
  co.nombre                                                       AS company,
  COUNT(v.id_viaje)                                               AS viajes,
  ROUND(SUM(v.precio_euros), 2)                                   AS ingresos_eur,
  ROUND(AVG(v.distancia_km), 2)                                   AS km_medio,
  ROUND(SUM(v.precio_euros) / NULLIF(SUM(v.distancia_km), 0), 2)  AS eur_por_km
FROM viaje v
JOIN conductor c ON c.id_conductor = v.id_conductor
JOIN usuario u   ON u.id_usuario = v.id_conductor
JOIN company co  ON co.id_company = c.id_company
WHERE v.estado = 'finalizado'
  AND v.fin_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY v.id_conductor, conductor, company
ORDER BY ingresos_eur DESC;


SELECT
  CONCAT(u.nombre, ' ', u.apellidos)                              AS conductor,
  co.nombre                                                       AS company,
  COUNT(o.id_oferta)                                              AS total_ofertas,
  SUM(o.estado = 'aceptada')                                      AS aceptadas,
  SUM(o.estado = 'rechazada')                                     AS rechazadas,
  ROUND(100 * SUM(o.estado = 'aceptada') / NULLIF(COUNT(o.id_oferta), 0), 1)
                                                                 AS tasa_pct
FROM oferta o
JOIN conductor c ON c.id_conductor = o.id_conductor
JOIN usuario u   ON u.id_usuario = o.id_conductor
JOIN company co  ON co.id_company = c.id_company
GROUP BY o.id_conductor, conductor, company
ORDER BY tasa_pct DESC;


SELECT
  co.nombre                                                       AS company,
  COUNT(DISTINCT c.id_conductor)                                  AS conductores,
  COUNT(v.id_viaje)                                               AS viajes_finalizados,
  ROUND(SUM(v.precio_euros), 2)                                   AS ingresos_total,
  ROUND(AVG(v.precio_euros), 2)                                   AS ticket_medio,
  ROUND(SUM(v.precio_euros) / NULLIF(SUM(v.distancia_km), 0), 2)  AS eur_por_km
FROM company co
LEFT JOIN conductor c ON c.id_company = co.id_company
LEFT JOIN viaje v
  ON v.id_conductor = c.id_conductor
 AND v.estado = 'finalizado'
GROUP BY co.id_company, co.nombre
ORDER BY ingresos_total DESC;


-- SECCION 4: SUBCONSULTAS

SELECT id_usuario, nombre, apellidos, email
FROM usuario
WHERE tipo = 'rider'
  AND id_usuario NOT IN (
    SELECT id_rider
    FROM viaje
    WHERE estado = 'finalizado'
  );


SELECT
  CONCAT(u.nombre, ' ', u.apellidos) AS conductor,
  ROUND(SUM(v.precio_euros), 2)      AS ingresos_total
FROM viaje v
JOIN conductor c ON c.id_conductor = v.id_conductor
JOIN usuario u   ON u.id_usuario = v.id_conductor
WHERE v.estado = 'finalizado'
  AND v.fin_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)
GROUP BY v.id_conductor
ORDER BY ingresos_total DESC
LIMIT 1;
