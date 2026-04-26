-- CREACIÓN DE LA BASE DE DATOS

-- Primero, se elimina la base de datos previa, esto nos permite reconstruir rápidamente la base de datos en caso de error en las pruebas.
DROP DATABASE IF EXISTS ride_hailing;

-- Se crea la base de datos.
-- utf8mb4 nos permite almacenar caracteres internacionales y emojis.
-- utf8mb4_0900_ai_ci es la collation recomendada para MySQL 8.
CREATE DATABASE ride_hailing CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- A partir de aquí, los comandos se escriben sobre la base de datos por lo que entramos en ella.
USE ride_hailing;

-- TABLAS

-- La tabla company almacena las empresas que operan en la plataforma.
-- Cada conductor y cada vehículo pertenecen a una company.
CREATE TABLE IF NOT EXISTS company (
    id_company BIGINT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    cif VARCHAR(9) NOT NULL,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    activo BOOLEAN DEFAULT TRUE NOT NULL,
    PRIMARY KEY (id_company),
    CONSTRAINT uk_company_cif UNIQUE (cif)
) ENGINE = InnoDB;

-- La tabla usuario almacena la información de cualquier persona registrada en el sistema.
-- A partir de esta tabla se especializan riders y conductores.
CREATE TABLE IF NOT EXISTS usuario (
    id_usuario BIGINT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL,
    apellido1 VARCHAR(50) NOT NULL,
    apellido2 VARCHAR(50),
    email VARCHAR(150) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    activo BOOLEAN DEFAULT TRUE NOT NULL,
    PRIMARY KEY (id_usuario),
    CONSTRAINT uk_usuario_email UNIQUE (email),
    CONSTRAINT uk_usuario_telefono UNIQUE (telefono)
) ENGINE = InnoDB;

-- La tabla rider especializa a un usuario como cliente.
-- Su clave primaria es también clave foránea a usuario, haciendo que un rider no pueda existir sin su usuario base.
CREATE TABLE IF NOT EXISTS rider (
    id_usuario BIGINT NOT NULL,
    PRIMARY KEY (id_usuario),
    CONSTRAINT fk_rider_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- La tabla conductor especializa a un usuario como conductor.
-- Se crea un índice sobre id_company y estado_conductor para búsquedas más rápidas.
CREATE TABLE IF NOT EXISTS conductor (
    id_usuario BIGINT NOT NULL,
    numero_licencia VARCHAR(50) NOT NULL,
    estado_conductor ENUM(
        'disponible',
        'en_viaje',
        'desconectado',
        'suspendido'
    ) DEFAULT 'desconectado' NOT NULL,
    fecha_alta_conductor DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_modificacion_conductor DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    id_company BIGINT NOT NULL,
    PRIMARY KEY (id_usuario),
    CONSTRAINT uk_conductor_licencia UNIQUE (numero_licencia),
    CONSTRAINT fk_conductor_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_conductor_company FOREIGN KEY (id_company) REFERENCES company (id_company) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_conductor_company (id_company),
    INDEX idx_conductor_estado (estado_conductor)
) ENGINE = InnoDB;

-- La tabla vehiculo almacena los vehículos gestionados por cada company.
-- Un vehículo puede ser asignado a diferentes conductores a lo largo del tiempo.
CREATE TABLE IF NOT EXISTS vehiculo (
    id_vehiculo BIGINT NOT NULL AUTO_INCREMENT,
    id_company BIGINT NOT NULL,
    matricula VARCHAR(20) NOT NULL,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    color VARCHAR(30) NOT NULL,
    capacidad INT DEFAULT 4 NOT NULL,
    activo BOOLEAN DEFAULT TRUE NOT NULL,
    PRIMARY KEY (id_vehiculo),
    CONSTRAINT uk_vehiculo_matricula UNIQUE (matricula),
    CONSTRAINT fk_vehiculo_company FOREIGN KEY (id_company) REFERENCES company (id_company) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_vehiculo_capacidad CHECK (capacidad > 0),
    INDEX idx_vehiculo_company (id_company)
) ENGINE = InnoDB;

-- Tabla conductor_vehiculo es el enlace N:N entre conductores y vehículos.
-- Permite registrar asignaciones históricas y saber cuál está vigente.
-- Los índices con fecha_hasta ayudan a localizar asignaciones vigentes actualmente.
CREATE TABLE IF NOT EXISTS conductor_vehiculo (
    id_conductor BIGINT NOT NULL,
    id_vehiculo BIGINT NOT NULL,
    fecha_desde DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_hasta DATETIME NULL, -- Si fecha_hasta es NULL, la asignación sigue activa.
    PRIMARY KEY (
        id_conductor,
        id_vehiculo,
        fecha_desde
    ),
    CONSTRAINT fk_cv_conductor FOREIGN KEY (id_conductor) REFERENCES conductor (id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_cv_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES vehiculo (id_vehiculo) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_cv_conductor_vigente (id_conductor, fecha_hasta),
    INDEX idx_cv_vehiculo_vigente (id_vehiculo, fecha_hasta)
) ENGINE = InnoDB;

-- La tabla viaje representa el ciclo de vida completo de un trayecto.
-- id_conductor e id_vehiculo se permiten NULL al inicio porque un viaje puede existir antes de que alguien lo acepte.
-- Los índices responden a las consultas más probables del sistema, búsquedas por estado, conductor y rider.
CREATE TABLE IF NOT EXISTS viaje (
    id_viaje BIGINT NOT NULL AUTO_INCREMENT,
    id_rider BIGINT NOT NULL,
    id_conductor BIGINT NULL,
    id_vehiculo BIGINT NULL,
    estado ENUM(
        'solicitado',
        'aceptado',
        'en_curso',
        'finalizado',
        'cancelado'
    ) DEFAULT 'solicitado' NOT NULL,
    fecha_solicitud DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_aceptacion DATETIME NULL,
    fecha_inicio DATETIME NULL,
    fecha_fin DATETIME NULL,
    latitud_origen DECIMAL(9, 6) NOT NULL,
    longitud_origen DECIMAL(9, 6) NOT NULL,
    latitud_destino DECIMAL(9, 6) NOT NULL,
    longitud_destino DECIMAL(9, 6) NOT NULL,
    origen_direccion VARCHAR(255) NOT NULL,
    destino_direccion VARCHAR(255) NOT NULL,
    distancia_km DECIMAL(10, 2) NULL,
    cancelado_por ENUM(
        'rider',
        'conductor',
        'sistema'
    ) NULL,
    motivo_cancelacion VARCHAR(255) NULL,
    PRIMARY KEY (id_viaje),
    CONSTRAINT fk_viaje_rider FOREIGN KEY (id_rider) REFERENCES rider (id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_viaje_conductor FOREIGN KEY (id_conductor) REFERENCES conductor (id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_viaje_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES vehiculo (id_vehiculo) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_viaje_lat_origen CHECK (
        latitud_origen BETWEEN -90 AND 90
    ),
    CONSTRAINT ck_viaje_lng_origen CHECK (
        longitud_origen BETWEEN -180 AND 180
    ),
    CONSTRAINT ck_viaje_lat_destino CHECK (
        latitud_destino BETWEEN -90 AND 90
    ),
    CONSTRAINT ck_viaje_lng_destino CHECK (
        longitud_destino BETWEEN -180 AND 180
    ),
    CONSTRAINT ck_viaje_distancia CHECK (
        distancia_km IS NULL
        OR distancia_km >= 0
    ),
    INDEX idx_viaje_estado_fecha (estado, fecha_solicitud),
    INDEX idx_viaje_conductor_fecha (id_conductor, fecha_solicitud),
    INDEX idx_viaje_rider_fecha (id_rider, fecha_solicitud)
) ENGINE = InnoDB;

-- La tabla oferta registra las ofertas enviadas a los conductores para un viaje.
-- Para un mismo viaje se pueden generar varias ofertas, pero solo una termina aceptada.
-- La restricción UNIQUE evita que el mismo conductor reciba dos veces una oferta para el mismo viaje.
CREATE TABLE IF NOT EXISTS oferta (
    id_oferta BIGINT NOT NULL AUTO_INCREMENT,
    id_viaje BIGINT NOT NULL,
    id_conductor BIGINT NOT NULL,
    fecha_envio DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_respuesta DATETIME NULL,
    estado_oferta ENUM(
        'pendiente',
        'aceptada',
        'rechazada',
        'expirada'
    ) DEFAULT 'pendiente' NOT NULL,
    importe_ofrecido DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (id_oferta),
    CONSTRAINT uk_oferta_viaje_conductor UNIQUE (id_viaje, id_conductor),
    CONSTRAINT fk_oferta_viaje FOREIGN KEY (id_viaje) REFERENCES viaje (id_viaje) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_oferta_conductor FOREIGN KEY (id_conductor) REFERENCES conductor (id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_oferta_importe CHECK (importe_ofrecido >= 0),
    INDEX idx_oferta_estado (estado_oferta),
    INDEX idx_oferta_viaje_conductor_estado (
        id_viaje,
        id_conductor,
        estado_oferta
    ),
    INDEX idx_oferta_viaje_estado (id_viaje, estado_oferta),
    INDEX idx_oferta_conductor_estado (id_conductor, estado_oferta),
    INDEX idx_oferta_fecha_envio (fecha_envio)
) ENGINE = InnoDB;

-- La tabla pago guarda la información económica de un viaje.
-- Cada viaje puede tener como máximo un pago asociado.
-- El CHECK garantiza consistencia contable, se usa ABS para evitar problemas de redondeo.
CREATE TABLE IF NOT EXISTS pago (
    id_pago BIGINT NOT NULL AUTO_INCREMENT,
    id_viaje BIGINT NOT NULL,
    importe_total DECIMAL(10, 2) NOT NULL,
    comision_company DECIMAL(10, 2) NOT NULL,
    importe_conductor DECIMAL(10, 2) NOT NULL,
    metodo_pago ENUM(
        'tarjeta_credito',
        'efectivo',
        'wallet'
    ) DEFAULT 'tarjeta_credito' NOT NULL,
    estado_pago ENUM(
        'pendiente',
        'completado',
        'fallido',
        'reembolsado'
    ) DEFAULT 'pendiente' NOT NULL,
    fecha_pago DATETIME NOT NULL,
    PRIMARY KEY (id_pago),
    CONSTRAINT uk_pago_viaje UNIQUE (id_viaje),
    CONSTRAINT fk_pago_viaje FOREIGN KEY (id_viaje) REFERENCES viaje (id_viaje) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_pago_sumas CHECK (
        ABS(
            importe_total - (
                comision_company + importe_conductor
            )
        ) < 0.01 -- total = comisión + importe del conductor.
    ),
    CONSTRAINT ck_pago_total CHECK (importe_total >= 0),
    CONSTRAINT ck_pago_comision CHECK (comision_company >= 0),
    CONSTRAINT ck_pago_conductor CHECK (importe_conductor >= 0),
    INDEX idx_pago_estado_fecha (estado_pago, fecha_pago)
) ENGINE = InnoDB;

-- En la tabla valoración se almacenan las valoraciones emitidas por los usuarios al finalizar un viaje.
-- Se permite valorar tanto al rider como al conductor con una puntuación entre 1 y 5.
-- Se crea un índice de usuario valorado para acceder mejor a métricas.
CREATE TABLE IF NOT EXISTS valoracion (
    id_valoracion BIGINT NOT NULL AUTO_INCREMENT,
    id_viaje BIGINT NOT NULL,
    id_usuario_valorador BIGINT NOT NULL,
    id_usuario_valorado BIGINT NOT NULL,
    rol_valorado ENUM('rider', 'conductor') NOT NULL,
    puntuacion TINYINT NOT NULL CHECK (puntuacion BETWEEN 1 AND 5),
    comentario VARCHAR(255) NULL,
    fecha_valoracion DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id_valoracion),
    CONSTRAINT fk_val_viaje FOREIGN KEY (id_viaje) REFERENCES viaje (id_viaje) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_val_valorador FOREIGN KEY (id_usuario_valorador) REFERENCES usuario (id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_val_valorado FOREIGN KEY (id_usuario_valorado) REFERENCES usuario (id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_valoracion_valorado_fecha (
        id_usuario_valorado,
        fecha_valoracion
    )
) ENGINE = InnoDB;

-- La tabla viaje_estado_log almacena el historial de cambios de estado de los viajes.
-- Se modifica automáticamente haciendo uso de un trigger.
CREATE TABLE IF NOT EXISTS viaje_estado_log (
    id_historial BIGINT NOT NULL AUTO_INCREMENT,
    id_viaje BIGINT NOT NULL,
    estado_anterior ENUM(
        'solicitado',
        'aceptado',
        'en_curso',
        'finalizado',
        'cancelado'
    ) NOT NULL,
    estado_nuevo ENUM(
        'solicitado',
        'aceptado',
        'en_curso',
        'finalizado',
        'cancelado'
    ) NOT NULL,
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    comentario VARCHAR(255),
    PRIMARY KEY (id_historial),
    CONSTRAINT fk_log_viaje FOREIGN KEY (id_viaje) REFERENCES viaje (id_viaje) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_log_viaje_fecha (id_viaje, fecha_cambio)
) ENGINE = InnoDB;

-- La tabla audit_operacion se usa como log de operaciones críticas.
-- En esta, se registran inserciones de viajes, actualizaciones de viajes, actualizaciones de ofertas e inserciones de pagos mediante triggers.
CREATE TABLE IF NOT EXISTS audit_operacion (
    id_audit BIGINT NOT NULL AUTO_INCREMENT,
    tabla_afectada VARCHAR(50) NOT NULL,
    id_registro BIGINT NOT NULL,
    accion ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    usuario_mysql VARCHAR(100) NOT NULL,
    fecha_operacion DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    descripcion VARCHAR(255) NULL,
    PRIMARY KEY (id_audit),
    INDEX idx_audit_tabla_fecha (
        tabla_afectada,
        fecha_operacion
    ),
    INDEX idx_audit_registro (tabla_afectada, id_registro)
) ENGINE = InnoDB;

-- PROCEDIMIENTOS ALMACENADOS

DROP PROCEDURE IF EXISTS sp_solicitar_viaje;

DELIMITER $$

-- sp_solicitar_viaje crea un viaje nuevo y genera automáticamente ofertas para
-- los conductores disponibles con vehículo activo y asignación vigente.

CREATE PROCEDURE sp_solicitar_viaje(
    IN p_id_rider BIGINT,
    IN p_origen_lat DECIMAL(9,6),
    IN p_origen_lng DECIMAL(9,6),
    IN p_destino_lat DECIMAL(9,6),
    IN p_destino_lng DECIMAL(9,6),
    IN p_origen_dir VARCHAR(255),
    IN p_destino_dir VARCHAR(255),
    IN p_distancia_km DECIMAL(10,2),
    OUT p_id_viaje BIGINT,
    OUT p_resultado VARCHAR(50)
)
BEGIN
    -- Importe base calculado a partir de la distancia.
    DECLARE v_importe_base DECIMAL(10,2);
    -- Número de ofertas generadas.
    DECLARE v_ofertas_generadas INT DEFAULT 0;
    -- Variable para bloquear la fila real del rider.
    DECLARE v_id_rider_bloqueado BIGINT DEFAULT NULL;
    -- Flag para controlar SELECT ... INTO sin resultado.
    DECLARE v_not_found BOOLEAN DEFAULT FALSE;

    -- Si un SELECT ... INTO no devuelve filas, se controla aquí.
    DECLARE CONTINUE HANDLER FOR NOT FOUND
    BEGIN
        SET v_not_found = TRUE;
    END;

    -- Cualquier error SQL cancela la transacción completa.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_id_viaje = NULL;
        SET p_resultado = 'ERROR_TRANSACCION';
    END;

    START TRANSACTION;

    -- Se bloquea la fila real con FOR UPDATE para mantener consistencia.
    SET v_not_found = FALSE;

    -- 1. Comprobar que el rider existe y está activo.
    SELECT r.id_usuario
    INTO v_id_rider_bloqueado
    FROM rider r
    JOIN usuario u ON u.id_usuario = r.id_usuario
    WHERE r.id_usuario = p_id_rider
      AND u.activo = TRUE
    FOR UPDATE;

    -- Si el rider no existe o no está activo, no se crea el viaje.
    IF v_not_found = TRUE OR v_id_rider_bloqueado IS NULL THEN
        ROLLBACK;
        SET p_id_viaje = NULL;
        SET p_resultado = 'ERROR_RIDER_NO_VALIDO';
    ELSE
        -- 2. Insertar el viaje en estado solicitado.
        INSERT INTO viaje (
            id_rider,
            estado,
            latitud_origen,
            longitud_origen,
            latitud_destino,
            longitud_destino,
            origen_direccion,
            destino_direccion,
            distancia_km,
            fecha_solicitud
        ) VALUES (
            p_id_rider,
            'solicitado',
            p_origen_lat,
            p_origen_lng,
            p_destino_lat,
            p_destino_lng,
            p_origen_dir,
            p_destino_dir,
            p_distancia_km,
            CURRENT_TIMESTAMP
        );

        -- 3. Recuperar el id del viaje recién creado.
        SET p_id_viaje = LAST_INSERT_ID();

        -- 4. Calcular el importe base de la oferta.
        SET v_importe_base = ROUND(p_distancia_km * 1.50, 2);

        -- 5. Generar ofertas para conductores disponibles.
        -- Deben tener asignación vigente con un vehículo activo
        -- Debe haber coherencia de company entre conductor y vehículo.
        INSERT INTO oferta (
            id_viaje,
            id_conductor,
            importe_ofrecido,
            estado_oferta
        )
        SELECT
            p_id_viaje,
            c.id_usuario,
            v_importe_base,
            'pendiente'
        FROM conductor c
        WHERE c.estado_conductor = 'disponible'
          AND EXISTS (
                SELECT 1
                FROM conductor_vehiculo cv
                JOIN vehiculo v ON v.id_vehiculo = cv.id_vehiculo
                WHERE cv.id_conductor = c.id_usuario
                  AND cv.fecha_hasta IS NULL
                  AND v.activo = TRUE
                  AND v.id_company = c.id_company
          );

        -- 6. Guardar cuántas ofertas se han insertado.
        SET v_ofertas_generadas = ROW_COUNT();

        -- Si no se generó ninguna oferta, se deshace el viaje.
        IF v_ofertas_generadas = 0 THEN
            ROLLBACK;
            SET p_id_viaje = NULL;
            SET p_resultado = 'ERROR_SIN_CONDUCTORES_DISPONIBLES';
        ELSE

            -- 7. Confirmar viaje y ofertas.
            COMMIT;
            SET p_resultado = 'OK';
        END IF;
    END IF;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS sp_aceptar_oferta;

DELIMITER $$

-- sp_aceptar_oferta asigna el viaje al primer conductor que lo acepta.
-- Se hace uso de bloqueo pesimista sobre el viaje con SELECT ... FOR UPDATE para evitar dobles aceptaciones concurrentes.

CREATE PROCEDURE sp_aceptar_oferta(
    IN p_id_viaje BIGINT,
    IN p_id_conductor BIGINT,
    IN p_id_vehiculo BIGINT,
    OUT p_resultado VARCHAR(50)
)
BEGIN
    DECLARE v_estado_actual VARCHAR(20) DEFAULT NULL;
    DECLARE v_id_oferta BIGINT DEFAULT NULL;
    DECLARE v_id_vehiculo_bloqueado BIGINT DEFAULT NULL;
    DECLARE v_not_found BOOLEAN DEFAULT FALSE;

    -- Si un SELECT ... INTO no devuelve filas, se controla aquí.
    DECLARE CONTINUE HANDLER FOR NOT FOUND
    BEGIN
        SET v_not_found = TRUE;
    END;

    -- Cualquier error SQL provoca rollback completo.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR_TRANSACCION';
    END;

    START TRANSACTION;

    -- 1. Bloquear el viaje. Solo una sesión podrá aceptarlo.
    SET v_not_found = FALSE;

    SELECT estado
    INTO v_estado_actual
    FROM viaje
    WHERE id_viaje = p_id_viaje
    FOR UPDATE;

    -- Si el viaje no existe, terminar con error controlado.
    IF v_not_found = TRUE OR v_estado_actual IS NULL THEN
        ROLLBACK;
        SET p_resultado = 'ERROR_VIAJE_NO_EXISTE';

    -- Solo se puede aceptar un viaje en estado solicitado.
    ELSEIF v_estado_actual <> 'solicitado' THEN
        ROLLBACK;
        SET p_resultado = 'ERROR_ESTADO_NO_VALIDO';

    ELSE
        -- 2. Buscar y bloquear la oferta pendiente de ese conductor.
        SET v_not_found = FALSE;
        SET v_id_oferta = NULL;

        SELECT id_oferta
        INTO v_id_oferta
        FROM oferta
        WHERE id_viaje = p_id_viaje
          AND id_conductor = p_id_conductor
          AND estado_oferta = 'pendiente'
        FOR UPDATE;

        -- Si no existe oferta pendiente, abortar.
        IF v_not_found = TRUE OR v_id_oferta IS NULL THEN
            ROLLBACK;
            SET p_resultado = 'ERROR_OFERTA_NO_PENDIENTE';

        ELSE
            -- 3. Validar vehículo y asignación vigente.
            -- Se comprueba que el conductor siga disponible.
            -- Se bloquean las filas implicadas para evitar cambios concurrentes.
            SET v_not_found = FALSE;
            SET v_id_vehiculo_bloqueado = NULL;

            SELECT cv.id_vehiculo
            INTO v_id_vehiculo_bloqueado
            FROM conductor_vehiculo cv
            JOIN vehiculo v
                ON v.id_vehiculo = cv.id_vehiculo
            JOIN conductor c
                ON c.id_usuario = cv.id_conductor
            WHERE cv.id_conductor = p_id_conductor
              AND cv.id_vehiculo = p_id_vehiculo
              AND cv.fecha_hasta IS NULL
              AND v.activo = TRUE
              AND v.id_company = c.id_company
              AND c.estado_conductor = 'disponible'
            FOR UPDATE;

            -- Si el vehículo no es válido, abortar.
            IF v_not_found = TRUE OR v_id_vehiculo_bloqueado IS NULL THEN
                ROLLBACK;
                SET p_resultado = 'ERROR_VEHICULO_NO_VALIDO';

            ELSE
                -- 4. Asignar el viaje al conductor ganador.
                UPDATE viaje
                SET
                    estado = 'aceptado',
                    id_conductor = p_id_conductor,
                    id_vehiculo = p_id_vehiculo,
                    fecha_aceptacion = CURRENT_TIMESTAMP
                WHERE id_viaje = p_id_viaje
                  AND estado = 'solicitado';

                -- 5. Marcar su oferta como aceptada.
                UPDATE oferta
                SET
                    estado_oferta = 'aceptada',
                    fecha_respuesta = CURRENT_TIMESTAMP
                WHERE id_oferta = v_id_oferta;

                -- 6. Expirar el resto de ofertas pendientes del mismo viaje.
                UPDATE oferta
                SET
                    estado_oferta = 'expirada',
                    fecha_respuesta = CURRENT_TIMESTAMP
                WHERE id_viaje = p_id_viaje
                  AND id_oferta <> v_id_oferta
                  AND estado_oferta = 'pendiente';

                -- 7. Cambiar el conductor a estado en_viaje.
                UPDATE conductor
                SET estado_conductor = 'en_viaje'
                WHERE id_usuario = p_id_conductor;

                -- 8. Confirmar todos los cambios.
                COMMIT;
                SET p_resultado = 'OK';
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS sp_iniciar_viaje;

DELIMITER $$

-- sp_iniciar_viaje cambia un viaje aceptado a en_curso y registra su fecha_inicio.

CREATE PROCEDURE sp_iniciar_viaje(
    IN p_id_viaje BIGINT,
    OUT p_resultado VARCHAR(50)
)
BEGIN
    DECLARE v_estado_actual VARCHAR(20) DEFAULT NULL;
    DECLARE v_id_conductor BIGINT DEFAULT NULL;
    DECLARE v_id_vehiculo BIGINT DEFAULT NULL;
    DECLARE v_not_found BOOLEAN DEFAULT FALSE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
    BEGIN
        SET v_not_found = TRUE;
    END;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR_TRANSACCION';
    END;

    START TRANSACTION;

    -- Bloquear el viaje antes de cambiar su estado.
    SET v_not_found = FALSE;

    SELECT estado, id_conductor, id_vehiculo
    INTO v_estado_actual, v_id_conductor, v_id_vehiculo
    FROM viaje
    WHERE id_viaje = p_id_viaje
    FOR UPDATE;

    -- Validar que el viaje exista.
    IF v_not_found = TRUE THEN
        ROLLBACK;
        SET p_resultado = 'ERROR_VIAJE_NO_EXISTE';

    -- Solo puede iniciarse si ya fue aceptado.
    ELSEIF v_estado_actual <> 'aceptado' THEN
        ROLLBACK;
        SET p_resultado = 'ERROR_ESTADO_NO_VALIDO';

    -- Debe tener conductor y vehículo asignados.
    ELSEIF v_id_conductor IS NULL OR v_id_vehiculo IS NULL THEN
        ROLLBACK;
        SET p_resultado = 'ERROR_VIAJE_SIN_ASIGNACION';

    ELSE
        -- 1. Marcar el viaje como en curso.
        UPDATE viaje
        SET
            estado = 'en_curso',
            fecha_inicio = CURRENT_TIMESTAMP
        WHERE id_viaje = p_id_viaje;

        -- 2. Confirmar la transición.
        COMMIT;
        SET p_resultado = 'OK';
    END IF;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS sp_finalizar_viaje_y_pagar;

DELIMITER $$

-- sp_finalizar_viaje_y_pagar cierra el viaje, libera al conductor y genera el pago final.

CREATE PROCEDURE sp_finalizar_viaje_y_pagar(
    IN p_id_viaje BIGINT,
    IN p_metodo_pago VARCHAR(20),
    OUT p_resultado VARCHAR(50)
)
BEGIN
    DECLARE v_estado_actual VARCHAR(20) DEFAULT NULL;
    DECLARE v_id_conductor BIGINT DEFAULT NULL;
    DECLARE v_importe_ofrecido DECIMAL(10,2) DEFAULT NULL;
    DECLARE v_importe_total DECIMAL(10,2);
    DECLARE v_comision DECIMAL(10,2);
    DECLARE v_id_pago_existente BIGINT DEFAULT NULL;
    DECLARE v_pago_encontrado BOOLEAN DEFAULT FALSE;
    DECLARE v_oferta_encontrada BOOLEAN DEFAULT TRUE;
    DECLARE v_not_found BOOLEAN DEFAULT FALSE;
    DECLARE v_metodo_pago_valido INT DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
    BEGIN
        SET v_not_found = TRUE;
    END;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR_TRANSACCION';
    END;

    START TRANSACTION;

    -- Bloquear el viaje y recuperar estado y conductor.
    SET v_not_found = FALSE;

    SELECT estado, id_conductor
    INTO v_estado_actual, v_id_conductor
    FROM viaje
    WHERE id_viaje = p_id_viaje
    FOR UPDATE;

    -- Validar existencia.
    IF v_not_found = TRUE THEN
        ROLLBACK;
        SET p_resultado = 'ERROR_VIAJE_NO_EXISTE';

    -- Solo puede finalizarse un viaje en curso.
    ELSEIF v_estado_actual <> 'en_curso' THEN
        ROLLBACK;
        SET p_resultado = 'ERROR_ESTADO_NO_VALIDO';

    ELSE
        -- Validar método de pago dentro del dominio permitido.
        SET v_metodo_pago_valido = (
            p_metodo_pago IN ('tarjeta_credito', 'efectivo', 'wallet')
        );

        IF v_metodo_pago_valido = 0 THEN
            ROLLBACK;
            SET p_resultado = 'ERROR_METODO_PAGO_NO_VALIDO';

        ELSE
            -- Comprobar si ya existe un pago para ese viaje.
            SELECT COUNT(*)
            INTO v_pago_encontrado
            FROM pago
            WHERE id_viaje = p_id_viaje;

            IF v_pago_encontrado > 0 THEN
                ROLLBACK;
                SET p_resultado = 'ERROR_PAGO_YA_EXISTE';

            ELSE
                -- Recuperar y bloquear la oferta aceptada.
                SET v_not_found = FALSE;
                SET v_importe_ofrecido = NULL;

                SELECT importe_ofrecido
                INTO v_importe_ofrecido
                FROM oferta
                WHERE id_viaje = p_id_viaje
                  AND estado_oferta = 'aceptada'
                LIMIT 1
                FOR UPDATE;

                IF v_not_found = TRUE OR v_importe_ofrecido IS NULL THEN
                    SET v_oferta_encontrada = FALSE;
                END IF;

                -- Si no hay oferta aceptada, no se puede liquidar.
                IF v_oferta_encontrada = FALSE THEN
                    ROLLBACK;
                    SET p_resultado = 'ERROR_SIN_OFERTA_ACEPTADA';

                ELSE
                    -- Finalizar el viaje.
                    UPDATE viaje
                    SET
                        estado = 'finalizado',
                        fecha_fin = CURRENT_TIMESTAMP
                    WHERE id_viaje = p_id_viaje;

                    -- Liberar al conductor.
                    UPDATE conductor
                    SET estado_conductor = 'disponible'
                    WHERE id_usuario = v_id_conductor;

                    -- Calcular total y comisión.
                    SET v_importe_total = ROUND(v_importe_ofrecido * 1.20, 2);
                    SET v_comision = ROUND(v_importe_total - v_importe_ofrecido, 2);

                    -- Insertar el pago.
                    INSERT INTO pago (
                        id_viaje,
                        importe_total,
                        comision_company,
                        importe_conductor,
                        metodo_pago,
                        estado_pago,
                        fecha_pago
                    )
                    VALUES (
                        p_id_viaje,
                        v_importe_total,
                        v_comision,
                        v_importe_ofrecido,
                        p_metodo_pago,
                        'completado',
                        CURRENT_TIMESTAMP
                    );

                    -- Confirmar todo.
                    COMMIT;
                    SET p_resultado = 'OK';
                END IF;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;

-- TRIGGERS

DROP TRIGGER IF EXISTS tr_audit_viaje_estado;

DELIMITER $$

-- tr_audit_viaje_estado registra automáticamente en viaje_estado_log cualquier cambio de estado que sufra un viaje.
CREATE TRIGGER tr_audit_viaje_estado
AFTER UPDATE ON viaje
FOR EACH ROW
BEGIN
    -- Comprobar si el estado ha cambiado.
    -- Se usa <=> para comparar incluso con NULL.
    IF NOT (OLD.estado <=> NEW.estado) THEN
        -- Insertar el cambio en la tabla de auditoría.
        INSERT INTO viaje_estado_log (
            id_viaje,
            estado_anterior,
            estado_nuevo,
            comentario
        )
        VALUES (
            NEW.id_viaje,
            OLD.estado,
            NEW.estado,
            'Actualizacion de estado'
        );
    END IF;
END$$

DELIMITER ;

DROP TRIGGER IF EXISTS tr_audit_viaje_insert;

DELIMITER $$

-- tr_audit_viaje_insert registra la creación de viajes en la auditoría general.

CREATE TRIGGER tr_audit_viaje_insert
AFTER INSERT ON viaje
FOR EACH ROW
BEGIN
    INSERT INTO audit_operacion (
        tabla_afectada,
        id_registro,
        accion,
        usuario_mysql,
        descripcion
    )
    VALUES (
        'viaje',
        NEW.id_viaje,
        'INSERT',
        USER(),
        CONCAT('Viaje creado en estado ', NEW.estado)
    );
END$$

DELIMITER ;

DROP TRIGGER IF EXISTS tr_audit_viaje_update;

DELIMITER $$

-- tr_audit_viaje_update registra actualizaciones de viajes en la auditoría general.

CREATE TRIGGER tr_audit_viaje_update
AFTER UPDATE ON viaje
FOR EACH ROW
BEGIN
    INSERT INTO audit_operacion (
        tabla_afectada,
        id_registro,
        accion,
        usuario_mysql,
        descripcion
    )
    VALUES (
        'viaje',
        NEW.id_viaje,
        'UPDATE',
        USER(),
        CONCAT('Viaje actualizado. Estado anterior: ', OLD.estado, ', estado nuevo: ', NEW.estado)
    );
END$$

DELIMITER ;

DROP TRIGGER IF EXISTS tr_audit_oferta_update;

DELIMITER $$

-- tr_audit_oferta_update registra cambios en las ofertas, especialmente aceptaciones y expiraciones.

CREATE TRIGGER tr_audit_oferta_update
AFTER UPDATE ON oferta
FOR EACH ROW
BEGIN
    INSERT INTO audit_operacion (
        tabla_afectada,
        id_registro,
        accion,
        usuario_mysql,
        descripcion
    )
    VALUES (
        'oferta',
        NEW.id_oferta,
        'UPDATE',
        USER(),
        CONCAT('Oferta actualizada. Estado anterior: ', OLD.estado_oferta, ', estado nuevo: ', NEW.estado_oferta)
    );
END$$

DELIMITER ;

DROP TRIGGER IF EXISTS tr_audit_pago_insert;

DELIMITER $$

-- tr_audit_pago_insert registra la creación de pagos en la auditoría general.
CREATE TRIGGER tr_audit_pago_insert
AFTER INSERT ON pago
FOR EACH ROW
BEGIN
    INSERT INTO audit_operacion (
        tabla_afectada,
        id_registro,
        accion,
        usuario_mysql,
        descripcion
    )
    VALUES (
        'pago',
        NEW.id_pago,
        'INSERT',
        USER(),
        CONCAT('Pago creado para viaje ', NEW.id_viaje, ' por importe ', NEW.importe_total)
    );
END$$

DELIMITER ;