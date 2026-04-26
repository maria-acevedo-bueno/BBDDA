USE ride_hailing;

-- **************************************************************************************************************************************************

-- 1. FLUJO BÁSICO DEL PROGRAMA

-- 1.1. Insertar datos necesarios

-- company nueva

INSERT INTO company (
    nombre,
    cif,
    activo
) VALUES (
    'Company Prueba',
    'T99999999',
    TRUE
);

SET @id_company_prueba = LAST_INSERT_ID();

-- nuevo rider

INSERT INTO usuario (
    nombre,
    apellido1,
    apellido2,
    email,
    telefono,
    activo
) VALUES (
    'Rider',
    'Prueba',
    'Completa',
    'rider.prueba@ridehailing.test',
    '699000001',
    TRUE
);

SET @id_rider_prueba = LAST_INSERT_ID();

INSERT INTO rider (
    id_usuario
) VALUES (
    @id_rider_prueba
);

-- nuevo conductor

INSERT INTO usuario (
    nombre,
    apellido1,
    apellido2,
    email,
    telefono,
    activo
) VALUES (
    'Conductor',
    'Prueba',
    'Completa',
    'conductor.prueba@ridehailing.test',
    '699000002',
    TRUE
);

SET @id_conductor_prueba = LAST_INSERT_ID();

INSERT INTO conductor (
    id_usuario,
    numero_licencia,
    estado_conductor,
    id_company
) VALUES (
    @id_conductor_prueba,
    'LIC-TEST-0001',
    'disponible',
    @id_company_prueba
);

-- nuevo vehículo

INSERT INTO vehiculo (
    id_company,
    matricula,
    marca,
    modelo,
    color,
    capacidad,
    activo
) VALUES (
    @id_company_prueba,
    '9999ZZZ',
    'Toyota',
    'Prius',
    'Blanco',
    4,
    TRUE
);

SET @id_vehiculo_prueba = LAST_INSERT_ID();

INSERT INTO conductor_vehiculo (
    id_conductor,
    id_vehiculo,
    fecha_desde,
    fecha_hasta
) VALUES (
    @id_conductor_prueba,
    @id_vehiculo_prueba,
    CURRENT_TIMESTAMP,
    NULL
);

-- Comprobación de los identificadores generados

SELECT
    @id_company_prueba AS id_company_prueba,
    @id_rider_prueba AS id_rider_prueba,
    @id_conductor_prueba AS id_conductor_prueba,
    @id_vehiculo_prueba AS id_vehiculo_prueba;

-- **************************************************************************************************************************************************

-- 1.2. Comprobaciones previas

-- Comprobamos que el rider existe.

SELECT
    u.id_usuario,
    u.nombre,
    u.apellido1,
    u.email,
    u.activo
FROM usuario u
JOIN rider r
    ON r.id_usuario = u.id_usuario
WHERE u.id_usuario = @id_rider_prueba;

-- Comprobamos que el conductor está disponible.

SELECT
    c.id_usuario AS id_conductor,
    u.nombre,
    u.apellido1,
    c.estado_conductor,
    c.id_company
FROM conductor c
JOIN usuario u
    ON u.id_usuario = c.id_usuario
WHERE c.id_usuario = @id_conductor_prueba;

-- Comprobamos que el vehículo está activo y asignado al conductor.

SELECT
    cv.id_conductor,
    cv.id_vehiculo,
    v.matricula,
    v.marca,
    v.modelo,
    v.activo,
    cv.fecha_desde,
    cv.fecha_hasta
FROM conductor_vehiculo cv
JOIN vehiculo v
    ON v.id_vehiculo = cv.id_vehiculo
WHERE cv.id_conductor = @id_conductor_prueba
  AND cv.id_vehiculo = @id_vehiculo_prueba
  AND cv.fecha_hasta IS NULL;

-- **************************************************************************************************************************************************

-- 1.3. El rider solicita un viaje

-- Se llama al procedimiento sp_solicitar_viaje.
-- Este procedimiento inserta un viaje en estado solicitado y genera ofertas para conductores disponibles con vehículo activo.

CALL sp_solicitar_viaje(
    @id_rider_prueba,
    40.416775,
    -3.703790,
    40.430000,
    -3.690000,
    'Puerta del Sol, Madrid',
    'Nuevos Ministerios, Madrid',
    6.40,
    @id_viaje_prueba,
    @resultado_solicitud
);

-- Comprobamos el resultado del procedimiento.

SELECT
    @id_viaje_prueba AS id_viaje_generado,
    @resultado_solicitud AS resultado_solicitud;

-- Comprobamos las tablas afectadas por este procedimiento.

-- En la tabla viaje, debe haberse creado un viaje nuevo en estado solicitado.

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
FROM viaje
WHERE id_viaje = @id_viaje_prueba;

-- En la tabla oferta, deben haberse creado ofertas pendientes para los conductores disponibles.

SELECT
    id_oferta,
    id_viaje,
    id_conductor,
    fecha_envio,
    fecha_respuesta,
    estado_oferta,
    importe_ofrecido
FROM oferta
WHERE id_viaje = @id_viaje_prueba
ORDER BY id_oferta;

-- En la tabla audit_operacion, el trigger de inserción de viaje debe haber registrado la creación del viaje.

SELECT
    id_audit,
    tabla_afectada,
    id_registro,
    accion,
    usuario_mysql,
    fecha_operacion,
    descripcion
FROM audit_operacion
WHERE tabla_afectada = 'viaje'
  AND id_registro = @id_viaje_prueba
ORDER BY fecha_operacion DESC;

-- **************************************************************************************************************************************************

-- 1.4. El conductor acepta la oferta

-- Antes de aceptar, comprobamos la oferta pendiente del conductor.

SELECT
    id_oferta,
    id_viaje,
    id_conductor,
    estado_oferta,
    importe_ofrecido,
    fecha_envio,
    fecha_respuesta
FROM oferta
WHERE id_viaje = @id_viaje_prueba
  AND id_conductor = @id_conductor_prueba;

-- Se llama al procedimiento sp_aceptar_oferta.
-- Este procedimiento:
-- - bloquea el viaje con SELECT ... FOR UPDATE,
-- - asigna conductor y vehículo al viaje,
-- - marca una oferta como aceptada,
-- - expira el resto de ofertas pendientes,
-- - cambia el conductor a estado en_viaje.

CALL sp_aceptar_oferta(
    @id_viaje_prueba,
    @id_conductor_prueba,
    @id_vehiculo_prueba,
    @resultado_aceptacion
);

-- Comprobamos el resultado del procedimiento.

SELECT
    @id_viaje_prueba AS id_viaje,
    @resultado_aceptacion AS resultado_aceptacion;

-- Comprobamos las tablas aceptadas por el procedimiento

-- En la tabla viaje, el viaje debe pasar de solicitado a aceptado.
-- También deben aparecer id_conductor, id_vehiculo y fecha_aceptacion.

SELECT
    id_viaje,
    id_rider,
    id_conductor,
    id_vehiculo,
    estado,
    fecha_solicitud,
    fecha_aceptacion,
    fecha_inicio,
    fecha_fin
FROM viaje
WHERE id_viaje = @id_viaje_prueba;

-- Tabla oferta:
-- En la tabla oferta, la oferta del conductor debe estar aceptada.
-- El resto de ofertas del viaje deben estar expiradas.

SELECT
    id_oferta,
    id_viaje,
    id_conductor,
    estado_oferta,
    fecha_envio,
    fecha_respuesta,
    importe_ofrecido
FROM oferta
WHERE id_viaje = @id_viaje_prueba
ORDER BY id_oferta;

-- En la tabla conductor, el conductor debe haber pasado a estado en_viaje.

SELECT
    c.id_usuario AS id_conductor,
    u.nombre,
    u.apellido1,
    c.estado_conductor
FROM conductor c
JOIN usuario u
    ON u.id_usuario = c.id_usuario
WHERE c.id_usuario = @id_conductor_prueba;

-- En la tabla viaje_estado_log, el trigger debe haber registrado el cambio de solicitado a aceptado.

SELECT
    id_historial,
    id_viaje,
    estado_anterior,
    estado_nuevo,
    fecha_cambio,
    comentario
FROM viaje_estado_log
WHERE id_viaje = @id_viaje_prueba
ORDER BY fecha_cambio;

-- En la tabla audit_operacion, deben aparecer actualizaciones sobre viaje y oferta.

SELECT
    id_audit,
    tabla_afectada,
    id_registro,
    accion,
    usuario_mysql,
    fecha_operacion,
    descripcion
FROM audit_operacion
WHERE (
        tabla_afectada = 'viaje'
        AND id_registro = @id_viaje_prueba
      )
   OR (
        tabla_afectada = 'oferta'
        AND id_registro IN (
            SELECT id_oferta
            FROM oferta
            WHERE id_viaje = @id_viaje_prueba
        )
      )
ORDER BY fecha_operacion DESC;

-- **************************************************************************************************************************************************

-- 1.5. Iniciar el viaje

-- Antes de iniciar, comprobamos que el viaje está aceptado.

SELECT
    id_viaje,
    estado,
    id_conductor,
    id_vehiculo,
    fecha_aceptacion,
    fecha_inicio
FROM viaje
WHERE id_viaje = @id_viaje_prueba;

-- Se llama al procedimiento sp_iniciar_viaje.
-- Este procedimiento cambia el viaje de aceptado a en_curso.

CALL sp_iniciar_viaje(
    @id_viaje_prueba,
    @resultado_inicio
);

-- Comprobamos el resultado del procedimiento.

SELECT
    @id_viaje_prueba AS id_viaje,
    @resultado_inicio AS resultado_inicio;

-- Comprobamos las tablas afectadas por el procedimiento

-- En la tabla viaje, el viaje debe estar en estado en_curso y tener fecha_inicio.

SELECT
    id_viaje,
    id_rider,
    id_conductor,
    id_vehiculo,
    estado,
    fecha_aceptacion,
    fecha_inicio,
    fecha_fin
FROM viaje
WHERE id_viaje = @id_viaje_prueba;

-- En la tabla conductor, el conductor sigue en estado en_viaje.

SELECT
    c.id_usuario AS id_conductor,
    u.nombre,
    u.apellido1,
    c.estado_conductor
FROM conductor c
JOIN usuario u
    ON u.id_usuario = c.id_usuario
WHERE c.id_usuario = @id_conductor_prueba;

-- En la tabla viaje_estado_log, debe aparecer el cambio de aceptado a en_curso.

SELECT
    id_historial,
    id_viaje,
    estado_anterior,
    estado_nuevo,
    fecha_cambio,
    comentario
FROM viaje_estado_log
WHERE id_viaje = @id_viaje_prueba
ORDER BY fecha_cambio;

-- En la tabla audit_operacion, debe haberse registrado la actualización del viaje.

SELECT
    id_audit,
    tabla_afectada,
    id_registro,
    accion,
    usuario_mysql,
    fecha_operacion,
    descripcion
FROM audit_operacion
WHERE tabla_afectada = 'viaje'
  AND id_registro = @id_viaje_prueba
ORDER BY fecha_operacion DESC;

-- **************************************************************************************************************************************************

-- 1.6. Finalizar el viaje y generar el pago

-- Comprobamos que el viaje está en curso y que existe una oferta aceptada.

SELECT
    id_viaje,
    estado,
    id_conductor,
    id_vehiculo,
    fecha_inicio,
    fecha_fin
FROM viaje
WHERE id_viaje = @id_viaje_prueba;

SELECT
    id_oferta,
    id_viaje,
    id_conductor,
    estado_oferta,
    importe_ofrecido
FROM oferta
WHERE id_viaje = @id_viaje_prueba
  AND estado_oferta = 'aceptada';

-- Se llama al procedimiento sp_finalizar_viaje_y_pagar.
-- Este procedimiento:
-- - cambia el viaje a finalizado,
-- - libera al conductor,
-- - calcula importes,
-- - inserta el pago.

CALL sp_finalizar_viaje_y_pagar(
    @id_viaje_prueba,
    'tarjeta_credito',
    @resultado_finalizacion
);

-- Comprobamos el resultado del procedimiento.

SELECT
    @id_viaje_prueba AS id_viaje,
    @resultado_finalizacion AS resultado_finalizacion;

-- Comprobamos las tablas afectadas por el procedimiento.

-- En la tabla viaje, el viaje debe estar finalizado y tener fecha_fin.

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
    distancia_km
FROM viaje
WHERE id_viaje = @id_viaje_prueba;

-- En la tabla conductor, el conductor debe volver a estado disponible.

SELECT
    c.id_usuario AS id_conductor,
    u.nombre,
    u.apellido1,
    c.estado_conductor
FROM conductor c
JOIN usuario u
    ON u.id_usuario = c.id_usuario
WHERE c.id_usuario = @id_conductor_prueba;

-- En la tabla pago, debe haberse creado un pago asociado al viaje.
-- El importe_total debe ser el importe ofrecido multiplicado por 1.20.
-- La comisión es la diferencia entre importe_total e importe_conductor.

SELECT
    id_pago,
    id_viaje,
    importe_total,
    comision_company,
    importe_conductor,
    metodo_pago,
    estado_pago,
    fecha_pago
FROM pago
WHERE id_viaje = @id_viaje_prueba;

-- En la tabla viaje_estado_log, debe aparecer el cambio de en_curso a finalizado.

SELECT
    id_historial,
    id_viaje,
    estado_anterior,
    estado_nuevo,
    fecha_cambio,
    comentario
FROM viaje_estado_log
WHERE id_viaje = @id_viaje_prueba
ORDER BY fecha_cambio;

-- En la tabla audit_operacion, deben aparecer las operaciones de viaje, oferta y pago relacionadas con este flujo.

SELECT
    id_audit,
    tabla_afectada,
    id_registro,
    accion,
    usuario_mysql,
    fecha_operacion,
    descripcion
FROM audit_operacion
WHERE (
        tabla_afectada = 'viaje'
        AND id_registro = @id_viaje_prueba
      )
   OR (
        tabla_afectada = 'oferta'
        AND id_registro IN (
            SELECT id_oferta
            FROM oferta
            WHERE id_viaje = @id_viaje_prueba
        )
      )
   OR (
        tabla_afectada = 'pago'
        AND id_registro IN (
            SELECT id_pago
            FROM pago
            WHERE id_viaje = @id_viaje_prueba
        )
      )
ORDER BY fecha_operacion DESC;

-- **************************************************************************************************************************************************

-- 2. CASOS DE CONTROL DE ERRORES

-- 2.1. Errores posibles en sp_solicitar_viaje

-- CASO 1: Solicitar un viaje con un rider que no existe.

CALL sp_solicitar_viaje(
    999999,
    40.416775,
    -3.703790,
    40.430000,
    -3.690000,
    'Puerta del Sol, Madrid',
    'Nuevos Ministerios, Madrid',
    6.40,
    @id_viaje_error_rider,
    @resultado_error_rider
);

SELECT
    @id_viaje_error_rider AS id_viaje,
    @resultado_error_rider AS resultado;

-- CASO 2: Solicitar un viaje con una latitud fuera del rango permitido.

CALL sp_solicitar_viaje(
    @id_rider_prueba,
    999.000000,
    -3.703790,
    40.430000,
    -3.690000,
    'Origen no valido',
    'Destino valido',
    6.40,
    @id_viaje_error_latitud,
    @resultado_error_latitud
);

SELECT
    @id_viaje_error_latitud AS id_viaje,
    @resultado_error_latitud AS resultado;

-- **************************************************************************************************************************************************

-- 2.2. Errores posibles en sp_aceptar_oferta

-- CASO 1: Intentar aceptar un viaje que no existe.

CALL sp_aceptar_oferta(
    999999,
    @id_conductor_prueba,
    @id_vehiculo_prueba,
    @resultado_error_viaje_no_existe
);

SELECT
    @resultado_error_viaje_no_existe AS resultado;

-- CASO 2: Intentar aceptar un viaje que no está en estado solicitado.

CALL sp_aceptar_oferta(
    @id_viaje_prueba,
    @id_conductor_prueba,
    @id_vehiculo_prueba,
    @resultado_error_estado_aceptar
);

SELECT
    @id_viaje_prueba AS id_viaje,
    @resultado_error_estado_aceptar AS resultado;

-- **************************************************************************************************************************************************

-- 2.3. Errores posibles en sp_iniciar_viaje

-- CASO 1: Intentar iniciar un viaje que no existe.

CALL sp_iniciar_viaje(
    999999,
    @resultado_error_inicio_no_existe
);

SELECT
    @resultado_error_inicio_no_existe AS resultado;


-- CASO 2: Intentar iniciar un viaje que no está aceptado.

CALL sp_iniciar_viaje(
    @id_viaje_prueba,
    @resultado_error_inicio_estado
);

SELECT
    @id_viaje_prueba AS id_viaje,
    @resultado_error_inicio_estado AS resultado;

-- **************************************************************************************************************************************************

-- 2.4. Errores posibles en sp_finalizar_viaje_y_pagar

-- CASO 1: Intentar finalizar un viaje que no existe.

CALL sp_finalizar_viaje_y_pagar(
    999999,
    'tarjeta_credito',
    @resultado_error_fin_no_existe
);

SELECT
    @resultado_error_fin_no_existe AS resultado;


-- CASO 2: Intentar finalizar un viaje con un método de pago no permitido.

CALL sp_finalizar_viaje_y_pagar(
    11,
    'paypal',
    @resultado_error_metodo_pago
);

SELECT
    11 AS id_viaje,
    @resultado_error_metodo_pago AS resultado;

-- **************************************************************************************************************************************************

-- 3. CONSULTAS INTERESANTES CON JOIN

-- 3.1 Vehículos asignados actualmente a cada conductor.
SELECT
    c.id_usuario AS id_conductor,
    CONCAT(u.nombre, ' ', u.apellido1) AS conductor,
    co.nombre AS company,
    v.id_vehiculo,
    v.matricula,
    v.marca,
    v.modelo,
    v.color,
    cv.fecha_desde,
    c.estado_conductor,
    v.activo AS vehiculo_activo
FROM conductor_vehiculo cv
JOIN conductor c
    ON c.id_usuario = cv.id_conductor
JOIN usuario u
    ON u.id_usuario = c.id_usuario
JOIN vehiculo v
    ON v.id_vehiculo = cv.id_vehiculo
JOIN company co
    ON co.id_company = c.id_company
WHERE cv.fecha_hasta IS NULL
ORDER BY
    co.nombre,
    conductor;


-- 3.2. Viajes pendientes de aceptación con sus ofertas pendientes.
SELECT
    v.id_viaje,
    v.estado AS estado_viaje,
    v.fecha_solicitud,
    v.origen_direccion,
    v.destino_direccion,
    v.distancia_km,
    o.id_oferta,
    o.estado_oferta,
    o.importe_ofrecido,
    CONCAT(u.nombre, ' ', u.apellido1) AS conductor_ofertado,
    co.nombre AS company
FROM viaje v
JOIN oferta o
    ON o.id_viaje = v.id_viaje
JOIN conductor c
    ON c.id_usuario = o.id_conductor
JOIN usuario u
    ON u.id_usuario = c.id_usuario
JOIN company co
    ON co.id_company = c.id_company
WHERE v.estado = 'solicitado'
  AND o.estado_oferta = 'pendiente'
ORDER BY
    v.fecha_solicitud,
    o.fecha_envio;

-- 3.3. Valoraciones recibidas por conductores con información del viaje.
SELECT
    val.id_valoracion,
    val.id_viaje,
    CONCAT(u_cond.nombre, ' ', u_cond.apellido1) AS conductor_valorado,
    co.nombre AS company,
    val.puntuacion,
    val.comentario,
    val.fecha_valoracion,
    v.origen_direccion,
    v.destino_direccion,
    v.distancia_km
FROM valoracion val
JOIN usuario u_cond
    ON u_cond.id_usuario = val.id_usuario_valorado
JOIN conductor c
    ON c.id_usuario = val.id_usuario_valorado
JOIN company co
    ON co.id_company = c.id_company
JOIN viaje v
    ON v.id_viaje = val.id_viaje
WHERE val.rol_valorado = 'conductor'
ORDER BY
    val.puntuacion DESC,
    val.fecha_valoracion DESC;


-- 3.4. Resumen de ingresos por viaje finalizado.
SELECT
    v.id_viaje,
    CONCAT(u.nombre, ' ', u.apellido1) AS conductor,
    co.nombre AS company,
    v.distancia_km,
    TIMESTAMPDIFF(MINUTE, v.fecha_inicio, v.fecha_fin) AS duracion_minutos,
    p.importe_total,
    p.comision_company,
    p.importe_conductor,
    ROUND(p.importe_total / NULLIF(v.distancia_km, 0), 2) AS euros_por_km,
    ROUND(
        p.importe_total / NULLIF(TIMESTAMPDIFF(MINUTE, v.fecha_inicio, v.fecha_fin), 0),
        2
    ) AS euros_por_minuto
FROM viaje v
JOIN pago p
    ON p.id_viaje = v.id_viaje
JOIN conductor c
    ON c.id_usuario = v.id_conductor
JOIN usuario u
    ON u.id_usuario = c.id_usuario
JOIN company co
    ON co.id_company = c.id_company
WHERE v.estado = 'finalizado'
  AND p.estado_pago = 'completado'
ORDER BY
    p.fecha_pago DESC;

-- **************************************************************************************************************************************************

-- 4. UPDATES INTERESANTES

-- 4.1. Suspender temporalmente a un conductor.
SELECT
    c.id_usuario,
    CONCAT(u.nombre, ' ', u.apellido1) AS conductor,
    c.estado_conductor
FROM conductor c
JOIN usuario u
    ON u.id_usuario = c.id_usuario
WHERE c.id_usuario = 30;

UPDATE conductor
SET estado_conductor = 'suspendido'
WHERE id_usuario = 30;

SELECT
    c.id_usuario,
    CONCAT(u.nombre, ' ', u.apellido1) AS conductor,
    c.estado_conductor
FROM conductor c
JOIN usuario u
    ON u.id_usuario = c.id_usuario
WHERE c.id_usuario = 30;

-- 4.2. Actualizar el teléfono de un usuario.
SELECT
    id_usuario,
    nombre,
    apellido1,
    telefono,
    fecha_modificacion
FROM usuario
WHERE id_usuario = 1;

UPDATE usuario
SET telefono = '699999001'
WHERE id_usuario = 1;

SELECT
    id_usuario,
    nombre,
    apellido1,
    telefono,
    fecha_modificacion
FROM usuario
WHERE id_usuario = 1;

-- 4.3. Desactivar un vehículo.
-- Puede usarse cuando un vehículo deja de estar operativo.
SELECT
    id_vehiculo,
    matricula,
    marca,
    modelo,
    activo
FROM vehiculo
WHERE id_vehiculo = 20;

UPDATE vehiculo
SET activo = FALSE
WHERE id_vehiculo = 20;

SELECT
    id_vehiculo,
    matricula,
    marca,
    modelo,
    activo
FROM vehiculo
WHERE id_vehiculo = 20;

-- 4.4. Cerrar una asignación vigente entre conductor y vehículo.
SELECT
    id_conductor,
    id_vehiculo,
    fecha_desde,
    fecha_hasta
FROM conductor_vehiculo
WHERE id_conductor = 20
  AND id_vehiculo = 18;

UPDATE conductor_vehiculo
SET fecha_hasta = CURRENT_TIMESTAMP
WHERE id_conductor = 20
  AND id_vehiculo = 18
  AND fecha_hasta IS NULL;

SELECT
    id_conductor,
    id_vehiculo,
    fecha_desde,
    fecha_hasta
FROM conductor_vehiculo
WHERE id_conductor = 20
  AND id_vehiculo = 18;

-- **************************************************************************************************************************************************

-- 5. DELETES INTERESANTES

-- 5.1. Intento de borrado de un usuario con dependencias.

SELECT
    u.id_usuario,
    u.nombre,
    u.apellido1,
    r.id_usuario AS existe_como_rider
FROM usuario u
JOIN rider r
    ON r.id_usuario = u.id_usuario
WHERE u.id_usuario = 1;

DELETE FROM usuario
    WHERE id_usuario = 1;

-- 5.2. Crear un usuario de prueba que no será rider ni conductor.
-- Al no tener relaciones con otras tablas, se puede borrar directamente.
INSERT INTO usuario (
    nombre,
    apellido1,
    apellido2,
    email,
    telefono,
    activo
) VALUES (
    'Usuario',
    'Temporal',
    'Delete',
    'usuario.temporal.delete@ridehailing.test',
    '699990001',
    TRUE
);

SELECT
    id_usuario,
    nombre,
    apellido1,
    email,
    telefono,
    activo
FROM usuario
WHERE email = 'usuario.temporal.delete@ridehailing.test';

DELETE FROM usuario
WHERE email = 'usuario.temporal.delete@ridehailing.test';

SELECT
    id_usuario,
    nombre,
    apellido1,
    email,
    telefono,
    activo
FROM usuario
WHERE email = 'usuario.temporal.delete@ridehailing.test';

-- **************************************************************************************************************************************************