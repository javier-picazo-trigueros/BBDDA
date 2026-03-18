-- ============================================================
-- dashboard.sql  —  Consultas para dashboards
-- Ride-Hailing Database  |  MySQL 8.0
-- ============================================================

USE ridehailing;

-- ============================================================
-- DASHBOARD 1: MÉTRICAS DE BASE DE DATOS
-- ============================================================

-- DB-1. Tamaño de cada tabla en MB
SELECT
  TABLE_NAME                                         AS tabla,
  TABLE_ROWS                                         AS filas_estimadas,
  ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) AS total_mb,
  ROUND(DATA_LENGTH  / 1024 / 1024, 2)               AS datos_mb,
  ROUND(INDEX_LENGTH / 1024 / 1024, 2)               AS indices_mb
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'ridehailing'
ORDER BY total_mb DESC;

-- DB-2. Conexiones activas vs límite
SELECT
  (SELECT VARIABLE_VALUE FROM performance_schema.global_status  WHERE VARIABLE_NAME = 'Threads_connected')     AS conexiones_activas,
  (SELECT VARIABLE_VALUE FROM performance_schema.global_variables WHERE VARIABLE_NAME = 'max_connections')      AS conexiones_maximo,
  (SELECT VARIABLE_VALUE FROM performance_schema.global_status  WHERE VARIABLE_NAME = 'Max_used_connections')  AS pico_historico,
  ROUND(
    100 * (SELECT VARIABLE_VALUE FROM performance_schema.global_status  WHERE VARIABLE_NAME = 'Threads_connected')
        / (SELECT VARIABLE_VALUE FROM performance_schema.global_variables WHERE VARIABLE_NAME = 'max_connections'),
    1
  ) AS uso_pct;

-- DB-3. Buffer pool hit ratio (debe ser > 99%)
SELECT
  ROUND(
    (1 - (
       (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_buffer_pool_reads')
     / (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_buffer_pool_read_requests')
    )) * 100, 2
  ) AS buffer_pool_hit_ratio_pct;

-- DB-4. Queries lentas acumuladas y por segundo
SELECT
  (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Slow_queries')    AS slow_queries_total,
  (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Queries')         AS queries_total,
  (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Com_select')      AS selects,
  (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Com_insert')      AS inserts,
  (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Com_update')      AS updates,
  (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Com_delete')      AS deletes;

-- DB-5. Deadlocks e InnoDB row locks
SELECT
  (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_deadlocks')          AS deadlocks,
  (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_row_lock_waits')      AS row_lock_waits,
  (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_row_lock_time_avg')   AS avg_lock_time_ms;

-- DB-6. Transacciones activas (bloqueos actuales)
SELECT
  trx_id,
  trx_state,
  trx_started,
  TIMESTAMPDIFF(SECOND, trx_started, NOW()) AS segundos_activa,
  trx_mysql_thread_id                       AS thread_id,
  LEFT(trx_query, 120)                      AS query_actual
FROM information_schema.INNODB_TRX
ORDER BY trx_started;

-- DB-7. Top 10 queries más lentas (performance_schema)
SELECT
  DIGEST_TEXT,
  COUNT_STAR          AS veces_ejecutada,
  ROUND(AVG_TIMER_WAIT / 1e9, 3)   AS avg_ms,
  ROUND(MAX_TIMER_WAIT / 1e9, 3)   AS max_ms,
  ROUND(SUM_TIMER_WAIT / 1e9, 3)   AS total_ms
FROM performance_schema.events_statements_summary_by_digest
WHERE SCHEMA_NAME = 'ridehailing'
ORDER BY avg_ms DESC
LIMIT 10;

-- DB-8. Índices no usados
SELECT OBJECT_SCHEMA, OBJECT_NAME, INDEX_NAME
FROM sys.schema_unused_indexes
WHERE OBJECT_SCHEMA = 'ridehailing';

-- ============================================================
-- DASHBOARD 2: MÉTRICAS DE NEGOCIO
-- ============================================================

-- BIZ-1. Viajes por hora (últimas 24 h)
SELECT
  DATE_FORMAT(solicitado_at, '%Y-%m-%d %H:00') AS hora,
  COUNT(*)                                      AS total_viajes,
  SUM(estado = 'finalizado')                   AS finalizados,
  SUM(estado = 'cancelado')                    AS cancelados,
  SUM(estado IN ('solicitado','aceptado','en_curso')) AS activos
FROM viaje
WHERE solicitado_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY hora
ORDER BY hora;

-- BIZ-2. KPIs globales en tiempo real
SELECT
  COUNT(*)                                                           AS total_viajes,
  SUM(estado = 'finalizado')                                        AS finalizados,
  SUM(estado = 'cancelado')                                         AS cancelados,
  SUM(estado IN ('solicitado','aceptado','en_curso'))                AS en_progreso,
  ROUND(100 * SUM(estado = 'cancelado') / NULLIF(COUNT(*), 0), 1)   AS tasa_cancelacion_pct,
  ROUND(AVG(CASE WHEN estado = 'finalizado' THEN distancia_km END), 2) AS km_medio,
  ROUND(AVG(CASE WHEN estado = 'finalizado' THEN duracion_min END), 2) AS min_medio,
  ROUND(AVG(CASE WHEN estado = 'finalizado' THEN precio_euros END), 2) AS ticket_medio,
  ROUND(SUM(CASE WHEN estado = 'finalizado' THEN precio_euros END), 2) AS ingresos_totales
FROM viaje;

-- BIZ-3. Ofertas aceptadas vs rechazadas (últimos 7 días)
SELECT
  DATE(enviada_at)                                        AS dia,
  COUNT(*)                                                AS total_ofertas,
  SUM(estado = 'aceptada')                               AS aceptadas,
  SUM(estado = 'rechazada')                              AS rechazadas,
  SUM(estado = 'pendiente')                              AS pendientes,
  ROUND(100 * SUM(estado = 'aceptada') / NULLIF(COUNT(*), 0), 1) AS tasa_aceptacion_pct
FROM oferta
WHERE enviada_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY dia
ORDER BY dia;

-- BIZ-4. Top 5 conductores por ingresos (últimos 30 días)
SELECT
  CONCAT(u.nombre, ' ', u.apellidos)   AS conductor,
  co.nombre                             AS company,
  COUNT(v.id_viaje)                     AS viajes,
  ROUND(SUM(v.precio_euros), 2)         AS ingresos_eur,
  ROUND(AVG(v.precio_euros / NULLIF(v.distancia_km, 0)), 2) AS eur_por_km,
  ROUND(AVG(v.precio_euros / NULLIF(v.duracion_min,  0)), 2) AS eur_por_min
FROM viaje v
JOIN conductor c ON c.id_conductor = v.id_conductor
JOIN usuario   u ON u.id_usuario   = v.id_conductor
JOIN company  co ON co.id_company  = c.id_company
WHERE v.estado = 'finalizado'
  AND v.fin_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY v.id_conductor, conductor, company
ORDER BY ingresos_eur DESC
LIMIT 5;

-- BIZ-5. Rendimiento por company
SELECT * FROM v_metricas_company ORDER BY ingresos_totales DESC;

-- BIZ-6. Tiempo medio de espera del rider (solicitud → inicio del viaje) en minutos
SELECT
  ROUND(AVG(TIMESTAMPDIFF(SECOND, solicitado_at, inicio_at)) / 60, 2) AS espera_media_min,
  ROUND(MIN(TIMESTAMPDIFF(SECOND, solicitado_at, inicio_at)) / 60, 2) AS espera_min,
  ROUND(MAX(TIMESTAMPDIFF(SECOND, solicitado_at, inicio_at)) / 60, 2) AS espera_max
FROM viaje
WHERE estado = 'finalizado'
  AND inicio_at IS NOT NULL;

-- BIZ-7. Distribución de viajes por franja horaria
SELECT
  CASE
    WHEN HOUR(solicitado_at) BETWEEN  6 AND  9 THEN 'Mañana temprano (06-09)'
    WHEN HOUR(solicitado_at) BETWEEN 10 AND 13 THEN 'Mañana (10-13)'
    WHEN HOUR(solicitado_at) BETWEEN 14 AND 17 THEN 'Tarde temprano (14-17)'
    WHEN HOUR(solicitado_at) BETWEEN 18 AND 21 THEN 'Tarde (18-21)'
    ELSE                                             'Noche (22-05)'
  END                                AS franja,
  COUNT(*)                           AS viajes,
  ROUND(AVG(precio_euros), 2)        AS ticket_medio
FROM viaje
WHERE estado = 'finalizado'
GROUP BY franja
ORDER BY viajes DESC;

-- BIZ-8. Riders más activos
SELECT
  CONCAT(u.nombre, ' ', u.apellidos) AS rider,
  COUNT(v.id_viaje)                   AS total_viajes,
  SUM(v.estado = 'finalizado')       AS finalizados,
  ROUND(SUM(v.precio_euros), 2)      AS gasto_total
FROM viaje v
JOIN usuario u ON u.id_usuario = v.id_rider
GROUP BY v.id_rider, rider
ORDER BY total_viajes DESC
LIMIT 10;
