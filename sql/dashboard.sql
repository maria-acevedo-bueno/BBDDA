USE ride_hailing;

-- RESUMEN GENERAL DEL SISTEMA

-- Conteo global de las entradas por cada tabla en la base de datos.
SELECT 'usuarios' AS metrica, COUNT(*) AS total
FROM usuario
UNION ALL
SELECT 'riders', COUNT(*)
FROM rider
UNION ALL
SELECT 'conductores', COUNT(*)
FROM conductor
UNION ALL
SELECT 'companies', COUNT(*)
FROM company
UNION ALL
SELECT 'vehiculos', COUNT(*)
FROM vehiculo
UNION ALL
SELECT 'viajes', COUNT(*)
FROM viaje
UNION ALL
SELECT 'ofertas', COUNT(*)
FROM oferta
UNION ALL
SELECT 'pagos', COUNT(*)
FROM pago
UNION ALL
SELECT 'operaciones_auditadas', COUNT(*)
FROM audit_operacion;

-- Conteo de viajes por estado (cuántos viajes están solicitados, aceptados, en curso, finalizados o cancelados).
SELECT
    estado,
    COUNT(*) AS total_viajes
FROM viaje
GROUP BY estado
ORDER BY total_viajes DESC;

-- Conteo de ofertas por estado (cuántas ofertas están pendientes, aceptadas, rechazadas o expiradas).
SELECT
    estado_oferta,
    COUNT(*) AS total_ofertas
FROM oferta
GROUP BY estado_oferta
ORDER BY total_ofertas DESC;

-- MÉTRICAS DE NEGOCIO

-- Métrica que muestra viajes solicitados a lo largo del día.
SELECT
    HOUR(fecha_solicitud) AS hora_del_dia,
    COUNT(*) AS total_viajes_solicitados
FROM viaje
GROUP BY HOUR(fecha_solicitud)
ORDER BY hora_del_dia ASC;

-- Métrica que muestra ofertas aceptadas a lo largo del día.
SELECT
    HOUR(fecha_respuesta) AS hora_del_dia,
    COUNT(*) AS ofertas_aceptadas
FROM oferta
WHERE estado_oferta = 'aceptada'
  AND fecha_respuesta IS NOT NULL
GROUP BY HOUR(fecha_respuesta)
ORDER BY hora_del_dia ASC;

-- Métrica de tasa de aceptación por conductor en la que calcula: (ofertas aceptadas / total de ofertas recibidas) * 100
SELECT
    o.id_conductor,
    u.nombre AS conductor,
    COUNT(o.id_oferta) AS total_ofertas_recibidas,
    SUM(CASE WHEN o.estado_oferta = 'aceptada' THEN 1 ELSE 0 END) AS ofertas_aceptadas,
    ROUND(
        CASE
            WHEN COUNT(o.id_oferta) = 0 THEN 0
            ELSE SUM(CASE WHEN o.estado_oferta = 'aceptada' THEN 1 ELSE 0 END)
                 / COUNT(o.id_oferta) * 100
        END,
        2
    ) AS tasa_aceptacion_pct
FROM oferta o
JOIN usuario u
    ON u.id_usuario = o.id_conductor
GROUP BY o.id_conductor, u.nombre
ORDER BY tasa_aceptacion_pct DESC;

-- Métrica de tasa de aceptación por company en la que calcula: (ofertas aceptadas / total de ofertas recibidas) * 100
SELECT
    c.id_company,
    c.nombre AS company,
    COUNT(o.id_oferta) AS total_ofertas,
    SUM(CASE WHEN o.estado_oferta = 'aceptada' THEN 1 ELSE 0 END) AS ofertas_aceptadas,
    ROUND(
        CASE
            WHEN COUNT(o.id_oferta) = 0 THEN 0
            ELSE SUM(CASE WHEN o.estado_oferta = 'aceptada' THEN 1 ELSE 0 END)
                 / COUNT(o.id_oferta) * 100
        END,
        2
    ) AS tasa_aceptacion_pct
FROM oferta o
JOIN conductor cond
    ON cond.id_usuario = o.id_conductor
JOIN company c
    ON c.id_company = cond.id_company
GROUP BY c.id_company, c.nombre
ORDER BY tasa_aceptacion_pct DESC;

-- Métrica de kilometraje medio y duración media de viajes finalizados (que tengan fechas de inicio y fin registradas).
SELECT
    COUNT(*) AS viajes_finalizados,
    ROUND(AVG(distancia_km), 2) AS kilometraje_medio_km,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, fecha_inicio, fecha_fin)), 2) AS duracion_media_minutos
FROM viaje
WHERE estado = 'finalizado'
  AND fecha_inicio IS NOT NULL
  AND fecha_fin IS NOT NULL;

-- Métrica de ingresos por conductor que incluye euros/km y euros/minuto.
SELECT
    v.id_conductor,
    u.nombre AS conductor,
    COUNT(v.id_viaje) AS viajes_finalizados,
    ROUND(SUM(p.importe_conductor), 2) AS ingresos_conductor,
    ROUND(
        CASE
            WHEN SUM(v.distancia_km) = 0 THEN 0
            ELSE SUM(p.importe_conductor) / SUM(v.distancia_km)
        END,
        2
    ) AS euros_por_km,
    ROUND(
        CASE
            WHEN SUM(TIMESTAMPDIFF(MINUTE, v.fecha_inicio, v.fecha_fin)) = 0 THEN 0
            ELSE SUM(p.importe_conductor)
                 / SUM(TIMESTAMPDIFF(MINUTE, v.fecha_inicio, v.fecha_fin))
        END,
        2
    ) AS euros_por_minuto
FROM pago p
JOIN viaje v
    ON v.id_viaje = p.id_viaje
JOIN usuario u
    ON u.id_usuario = v.id_conductor
WHERE v.estado = 'finalizado'
  AND p.estado_pago = 'completado'
  AND v.fecha_inicio IS NOT NULL
  AND v.fecha_fin IS NOT NULL
GROUP BY v.id_conductor, u.nombre
ORDER BY ingresos_conductor DESC;

-- Métrica de ingresos por company que usa la comisión registrada en pago como ingreso de la company/plataforma.
SELECT
    c.id_company,
    c.nombre AS company,
    COUNT(v.id_viaje) AS viajes_finalizados,
    ROUND(SUM(p.comision_company), 2) AS ingresos_company,
    ROUND(
        CASE
            WHEN SUM(v.distancia_km) = 0 THEN 0
            ELSE SUM(p.comision_company) / SUM(v.distancia_km)
        END,
        2
    ) AS euros_company_por_km,
    ROUND(
        CASE
            WHEN SUM(TIMESTAMPDIFF(MINUTE, v.fecha_inicio, v.fecha_fin)) = 0 THEN 0
            ELSE SUM(p.comision_company)
                 / SUM(TIMESTAMPDIFF(MINUTE, v.fecha_inicio, v.fecha_fin))
        END,
        2
    ) AS euros_company_por_minuto
FROM pago p
JOIN viaje v
    ON v.id_viaje = p.id_viaje
JOIN conductor cond
    ON cond.id_usuario = v.id_conductor
JOIN company c
    ON c.id_company = cond.id_company
WHERE v.estado = 'finalizado'
  AND p.estado_pago = 'completado'
  AND v.fecha_inicio IS NOT NULL
  AND v.fecha_fin IS NOT NULL
GROUP BY c.id_company, c.nombre
ORDER BY ingresos_company DESC;

-- Métrica de valoración media por conductor que calcula la puntuación media de las valoraciones recibidas por cada conductor.
SELECT
    val.id_usuario_valorado AS id_conductor,
    u.nombre AS conductor,
    COUNT(*) AS total_valoraciones,
    ROUND(AVG(val.puntuacion), 2) AS puntuacion_media
FROM valoracion val
JOIN usuario u
    ON u.id_usuario = val.id_usuario_valorado
WHERE val.rol_valorado = 'conductor'
GROUP BY val.id_usuario_valorado, u.nombre
ORDER BY puntuacion_media DESC;

-- MÉTRICAS DE BASE DE DATOS PARA MONITORIZACIÓN

-- Uptime del servidor MySQL.
SHOW STATUS LIKE 'Uptime';

-- Conexiones activas.
SHOW STATUS LIKE 'Threads_connected';

-- Máximo de conexiones alcanzado.
SHOW STATUS LIKE 'Max_used_connections';

-- Límite de conexiones configurado.
SHOW VARIABLES LIKE 'max_connections';

-- Conexiones rechazadas por superar max_connections.
SHOW STATUS LIKE 'Connection_errors_max_connections';

-- Total de queries ejecutadas.
SHOW STATUS LIKE 'Queries';

-- Total de preguntas/consultas recibidas desde clientes.
SHOW STATUS LIKE 'Questions';

-- Desglose de operaciones por tipo.
SHOW STATUS LIKE 'Com_select';
SHOW STATUS LIKE 'Com_insert';
SHOW STATUS LIKE 'Com_update';
SHOW STATUS LIKE 'Com_delete';

-- Queries lentas acumuladas.
SHOW STATUS LIKE 'Slow_queries';

-- Configuración del slow query log.
SHOW VARIABLES LIKE 'slow_query_log%';
SHOW VARIABLES LIKE 'long_query_time';

-- Tamaño del buffer pool de InnoDB.
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';

-- Páginas del buffer pool.
SHOW STATUS LIKE 'Innodb_buffer_pool_pages_total';
SHOW STATUS LIKE 'Innodb_buffer_pool_pages_free';
SHOW STATUS LIKE 'Innodb_buffer_pool_pages_dirty';

-- Lecturas lógicas y lecturas físicas del buffer pool.
SHOW STATUS LIKE 'Innodb_buffer_pool_read_requests';
SHOW STATUS LIKE 'Innodb_buffer_pool_reads';

-- Hit ratio del buffer pool, que calcula: (read_requests - reads) / read_requests * 100
-- Se controla la división por cero para evitar errores en entornos recién arrancados.
SELECT
    ROUND(
        CASE
            WHEN (
                SELECT CAST(VARIABLE_VALUE AS DECIMAL(20,4))
                FROM performance_schema.global_status
                WHERE VARIABLE_NAME = 'Innodb_buffer_pool_read_requests'
            ) = 0 THEN 0
            ELSE
                (1 - (
                    (SELECT CAST(VARIABLE_VALUE AS DECIMAL(20,4))
                     FROM performance_schema.global_status
                     WHERE VARIABLE_NAME = 'Innodb_buffer_pool_reads')
                    /
                    (SELECT CAST(VARIABLE_VALUE AS DECIMAL(20,4))
                     FROM performance_schema.global_status
                     WHERE VARIABLE_NAME = 'Innodb_buffer_pool_read_requests')
                )) * 100
        END,
        4
    ) AS buffer_pool_hit_ratio_pct;

-- Esperas por locks de fila en InnoDB.
SHOW STATUS LIKE 'Innodb_row_lock_waits';
SHOW STATUS LIKE 'Innodb_row_lock_time_avg';

-- Deadlocks detectados.
SHOW STATUS LIKE 'Innodb_deadlocks';

-- Mide transacciones activas, útil para detectar transacciones largas o bloqueadas.
SELECT
    trx_id,
    trx_state,
    trx_started,
    trx_query
FROM information_schema.INNODB_TRX
ORDER BY trx_started ASC;

-- Mide el tamaño de tablas e índices del esquema basado en information_schema.tables
SELECT
    table_name,
    ROUND(data_length / 1024 / 1024, 2) AS datos_MB,
    ROUND(index_length / 1024 / 1024, 2) AS indices_MB
FROM information_schema.tables
WHERE table_schema = 'ride_hailing'
ORDER BY datos_MB + indices_MB DESC;

-- COMPROBACIÓN DE ÍNDICES CON EXPLAIN

-- Consulta sobre ofertas pendientes ordenadas por fecha de envío. 
EXPLAIN
SELECT
    o.id_oferta,
    o.id_viaje,
    o.id_conductor,
    o.estado_oferta,
    o.fecha_envio
FROM oferta o
WHERE o.estado_oferta = 'pendiente'
ORDER BY o.fecha_envio DESC;

-- Consulta sobre viajes por estado y fecha.
EXPLAIN
SELECT
    v.id_viaje,
    v.estado,
    v.fecha_solicitud
FROM viaje v
WHERE v.estado = 'finalizado'
ORDER BY v.fecha_solicitud DESC;

-- Consulta de ingresos por company que agrupa por company y ordena por ingresos.
EXPLAIN
SELECT
    c.nombre AS company,
    SUM(p.comision_company) AS ingresos_company
FROM pago p
JOIN viaje v
    ON v.id_viaje = p.id_viaje
JOIN conductor cond
    ON cond.id_usuario = v.id_conductor
JOIN company c
    ON c.id_company = cond.id_company
WHERE v.estado = 'finalizado'
  AND p.estado_pago = 'completado'
GROUP BY c.id_company, c.nombre;

-- MÉTRICAS DE AUDITORÍA

-- Muestra las operaciones auditadas por tabla.
SELECT
    tabla_afectada,
    accion,
    COUNT(*) AS total_operaciones
FROM audit_operacion
GROUP BY tabla_afectada, accion
ORDER BY tabla_afectada, accion;

-- Muestra las últimas operaciones auditadas ordenadas por fecha de operación.
SELECT
    id_audit,
    tabla_afectada,
    id_registro,
    accion,
    usuario_mysql,
    fecha_operacion,
    descripcion
FROM audit_operacion
ORDER BY fecha_operacion DESC
LIMIT 20;

-- Muestra los cambios de estado de viaje por tipo de cambio y el total de cambios por cada tipo.
SELECT
    estado_anterior,
    estado_nuevo,
    COUNT(*) AS total_cambios
FROM viaje_estado_log
GROUP BY estado_anterior, estado_nuevo
ORDER BY total_cambios DESC;
