-- ============================================================
-- Practica Ride Hailing - BBDD Avanazadas
-- Autores: Javier Picazo, Alejandro Bernaldo de Quiros, Pablo Cerdeira y Jaime Ordovás
-- Grupo: 3A
-- ============================================================

USE ridehailing;

-- Desactivar validaciones para la carga inicial
SET foreign_key_checks = 0;
SET unique_checks      = 0;
SET autocommit         = 0;


-- COMPAÑIAS
INSERT INTO company (nombre, cif, email) VALUES
  ('Nuber', 'J65932322', 'ops@nuber.es'),
  ('Pabify',  'P65826483', 'ops@pabify.es'),
  ('Wolt',     'A77854312', 'ops@wolt.es'),
  ('Left',     'J98742699', 'ops@left.es'),
  ('Free Later',  'G56743892', 'ops@freelater.es');

-- USUARIOS
-- Riders
INSERT INTO usuario (tipo, nombre, apellidos, email, telefono, dni) VALUES
  ('rider', 'María',      'Acevedo Bueno',             'maria.acevedo@mail.es',      '612345001', '12345678A'),
  ('rider', 'Javier',     'Antón Ordoñez',             'javier.anton@mail.es',       '612345002', '23456789B'),
  ('rider', 'Alejandro',  'Bernaldo de Quirós Gómez',  'alejandro.bernaldo@mail.es', '612345003', '34567890C'),
  ('rider', 'Pablo',      'Cerdeira Crespo',           'pablo.cerdeira@mail.es',     '612345004', '45678901D'),
  ('rider', 'Irene',      'de Rosario Montero',        'irene.rosario@mail.es',      '612345005', '56789012E'),
  ('rider', 'María',      'Fernández del Pozo Romero', 'maria.fernandez@mail.es',    '612345006', '67890123F'),
  ('rider', 'Javier',     'López Ranero',              'javier.lopez@mail.es',       '612345007', '78901234G'),
  ('rider', 'Robert',     'Lucero Rodríguez',          'robert.lucero@mail.es',      '612345008', '89012345H'),
  ('rider', 'Antonio',    'Martínez Miguel',           'antonio.martinez@mail.es',   '612345009', '90123456J'),
  ('rider', 'Raúl',       'Muñoz Dobón',               'raul.munoz@mail.es',         '612345010', '11223344K'),
  ('rider', 'Jaime',      'Ordovás Curbera',           'jaime.ordovas@mail.es',      '612345011', '22334455L'),
  ('rider', 'Juan Diego', 'Panchón Vidal',             'juan.panchon@mail.es',       '612345012', '33445566M'),
  ('rider', 'Ángela',     'Pérez López',               'angela.perez@mail.es',       '612345013', '44556677N'),
  ('rider', 'Javier',     'Picazo Trigueros',          'javier.picazo@mail.es',      '612345014', '55667788P'),
  ('rider', 'Fernando',   'Romero Martín',             'fernando.romero@mail.es',    '612345015', '66778899Q'),
  ('rider', 'Daniel',     'Sama Clemente',             'daniel.sama@mail.es',        '612345016', '77889900R'),
  ('rider', 'Alejandro',  'Teba Ruiz',                 'alejandro.teba@mail.es',     '612345017', '88990011S'),
  ('rider', 'Juan',       'Valdivia Conde',            'juan.valdivia@mail.es',      '612345018', '99001122T'),
  ('rider', 'Pablo',      'López Amengual',            'pablo.lopez@mail.es',        '616583339', '87397847H'),
  ('rider', 'Álvaro',     'Castañeda Mora',            'alvaro.castañeda@mail.es',   '629849202', '85938903G');

-- Conductores
INSERT INTO usuario (tipo, nombre, apellidos, email, telefono, dni) VALUES
  ('conductor', 'Iván',    'Barcia Santos',          'ivan.barcia@driver.es',       '698498329', '51515434R'),
  ('conductor', 'Susana',  'Bautista Blasco',        'susana.bautista@driver.es',   '692942330', '52525375F'),
  ('conductor', 'Alberto', 'Celedon Fernandez',      'alberto.celedon@driver.es',   '618782939', '58748374F'),
  ('conductor', 'Héctor',  'Molina García',          'hector.molina@driver.es',     '618739827', '32748995D'),
  ('conductor', 'Olga',    'Peñalba Rodríguez',      'olga.penalba@driver.es',      '610983930', '46736487L'),
  ('conductor', 'Gonzalo', 'de las Heras de Matías', 'gonzalo.heras@driver.es',     '621920930', '87967097G'),
  ('conductor', 'Moisés',  'Martínez Muñoz',         'moises.martinez@driver.es',   '657634834', '37467438W'),
  ('conductor', 'Rodrigo', 'Díaz Morón',             'rodrigo.diaz@driver.es',      '632389238', '87493908G'),
  ('conductor', 'Roberto', 'Rodríguez Galán',        'roberto.rodriguez@driver.es', '634231422', '47374894T'),
  ('conductor', 'Elam',    'Uceda Herrrero',         'elam.uceda@driver.es',        '679687607', '83989239J');



-- CONDUCTORES COMPLETOS
INSERT INTO conductor (id_conductor, id_company, licencia, fecha_alta, disponible, rating) VALUES
  (21, 1, 'LIC-2025-0001', '2025-01-10', TRUE,  4.85),
  (22, 1, 'LIC-2024-0002', '2024-02-15', TRUE,  4.70),
  (23, 2, 'LIC-2022-0003', '2022-06-01', TRUE,  4.92),
  (24, 2, 'LIC-2024-0004', '2024-03-20', FALSE, 4.60),
  (25, 3, 'LIC-2023-0005', '2023-07-11', TRUE,  4.75),
  (26, 3, 'LIC-2026-0006', '2026-01-05', TRUE,  4.88),
  (27, 4, 'LIC-2023-0007', '2023-09-14', TRUE,  4.55),
  (28, 4, 'LIC-2024-0008', '2024-11-30', TRUE,  4.95),
  (29, 5, 'LIC-2020-0009', '2020-04-22', FALSE, 4.40),
  (30, 5, 'LIC-2024-0010', '2024-02-01', TRUE,  4.80);



-- VEHICULOS
INSERT INTO vehiculo (matricula, marca, modelo, anio, color) VALUES
  ('1234-ABC', 'Mercedes-Benz', 'Clase S',        2025, 'Negro'),
  ('5678-DEF', 'BMW',           'Serie 7',        2024, 'Gris'),
  ('9012-GHI', 'Audi',          'A8',             2022, 'Blanco'),
  ('3456-JKL', 'Porsche',       'Panamera',       2024, 'Azul'),
  ('7890-MNO', 'Range Rover',   'Sport',          2023, 'Negro'),
  ('2345-PQR', 'Tesla',         'Model S',        2026, 'Blanco'),
  ('6789-STU', 'Maserati',      'Ghibli',         2023, 'Gris'),
  ('0123-VWX', 'Lexus',         'LS 500',         2021, 'Rojo'),
  ('4567-YZA', 'Jaguar',        'XF',             2020, 'Azul'),
  ('8901-BCD', 'Porsche',       'Cayenne',        2024, 'Negro');



-- ASIGNACION CONDUCTOR con VEHICULO
INSERT INTO conductor_vehiculo (id_conductor, id_vehiculo, fecha_desde, fecha_hasta) VALUES
  (21, 1,  '2025-01-10', NULL),
  (22, 2,  '2024-02-15', NULL),
  (23, 3,  '2022-06-01', NULL),
  (24, 4,  '2024-03-20', NULL),
  (25, 5,  '2023-07-11', NULL),
  (26, 6,  '2026-01-05', NULL),
  (27, 7,  '2023-09-14', NULL),
  (28, 8,  '2024-11-30', NULL),
  (29, 9,  '2020-04-22', NULL),
  (30, 10, '2024-02-01', NULL);



-- VIAJES
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

-- Viajes de ejemplo en distintos estados
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




-- OFERTAS
INSERT INTO oferta (id_viaje, id_conductor, estado, enviada_at)
  SELECT id_viaje, 21 + MOD(id_viaje, 10), 'pendiente', NOW()
  FROM viaje WHERE estado = 'solicitado';

INSERT INTO oferta (id_viaje, id_conductor, estado, enviada_at)
  SELECT id_viaje, 21 + MOD(id_viaje + 1, 10), 'pendiente', NOW()
  FROM viaje WHERE estado = 'solicitado';

INSERT INTO oferta (id_viaje, id_conductor, estado, enviada_at)
  SELECT id_viaje, 21 + MOD(id_viaje + 2, 10), 'rechazada', NOW() - INTERVAL 30 SECOND
  FROM viaje WHERE estado = 'solicitado';


-- Viajes finalizados
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


-- Ofertas rechazadas
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




-- PAGOS
INSERT INTO pago (id_viaje, id_rider, id_conductor, importe_euros, metodo, estado, procesado_at)
SELECT
  v.id_viaje,
  v.id_rider,
  v.id_conductor,
  v.precio_euros,
  CASE MOD(v.id_viaje, 3)
    WHEN 0 THEN 'tarjeta'
    WHEN 1 THEN 'wallet'
    ELSE        'tarjeta'
  END,
  'completado',
  v.fin_at
FROM viaje v
WHERE v.estado = 'finalizado' AND v.id_conductor IS NOT NULL;


-- Restaurar validaciones
COMMIT;
SET foreign_key_checks = 1;
SET unique_checks       = 1;
SET autocommit          = 1;
