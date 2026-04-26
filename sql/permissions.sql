USE ride_hailing;

-- VISTAS PARA ROL_APP

-- El rol de aplicación puede consultar datos operativos del sistema:
-- conductores disponibles, viajes, ofertas y pagos básicos.
-- Las operaciones críticas se realizan mediante procedimientos almacenados, algo que estos usuarios pueden ejecutar.

CREATE VIEW v_app_conductores_disponibles AS
SELECT
    c.id_usuario AS id_conductor,
    c.id_company,
    co.nombre AS company,
    u.nombre,
    u.apellido1,
    c.estado_conductor
FROM conductor c
JOIN usuario u
    ON u.id_usuario = c.id_usuario
JOIN company co
    ON co.id_company = c.id_company
WHERE u.activo = TRUE
  AND c.estado_conductor = 'disponible';

CREATE VIEW v_app_viajes_operativos AS
SELECT
    id_viaje,
    id_rider,
    id_conductor,
    id_vehiculo,
    estado,
    fecha_solicitud,
    fecha_aceptacion,
    fecha_inicio,
    fecha_fin,
    origen_direccion,
    destino_direccion,
    distancia_km
FROM viaje;

CREATE VIEW v_app_ofertas_operativas AS
SELECT
    id_oferta,
    id_viaje,
    id_conductor,
    fecha_envio,
    fecha_respuesta,
    estado_oferta,
    importe_ofrecido
FROM oferta;

CREATE VIEW v_app_pagos_operativos AS
SELECT
    id_pago,
    id_viaje,
    importe_total,
    metodo_pago,
    estado_pago,
    fecha_pago
FROM pago;

-- VISTAS PARA ROL_ANALISTA

-- Los analistas pueden ver los usuarios del sistema sin datos personales privados, 
-- información en detalle sobre los viajes (duraciones, distancias...),
-- detalles sobre las ofertas, sobre los pagos, las valoraciones para analizar la calidad tanto de conductores como de riders,
-- historial del estado de los viajes para ver si hay algún problema con los mismos y la tabla de auditoría de operaciones.

-- Se dedican a analizar métricas para detectar problemas a nivel de aplicación y usuario/trabajador.

CREATE VIEW v_analyst_usuarios_anonimizados AS
SELECT
    id_usuario,
    nombre,
    apellido1,
    apellido2,
    fecha_alta,
    activo
FROM usuario;

CREATE VIEW v_analyst_viajes_detalle AS
SELECT
    v.id_viaje,
    v.id_rider,
    v.id_conductor,
    u_cond.nombre AS conductor_nombre,
    c.id_company,
    co.nombre AS company,
    v.id_vehiculo,
    v.estado,
    v.fecha_solicitud,
    v.fecha_aceptacion,
    v.fecha_inicio,
    v.fecha_fin,
    v.origen_direccion,
    v.destino_direccion,
    v.distancia_km,
    TIMESTAMPDIFF(MINUTE, v.fecha_inicio, v.fecha_fin) AS duracion_minutos
FROM viaje v
LEFT JOIN conductor c
    ON c.id_usuario = v.id_conductor
LEFT JOIN usuario u_cond
    ON u_cond.id_usuario = v.id_conductor
LEFT JOIN company co
    ON co.id_company = c.id_company;

CREATE VIEW v_analyst_ofertas_detalle AS
SELECT
    o.id_oferta,
    o.id_viaje,
    o.id_conductor,
    u.nombre AS conductor_nombre,
    c.id_company,
    co.nombre AS company,
    o.fecha_envio,
    o.fecha_respuesta,
    o.estado_oferta,
    o.importe_ofrecido
FROM oferta o
JOIN conductor c
    ON c.id_usuario = o.id_conductor
JOIN usuario u
    ON u.id_usuario = o.id_conductor
JOIN company co
    ON co.id_company = c.id_company;

CREATE VIEW v_analyst_tasa_aceptacion_conductor AS
SELECT
    o.id_conductor,
    u.nombre AS conductor_nombre,
    COUNT(o.id_oferta) AS total_ofertas,
    SUM(CASE WHEN o.estado_oferta = 'aceptada' THEN 1 ELSE 0 END) AS ofertas_aceptadas,
    ROUND(
        SUM(CASE WHEN o.estado_oferta = 'aceptada' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(o.id_oferta), 0),
        2
    ) AS tasa_aceptacion_pct
FROM oferta o
JOIN usuario u
    ON u.id_usuario = o.id_conductor
GROUP BY
    o.id_conductor,
    u.nombre;

CREATE VIEW v_analyst_tasa_aceptacion_company AS
SELECT
    c.id_company,
    co.nombre AS company,
    COUNT(o.id_oferta) AS total_ofertas,
    SUM(CASE WHEN o.estado_oferta = 'aceptada' THEN 1 ELSE 0 END) AS ofertas_aceptadas,
    ROUND(
        SUM(CASE WHEN o.estado_oferta = 'aceptada' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(o.id_oferta), 0),
        2
    ) AS tasa_aceptacion_pct
FROM oferta o
JOIN conductor c
    ON c.id_usuario = o.id_conductor
JOIN company co
    ON co.id_company = c.id_company
GROUP BY
    c.id_company,
    co.nombre;

CREATE VIEW v_analyst_ingresos_conductor AS
SELECT
    v.id_conductor,
    u.nombre AS conductor_nombre,
    COUNT(p.id_pago) AS total_pagos,
    SUM(p.importe_total) AS ingresos_totales,
    SUM(p.importe_conductor) AS ingresos_conductor,
    SUM(v.distancia_km) AS km_totales,
    ROUND(
        SUM(p.importe_total) / NULLIF(SUM(v.distancia_km), 0),
        2
    ) AS euros_por_km
FROM pago p
JOIN viaje v
    ON v.id_viaje = p.id_viaje
JOIN usuario u
    ON u.id_usuario = v.id_conductor
WHERE p.estado_pago = 'pagado'
GROUP BY
    v.id_conductor,
    u.nombre;

CREATE VIEW v_analyst_ingresos_company AS
SELECT
    c.id_company,
    co.nombre AS company,
    COUNT(p.id_pago) AS total_pagos,
    SUM(p.importe_total) AS ingresos_totales,
    SUM(p.comision_company) AS ingresos_company,
    SUM(v.distancia_km) AS km_totales,
    ROUND(
        SUM(p.importe_total) / NULLIF(SUM(v.distancia_km), 0),
        2
    ) AS euros_por_km
FROM pago p
JOIN viaje v
    ON v.id_viaje = p.id_viaje
JOIN conductor c
    ON c.id_usuario = v.id_conductor
JOIN company co
    ON co.id_company = c.id_company
WHERE p.estado_pago = 'pagado'
GROUP BY
    c.id_company,
    co.nombre;

CREATE VIEW v_analyst_pagos_detalle AS
SELECT
    p.id_pago,
    p.id_viaje,
    v.id_conductor,
    u.nombre AS conductor_nombre,
    c.id_company,
    co.nombre AS company,
    p.importe_total,
    p.comision_company,
    p.importe_conductor,
    p.metodo_pago,
    p.estado_pago,
    p.fecha_pago,
    v.distancia_km,
    TIMESTAMPDIFF(MINUTE, v.fecha_inicio, v.fecha_fin) AS duracion_minutos
FROM pago p
JOIN viaje v
    ON v.id_viaje = p.id_viaje
LEFT JOIN conductor c
    ON c.id_usuario = v.id_conductor
LEFT JOIN usuario u
    ON u.id_usuario = v.id_conductor
LEFT JOIN company co
    ON co.id_company = c.id_company;

CREATE VIEW v_analyst_valoraciones AS
SELECT
    val.id_valoracion,
    val.id_viaje,
    val.id_usuario_valorado,
    u.nombre AS usuario_valorado_nombre,
    val.rol_valorado,
    val.puntuacion,
    val.fecha_valoracion
FROM valoracion val
JOIN usuario u
    ON u.id_usuario = val.id_usuario_valorado;

CREATE VIEW v_analyst_viaje_estado_log AS
SELECT
    id_historial,
    id_viaje,
    estado_anterior,
    estado_nuevo,
    fecha_cambio,
    comentario
FROM viaje_estado_log;

CREATE VIEW v_analyst_auditoria_operaciones AS
SELECT
    id_audit,
    tabla_afectada,
    id_registro,
    accion,
    usuario_mysql,
    fecha_operacion,
    descripcion
FROM audit_operacion;

-- VISTAS PARA ROL_READONLY

-- Las vistas de este rol están pensadas para consultas básicas, ver las companies activas, conductores sin datos privados, 
-- vehículos sin datos privados, viajes sin datos económicos detallados y un resúmen de estados de viajes. 

CREATE VIEW v_readonly_companies AS
SELECT
    id_company,
    nombre,
    activo
FROM company;

CREATE VIEW v_readonly_conductores AS
SELECT
    c.id_usuario AS id_conductor,
    u.nombre,
    u.apellido1,
    co.nombre AS company,
    c.estado_conductor
FROM conductor c
JOIN usuario u
    ON u.id_usuario = c.id_usuario
JOIN company co
    ON co.id_company = c.id_company;

CREATE VIEW v_readonly_vehiculos AS
SELECT
    v.id_vehiculo,
    co.nombre AS company,
    v.marca,
    v.modelo,
    v.color,
    v.capacidad,
    v.activo
FROM vehiculo v
JOIN company co
    ON co.id_company = v.id_company;

CREATE VIEW v_readonly_viajes_resumen AS
SELECT
    id_viaje,
    estado,
    fecha_solicitud,
    fecha_inicio,
    fecha_fin,
    origen_direccion,
    destino_direccion,
    distancia_km
FROM viaje;

CREATE VIEW v_readonly_viajes_por_estado AS
SELECT
    estado,
    COUNT(*) AS total_viajes
FROM viaje
GROUP BY estado;

-- DEFINICION DE ROLES

CREATE ROLE IF NOT EXISTS 'rol_admin';
CREATE ROLE IF NOT EXISTS 'rol_app';
CREATE ROLE IF NOT EXISTS 'rol_analista';
CREATE ROLE IF NOT EXISTS 'rol_backup';
CREATE ROLE IF NOT EXISTS 'rol_readonly';

-- ASIGNACION DE PRIVILEGIOS

-- El administrador tiene control total sobre toda la base de datos.
GRANT ALL PRIVILEGES ON ride_hailing.* TO 'rol_admin';

-- El rol de aplicación puede leer sus vistas, insertar valoraciones y ejecutar los procedimientos almacenados.

GRANT SELECT ON ride_hailing.v_app_conductores_disponibles TO 'rol_app';
GRANT SELECT ON ride_hailing.v_app_viajes_operativos TO 'rol_app';
GRANT SELECT ON ride_hailing.v_app_ofertas_operativas TO 'rol_app';
GRANT SELECT ON ride_hailing.v_app_pagos_operativos TO 'rol_app';

GRANT INSERT ON ride_hailing.valoracion TO 'rol_app';

GRANT EXECUTE ON PROCEDURE ride_hailing.sp_solicitar_viaje TO 'rol_app';
GRANT EXECUTE ON PROCEDURE ride_hailing.sp_aceptar_oferta TO 'rol_app';
GRANT EXECUTE ON PROCEDURE ride_hailing.sp_iniciar_viaje TO 'rol_app';
GRANT EXECUTE ON PROCEDURE ride_hailing.sp_finalizar_viaje_y_pagar TO 'rol_app';

-- El rol de analista tiene acceso a métricas y auditoría pero no a datos privados como emails o teléfonos.
GRANT SELECT ON ride_hailing.v_analyst_usuarios_anonimizados TO 'rol_analista';
GRANT SELECT ON ride_hailing.v_analyst_viajes_detalle TO 'rol_analista';
GRANT SELECT ON ride_hailing.v_analyst_ofertas_detalle TO 'rol_analista';
GRANT SELECT ON ride_hailing.v_analyst_pagos_detalle TO 'rol_analista';
GRANT SELECT ON ride_hailing.v_analyst_valoraciones TO 'rol_analista';
GRANT SELECT ON ride_hailing.v_analyst_viaje_estado_log TO 'rol_analista';
GRANT SELECT ON ride_hailing.v_analyst_auditoria_operaciones TO 'rol_analista';
GRANT SELECT ON ride_hailing.v_analyst_tasa_aceptacion_conductor TO 'rol_analista';
GRANT SELECT ON ride_hailing.v_analyst_tasa_aceptacion_company TO 'rol_analista';
GRANT SELECT ON ride_hailing.v_analyst_ingresos_conductor TO 'rol_analista';
GRANT SELECT ON ride_hailing.v_analyst_ingresos_company TO 'rol_analista';

-- El rol de solo lectura tiene acceso limitado a información pública.
GRANT SELECT ON ride_hailing.v_readonly_companies TO 'rol_readonly';
GRANT SELECT ON ride_hailing.v_readonly_conductores TO 'rol_readonly';
GRANT SELECT ON ride_hailing.v_readonly_vehiculos TO 'rol_readonly';
GRANT SELECT ON ride_hailing.v_readonly_viajes_resumen TO 'rol_readonly';
GRANT SELECT ON ride_hailing.v_readonly_viajes_por_estado TO 'rol_readonly';

-- El rol de backup tiene permisos para exportar datos ya que los necesita para realizar copias de seguridad
GRANT SELECT, SHOW VIEW, TRIGGER, EVENT, LOCK TABLES
ON ride_hailing.* TO 'rol_backup';

GRANT RELOAD, PROCESS, REPLICATION CLIENT
ON *.* TO 'rol_backup';

-- GESTION DE USUARIOS

CREATE USER IF NOT EXISTS 'admin_user'@'%' IDENTIFIED BY 'Admin1234';
GRANT 'rol_admin' TO 'admin_user'@'%';
SET DEFAULT ROLE 'rol_admin' TO 'admin_user'@'%';

CREATE USER IF NOT EXISTS 'backend_user'@'%' IDENTIFIED BY 'App1234';
GRANT 'rol_app' TO 'backend_user'@'%';
SET DEFAULT ROLE 'rol_app' TO 'backend_user'@'%';

CREATE USER IF NOT EXISTS 'analyst_user'@'%' IDENTIFIED BY 'Analyst1234';
GRANT 'rol_analista' TO 'analyst_user'@'%';
SET DEFAULT ROLE 'rol_analista' TO 'analyst_user'@'%';

CREATE USER IF NOT EXISTS 'readonly_user'@'%' IDENTIFIED BY 'Readonly1234';
GRANT 'rol_readonly' TO 'readonly_user'@'%';
SET DEFAULT ROLE 'rol_readonly' TO 'readonly_user'@'%';

CREATE USER IF NOT EXISTS 'backup_user'@'%' IDENTIFIED BY 'Backup1234';
GRANT 'rol_backup' TO 'backup_user'@'%';
SET DEFAULT ROLE 'rol_backup' TO 'backup_user'@'%';

-- COMPROBACIONES

SHOW GRANTS FOR 'admin_user'@'%';
SHOW GRANTS FOR 'backend_user'@'%';
SHOW GRANTS FOR 'analyst_user'@'%';
SHOW GRANTS FOR 'readonly_user'@'%';
SHOW GRANTS FOR 'backup_user'@'%';

SHOW GRANTS FOR 'rol_admin';
SHOW GRANTS FOR 'rol_app';
SHOW GRANTS FOR 'rol_analista';
SHOW GRANTS FOR 'rol_readonly';
SHOW GRANTS FOR 'rol_backup';

FLUSH PRIVILEGES;