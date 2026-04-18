-- ============================================================
-- Practica Ride Hailing - BBDD Avanazadas
-- Autores: Javier Picazo, Alejandro Bernaldo de Quiros, Pablo Cerdeira y Jaime Ordovás
-- Grupo: 3A
-- ============================================================

USE ridehailing;

-- Desactivar FK checks durante la carga masiva para mayor velocidad
-- (buena práctica en cargas iniciales)
SET foreign_key_checks = 0;
SET unique_checks      = 0;
SET autocommit         = 0;

-- ============================================================
-- 1. COMPANIES
-- ============================================================
INSERT INTO company (nombre, cif, email) VALUES
  ('RapidoDrive SL', 'B12345678', 'ops@rapidodrive.es'),
  ('UrbanFleet SA',  'A87654321', 'ops@urbanfleet.es'),
  ('EcoRide SL',     'B11223344', 'ops@ecoride.es'),
  ('MegaCab SA',     'A55667788', 'ops@megacab.es'),
  ('CityWheels SL',  'B99887766', 'ops@citywheels.es');

-- ============================================================
-- 2. USUARIOS
-- Insertar sin listar AUTO_INCREMENT (buena práctica: listar columnas)
-- ============================================================

-- Riders
INSERT INTO usuario (tipo, nombre, apellidos, email, telefono, dni) VALUES
  ('rider', 'Ana',       'García López',    'ana.garcia@mail.es',    '600000001', '10000001A'),
  ('rider', 'Luis',      'Martínez Ruiz',   'luis.martinez@mail.es', '600000002', '10000002B'),
  ('rider', 'Sofía',     'Fernández Gil',   'sofia.f@mail.es',       '600000003', '10000003C'),
  ('rider', 'Carlos',    'Sánchez Vega',    'carlos.s@mail.es',      '600000004', '10000004D'),
  ('rider', 'Elena',     'Jiménez Castro',  'elena.j@mail.es',       '600000005', '10000005E'),
  ('rider', 'Pablo',     'López Moreno',    'pablo.l@mail.es',       '600000006', '10000006F'),
  ('rider', 'Lucía',     'Díaz Navarro',    'lucia.d@mail.es',       '600000007', '10000007G'),
  ('rider', 'Miguel',    'Torres Blanco',   'miguel.t@mail.es',      '600000008', '10000008H'),
  ('rider', 'Marta',     'Ramírez Cortés',  'marta.r@mail.es',       '600000009', '10000009I'),
  ('rider', 'Javier',    'Morales Herrera', 'javier.m@mail.es',      '600000010', '10000010J'),
  ('rider', 'Laura',     'Alonso Peña',     'laura.a@mail.es',       '600000011', '10000011K'),
  ('rider', 'David',     'Romero Campos',   'david.r@mail.es',       '600000012', '10000012L'),
  ('rider', 'Cristina',  'Vargas Mendoza',  'cristina.v@mail.es',    '600000013', '10000013M'),
  ('rider', 'Sergio',    'Ríos Paredes',    'sergio.r@mail.es',      '600000014', '10000014N'),
  ('rider', 'Patricia',  'Guerrero Salas',  'patricia.g@mail.es',    '600000015', '10000015O'),
  ('rider', 'Alejandro', 'Fuentes Ibáñez',  'alejandro.f@mail.es',   '600000016', '10000016P'),
  ('rider', 'Isabel',    'Castro Rubio',    'isabel.c@mail.es',       '600000017', '10000017Q'),
  ('rider', 'Raúl',      'Ortega Serrano',  'raul.o@mail.es',         '600000018', '10000018R'),
  ('rider', 'Nuria',     'Molina Arias',    'nuria.m@mail.es',        '600000019', '10000019S'),
  ('rider', 'Alberto',   'Reyes Delgado',   'alberto.r@mail.es',      '600000020', '10000020T');

-- Conductores (id_usuario 21..30)
INSERT INTO usuario (tipo, nombre, apellidos, email, telefono, dni) VALUES
  ('conductor', 'Tomás',   'Pérez Valero',   'tomas.p@driver.es',   '611000001', '20000001A'),
  ('conductor', 'Rosa',    'Gutiérrez Lara', 'rosa.g@driver.es',    '611000002', '20000002B'),
  ('conductor', 'Manuel',  'Herrera Vidal',  'manuel.h@driver.es',  '611000003', '20000003C'),
  ('conductor', 'Beatriz', 'Molero Nieto',   'beatriz.m@driver.es', '611000004', '20000004D'),
  ('conductor', 'Jorge',   'Soler Prats',    'jorge.s@driver.es',   '611000005', '20000005E'),
  ('conductor', 'Adriana', 'Cano Esteve',    'adriana.c@driver.es', '611000006', '20000006F'),
  ('conductor', 'Rubén',   'Pascual Mora',   'ruben.p@driver.es',   '611000007', '20000007G'),
  ('conductor', 'Vanesa',  'Iglesias Bayo',  'vanesa.i@driver.es',  '611000008', '20000008H'),
  ('conductor', 'Marcos',  'Bravo Lozano',   'marcos.b@driver.es',  '611000009', '20000009I'),
  ('conductor', 'Carmen',  'Aguilera Font',  'carmen.a@driver.es',  '611000010', '20000010J');

-- ============================================================
-- 3. CONDUCTORES (perfil extendido)
-- id_conductor = id_usuario (relación 1:1)
-- ============================================================
INSERT INTO conductor (id_conductor, id_company, licencia, fecha_alta, disponible, rating) VALUES
  (21, 1, 'LIC-2020-0001', '2020-01-10', TRUE,  4.85),
  (22, 1, 'LIC-2020-0002', '2020-02-15', TRUE,  4.70),
  (23, 2, 'LIC-2019-0003', '2019-06-01', TRUE,  4.92),
  (24, 2, 'LIC-2021-0004', '2021-03-20', FALSE, 4.60),
  (25, 3, 'LIC-2020-0005', '2020-07-11', TRUE,  4.75),
  (26, 3, 'LIC-2022-0006', '2022-01-05', TRUE,  4.88),
  (27, 4, 'LIC-2018-0007', '2018-09-14', TRUE,  4.55),
  (28, 4, 'LIC-2021-0008', '2021-11-30', TRUE,  4.95),
  (29, 5, 'LIC-2020-0009', '2020-04-22', FALSE, 4.40),
  (30, 5, 'LIC-2023-0010', '2023-02-01', TRUE,  4.80);

-- ============================================================
-- 4. VEHÍCULOS
-- ============================================================
INSERT INTO vehiculo (matricula, marca, modelo, anio, color) VALUES
  ('1234-ABC', 'Toyota',     'Corolla',  2020, 'Blanco'),
  ('5678-DEF', 'Volkswagen', 'Passat',   2021, 'Gris'),
  ('9012-GHI', 'Seat',       'León',     2019, 'Negro'),
  ('3456-JKL', 'BMW',        '3 Series', 2022, 'Azul'),
  ('7890-MNO', 'Hyundai',    'Tucson',   2021, 'Rojo'),
  ('2345-PQR', 'Ford',       'Kuga',     2020, 'Blanco'),
  ('6789-STU', 'Kia',        'Sportage', 2023, 'Gris'),
  ('0123-VWX', 'Renault',    'Megane',   2019, 'Plata'),
  ('4567-YZA', 'Peugeot',    '508',      2022, 'Negro'),
  ('8901-BCD', 'Audi',       'A4',       2021, 'Azul');

-- ============================================================
-- 5. ASIGNACIÓN CONDUCTOR <-> VEHÍCULO
-- fecha_hasta NULL = asignación vigente
-- ============================================================
INSERT INTO conductor_vehiculo (id_conductor, id_vehiculo, fecha_desde, fecha_hasta) VALUES
  (21, 1,  '2020-01-10', NULL),
  (22, 2,  '2020-02-15', NULL),
  (23, 3,  '2019-06-01', NULL),
  (24, 4,  '2021-03-20', NULL),
  (25, 5,  '2020-07-11', NULL),
  (26, 6,  '2022-01-05', NULL),
  (27, 7,  '2018-09-14', NULL),
  (28, 8,  '2021-11-30', NULL),
  (29, 9,  '2020-04-22', NULL),
  (30, 10, '2023-02-01', NULL);

-- ============================================================
-- 6. VIAJES: carga masiva con stored procedure
-- (Tema 5 — Stored procedures con WHILE y variables)
-- ============================================================
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_generar_viajes$$
CREATE PROCEDURE sp_generar_viajes()
BEGIN
  DECLARE i           INT          DEFAULT 1;
  DECLARE v_rider     BIGINT;
  DECLARE v_conductor BIGINT;
  DECLARE v_vehiculo  BIGINT;
  DECLARE v_dist      DECIMAL(8,3);
  DECLARE v_dur       DECIMAL(8,2);
  DECLARE v_precio    DECIMAL(10,2);
  DECLARE v_fecha     DATETIME;

  WHILE i <= 60 DO
    SET v_rider     = 1  + MOD(i - 1, 20);
    SET v_conductor = 21 + MOD(i - 1, 10);
    SET v_vehiculo  = 1  + MOD(i - 1, 10);
    SET v_dist      = ROUND(2 + (RAND() * 28), 2);
    SET v_dur       = ROUND(v_dist * (3 + RAND() * 2), 2);
    -- Tarifa: 2.50 base + 1.20/km + 0.15/min
    SET v_precio    = ROUND(2.50 + v_dist * 1.20 + v_dur * 0.15, 2);
    SET v_fecha     = DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 90) DAY);

    INSERT INTO viaje (
      id_rider, id_conductor, id_vehiculo, estado,
      origen_lat,  origen_lng,  origen_desc,
      destino_lat, destino_lng, destino_desc,
      distancia_km, duracion_min, precio_euros,
      solicitado_at, aceptado_at, inicio_at, fin_at
    ) VALUES (
      v_rider, v_conductor, v_vehiculo, 'finalizado',
      40.4168 + (RAND() - 0.5) * 0.2, -3.7038 + (RAND() - 0.5) * 0.2,
      CONCAT('Calle ', i, ', Madrid'),
      40.4168 + (RAND() - 0.5) * 0.2, -3.7038 + (RAND() - 0.5) * 0.2,
      CONCAT('Avenida ', i, ', Madrid'),
      v_dist, v_dur, v_precio,
      v_fecha,
      DATE_ADD(v_fecha, INTERVAL FLOOR(30  + RAND() * 180) SECOND),
      DATE_ADD(v_fecha, INTERVAL FLOOR(210 + RAND() * 240) SECOND),
      DATE_ADD(v_fecha, INTERVAL FLOOR(ROUND(v_dur * 60) + 300) SECOND)
    );

    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;

CALL sp_generar_viajes();
DROP PROCEDURE IF EXISTS sp_generar_viajes;

-- Viajes en distintos estados para poder probar el ciclo de vida
INSERT INTO viaje (id_rider, estado,
  origen_lat,  origen_lng,  origen_desc,
  destino_lat, destino_lng, destino_desc)
VALUES
  (1, 'solicitado', 40.4200, -3.7050, 'Gran Vía, Madrid',     40.4300, -3.6900, 'Retiro, Madrid'),
  (2, 'solicitado', 40.4100, -3.7200, 'Moncloa, Madrid',      40.4050, -3.7100, 'Chamberí, Madrid'),
  (3, 'aceptado',   40.4250, -3.6950, 'Sol, Madrid',          40.4400, -3.6800, 'Hortaleza, Madrid'),
  (4, 'en_curso',   40.4180, -3.7100, 'Lavapiés, Madrid',     40.3900, -3.7300, 'Carabanchel, Madrid'),
  (5, 'cancelado',  40.4300, -3.6800, 'Chueca, Madrid',       40.4500, -3.7000, 'Tetuán, Madrid'),
  (6, 'cancelado',  40.4050, -3.6950, 'Salamanca, Madrid',    40.3850, -3.6750, 'Vallecas, Madrid');

-- ============================================================
-- 7. OFERTAS
-- ============================================================
-- Viajes solicitados: varias ofertas pendientes a distintos conductores
INSERT INTO oferta (id_viaje, id_conductor, estado, enviada_at)
  SELECT id_viaje, 21 + MOD(id_viaje, 10), 'pendiente', NOW()
  FROM viaje WHERE estado = 'solicitado';

INSERT INTO oferta (id_viaje, id_conductor, estado, enviada_at)
  SELECT id_viaje, 21 + MOD(id_viaje + 1, 10), 'pendiente', NOW()
  FROM viaje WHERE estado = 'solicitado';

INSERT INTO oferta (id_viaje, id_conductor, estado, enviada_at)
  SELECT id_viaje, 21 + MOD(id_viaje + 2, 10), 'rechazada', NOW() - INTERVAL 30 SECOND
  FROM viaje WHERE estado = 'solicitado';

-- Viajes finalizados: oferta aceptada por el conductor asignado
INSERT INTO oferta (id_viaje, id_conductor, estado, enviada_at, respondida_at)
SELECT
  v.id_viaje,
  v.id_conductor,
  'aceptada',
  DATE_SUB(v.aceptado_at, INTERVAL 20 SECOND),
  v.aceptado_at
FROM viaje v
WHERE v.estado = 'finalizado' AND v.id_conductor IS NOT NULL
LIMIT 60;

-- Ofertas rechazadas por otros conductores del mismo viaje
INSERT INTO oferta (id_viaje, id_conductor, estado, enviada_at, respondida_at)
SELECT
  v.id_viaje,
  21 + MOD(v.id_viaje + 3, 10),
  'rechazada',
  DATE_SUB(v.aceptado_at, INTERVAL 60 SECOND),
  DATE_SUB(v.aceptado_at, INTERVAL 25 SECOND)
FROM viaje v
WHERE v.estado = 'finalizado'
  AND v.id_conductor != 21 + MOD(v.id_viaje + 3, 10)
LIMIT 40;

-- ============================================================
-- 8. PAGOS (un pago por viaje finalizado)
-- ============================================================
INSERT INTO pago (id_viaje, id_rider, id_conductor, importe_euros, metodo, estado, procesado_at)
SELECT
  v.id_viaje,
  v.id_rider,
  v.id_conductor,
  v.precio_euros,
  ELT(1 + MOD(v.id_viaje, 3), 'tarjeta', 'wallet', 'tarjeta'),
  'completado',
  v.fin_at
FROM viaje v
WHERE v.estado = 'finalizado' AND v.id_conductor IS NOT NULL;

COMMIT;
SET foreign_key_checks = 1;
SET unique_checks       = 1;
SET autocommit          = 1;
