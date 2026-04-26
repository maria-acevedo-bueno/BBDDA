USE ride_hailing;

-- Se cargan los datos iniciales
-- 1. COMPANIES

INSERT INTO company (
    nombre,
    cif,
    activo
) VALUES
    ('Cabify', 'A12345678', TRUE),
    ('Uber', 'B23456789', TRUE),
    ('Bolt', 'C34567890', TRUE),
    ('Lyft', 'D45678901', TRUE),
    ('Free Now', 'E56789012', TRUE);

-- 2. USUARIOS
-- Primero se insertan riders y después conductores para controlar mejor los ids.

INSERT INTO usuario (
    nombre,
    apellido1,
    apellido2,
    email,
    telefono,
    activo
) VALUES
    ('Ana', 'Lopez', 'Martin', 'ana.lopez@ridehailing.test', '600000001', TRUE),         -- 1
    ('Luis', 'Garcia', 'Santos', 'luis.garcia@ridehailing.test', '600000002', TRUE),      -- 2
    ('Marta', 'Perez', 'Ruiz', 'marta.perez@ridehailing.test', '600000003', TRUE),        -- 3
    ('Diego', 'Navarro', 'Gil', 'diego.navarro@ridehailing.test', '600000004', TRUE),     -- 4
    ('Sara', 'Ortega', 'Mora', 'sara.ortega@ridehailing.test', '600000005', TRUE),        -- 5
    ('Pedro', 'Arias', 'Luna', 'pedro.arias@ridehailing.test', '600000006', TRUE),      -- 6
    ('Lucia', 'Ramos', 'Iglesias', 'lucia.ramos@ridehailing.test', '600000007', TRUE),    -- 7
    ('Jorge', 'Mendez', 'Prieto', 'jorge.mendez@ridehailing.test', '600000008', TRUE),    -- 8
    ('Paula', 'Herrera', 'Sanz', 'paula.herrera@ridehailing.test', '600000009', TRUE),    -- 9
    ('Raul', 'Castillo', 'Fuentes', 'raul.castillo@ridehailing.test', '600000010', TRUE), -- 10
    ('Carlos', 'Serrano', 'Vega', 'carlos.serrano@ridehailing.test', '611000001', TRUE),  -- 11
    ('Elena', 'Romero', 'Diaz', 'elena.romero@ridehailing.test', '611000002', TRUE),      -- 12
    ('Javier', 'Molina', 'Rey', 'javier.molina@ridehailing.test', '611000003', TRUE),     -- 13
    ('Laura', 'Castro', 'Nieto', 'laura.castro@ridehailing.test', '611000004', TRUE),     -- 14
    ('Pablo', 'Suarez', 'Ramos', 'pablo.suarez@ridehailing.test', '611000005', TRUE),     -- 15
    ('Nuria', 'Arias', 'Blanco', 'nuria.arias@ridehailing.test', '611000006', TRUE),      -- 16
    ('Alberto', 'Soto', 'Marin', 'alberto.soto@ridehailing.test', '611000007', TRUE),     -- 17
    ('Irene', 'Delgado', 'Vidal', 'irene.delgado@ridehailing.test', '611000008', TRUE),   -- 18
    ('Mario', 'Benitez', 'Peña', 'mario.benitez@ridehailing.test', '611000009', TRUE),    -- 19
    ('Clara', 'Pascual', 'Lozano', 'clara.pascual@ridehailing.test', '611000010', TRUE),  -- 20
    ('David', 'Soler', 'Acosta', 'david.soler@ridehailing.test', '611000011', TRUE),      -- 21
    ('Rocio', 'Campos', 'Mendez', 'rocio.campos@ridehailing.test', '611000012', TRUE),    -- 22
    ('Adrian', 'Rivas', 'Dominguez', 'adrian.rivas@ridehailing.test', '611000013', TRUE), -- 23
    ('Noelia', 'Vargas', 'Leal', 'noelia.vargas@ridehailing.test', '611000014', TRUE),    -- 24
    ('Sergio', 'Pardo', 'Cano', 'sergio.pardo@ridehailing.test', '611000015', TRUE),      -- 25
    ('Beatriz', 'Lorenzo', 'Nuñez', 'beatriz.lorenzo@ridehailing.test', '611000016', TRUE), -- 26
    ('Ivan', 'Crespo', 'Moya', 'ivan.crespo@ridehailing.test', '611000017', TRUE),        -- 27
    ('Alicia', 'Redondo', 'Sierra', 'alicia.redondo@ridehailing.test', '611000018', TRUE), -- 28
    ('Hugo', 'Requena', 'Polo', 'hugo.requena@ridehailing.test', '611000019', TRUE),      -- 29
    ('Julia', 'Pastor', 'Saez', 'julia.pastor@ridehailing.test', '611000020', TRUE);      -- 30

-- 3. RIDERS

INSERT INTO rider (id_usuario) VALUES
    (1), (2), (3), (4), (5),
    (6), (7), (8), (9), (10);

-- 4. CONDUCTORES

INSERT INTO conductor (
    id_usuario,
    numero_licencia,
    estado_conductor,
    id_company
) VALUES
    (11, 'LIC-MAD-0001', 'disponible',   1),
    (12, 'LIC-MAD-0002', 'disponible',   1),
    (13, 'LIC-BCN-0001', 'disponible',   2),
    (14, 'LIC-BCN-0002', 'desconectado', 2),
    (15, 'LIC-VLC-0001', 'disponible',   3),
    (16, 'LIC-VLC-0002', 'suspendido',   3),
    (17, 'LIC-BIL-0001', 'disponible',   4),
    (18, 'LIC-BIL-0002', 'disponible',   4),
    (19, 'LIC-SEV-0001', 'disponible',   5),
    (20, 'LIC-SEV-0002', 'desconectado', 5),
    (21, 'LIC-MAD-0003', 'disponible',   1),
    (22, 'LIC-BCN-0003', 'en_viaje',     2),
    (23, 'LIC-VLC-0003', 'en_viaje',     3),
    (24, 'LIC-BIL-0003', 'disponible',   4),
    (25, 'LIC-SEV-0003', 'disponible',   5),
    (26, 'LIC-MAD-0004', 'desconectado', 1),
    (27, 'LIC-BCN-0004', 'disponible',   2),
    (28, 'LIC-VLC-0004', 'disponible',   3),
    (29, 'LIC-BIL-0004', 'suspendido',   4),
    (30, 'LIC-SEV-0004', 'disponible',   5);

-- 5. VEHICULOS

INSERT INTO vehiculo (
    id_company,
    matricula,
    marca,
    modelo,
    color,
    capacidad,
    activo
) VALUES
    (1, '1111AAA', 'Toyota',  'Corolla', 'Blanco', 4, TRUE),   -- 1
    (1, '1112AAB', 'Seat',    'Leon',    'Negro',  4, TRUE),   -- 2
    (1, '1113AAC', 'Skoda',   'Octavia', 'Gris',   4, TRUE),   -- 3
    (1, '1114AAD', 'Hyundai', 'i30',     'Azul',   4, TRUE),   -- 4
    (2, '2221BBB', 'Renault', 'Clio',    'Rojo',   4, TRUE),   -- 5
    (2, '2222BBC', 'Peugeot', '308',     'Blanco', 4, TRUE),   -- 6
    (2, '2223BBD', 'Citroen', 'C4',      'Negro',  4, TRUE),   -- 7
    (2, '2224BBE', 'Kia',     'Ceed',    'Gris',   4, TRUE),   -- 8
    (3, '3331CCC', 'Hyundai', 'i30',     'Rojo',   4, TRUE),   -- 9
    (3, '3332CCD', 'Kia',     'Ceed',    'Blanco', 4, FALSE),  -- 10
    (3, '3333CCE', 'Toyota',  'Yaris',   'Azul',   4, TRUE),   -- 11
    (3, '3334CCF', 'Seat',    'Ibiza',   'Negro',  4, TRUE),   -- 12
    (4, '4441DDD', 'Volkswagen', 'Golf', 'Gris',   4, TRUE),   -- 13
    (4, '4442DDE', 'Ford',    'Focus',   'Blanco', 4, TRUE),   -- 14
    (4, '4443DDF', 'Opel',    'Astra',   'Azul',   4, TRUE),   -- 15
    (4, '4444DDG', 'Mazda',   '3',       'Rojo',   4, TRUE),   -- 16
    (5, '5551EEE', 'Peugeot', '208',     'Negro',  4, TRUE),   -- 17
    (5, '5552EEF', 'Renault', 'Megane',  'Gris',   4, TRUE),   -- 18
    (5, '5553EEG', 'Toyota',  'Corolla', 'Blanco', 4, TRUE),   -- 19
    (5, '5554EEH', 'Hyundai', 'Elantra', 'Azul',   4, TRUE);   -- 20

-- 6. ASIGNACIONES CONDUCTOR-VEHICULO
-- fecha_hasta NULL indica asignación vigente.

INSERT INTO conductor_vehiculo (
    id_conductor,
    id_vehiculo,
    fecha_desde,
    fecha_hasta
) VALUES
    (11, 1,  '2026-01-01 08:00:00', NULL),
    (12, 2,  '2026-01-01 08:00:00', NULL),
    (21, 3,  '2026-01-01 08:00:00', NULL),
    (26, 4,  '2026-01-01 08:00:00', NULL),

    (13, 5,  '2026-01-01 08:00:00', NULL),
    (14, 6,  '2026-01-01 08:00:00', NULL),
    (22, 7,  '2026-01-01 08:00:00', NULL),
    (27, 8,  '2026-01-01 08:00:00', NULL),

    (15, 9,  '2026-01-01 08:00:00', NULL),
    (16, 10, '2026-01-01 08:00:00', NULL),
    (23, 11, '2026-01-01 08:00:00', NULL),
    (28, 12, '2026-01-01 08:00:00', NULL),

    (17, 13, '2026-01-01 08:00:00', NULL),
    (18, 14, '2026-01-01 08:00:00', NULL),
    (24, 15, '2026-01-01 08:00:00', NULL),
    (29, 16, '2026-01-01 08:00:00', NULL),

    (19, 17, '2026-01-01 08:00:00', NULL),
    (20, 18, '2026-01-01 08:00:00', NULL),
    (25, 19, '2026-01-01 08:00:00', NULL),
    (30, 20, '2026-01-01 08:00:00', NULL),

    -- histórico adicional:
    (15, 10, '2025-06-01 08:00:00', '2025-12-31 23:59:59'),
    (17, 14, '2025-03-01 08:00:00', '2025-07-15 20:00:00'),
    (19, 18, '2025-02-10 08:00:00', '2025-11-01 18:00:00');

-- 7. VIAJES HISTORICOS

INSERT INTO viaje (
    id_rider,
    id_conductor,
    id_vehiculo,
    estado,
    fecha_solicitud,
    fecha_aceptacion,
    fecha_inicio,
    fecha_fin,
    latitud_origen,
    longitud_origen,
    latitud_destino,
    longitud_destino,
    origen_direccion,
    destino_direccion,
    distancia_km,
    cancelado_por,
    motivo_cancelacion
) VALUES
    (1, 11, 1,  'finalizado', '2026-04-20 09:00:00', '2026-04-20 09:01:00', '2026-04-20 09:05:00', '2026-04-20 09:25:00', 40.416775, -3.703790, 40.430000, -3.690000, 'Puerta del Sol, Madrid', 'Nuevos Ministerios, Madrid', 6.40, NULL, NULL),
    (2, 12, 2,  'finalizado', '2026-04-20 10:00:00', '2026-04-20 10:02:00', '2026-04-20 10:07:00', '2026-04-20 10:35:00', 40.420000, -3.705000, 40.450000, -3.700000, 'Atocha, Madrid', 'Chamartin, Madrid', 8.10, NULL, NULL),
    (3, NULL, NULL, 'cancelado', '2026-04-20 11:00:00', NULL, NULL, NULL, 41.387000, 2.170000, 41.400000, 2.150000, 'Plaza Catalunya, Barcelona', 'Sants Estacio, Barcelona', 5.20, 'rider', 'Cancelacion del cliente'),
    (4, 13, 5,  'finalizado', '2026-04-21 08:15:00', '2026-04-21 08:16:00', '2026-04-21 08:20:00', '2026-04-21 08:42:00', 41.390000, 2.160000, 41.405000, 2.175000, 'Universitat, Barcelona', 'Sagrada Familia, Barcelona', 4.90, NULL, NULL),
    (5, 15, 9,  'finalizado', '2026-04-21 09:30:00', '2026-04-21 09:32:00', '2026-04-21 09:36:00', '2026-04-21 10:05:00', 39.469900, -0.376300, 39.480000, -0.390000, 'Centro, Valencia', 'Campanar, Valencia', 7.00, NULL, NULL),
    (6, 17, 13, 'finalizado', '2026-04-21 11:00:00', '2026-04-21 11:01:00', '2026-04-21 11:04:00', '2026-04-21 11:28:00', 43.263000, -2.935000, 43.270000, -2.950000, 'Abando, Bilbao', 'Deusto, Bilbao', 5.70, NULL, NULL),
    (7, 19, 17, 'finalizado', '2026-04-21 12:10:00', '2026-04-21 12:12:00', '2026-04-21 12:15:00', '2026-04-21 12:46:00', 37.389000, -5.984000, 37.400000, -5.970000, 'Centro, Sevilla', 'Nervion, Sevilla', 6.80, NULL, NULL),
    (8, NULL, NULL, 'cancelado', '2026-04-21 13:00:00', NULL, NULL, NULL, 40.410000, -3.690000, 40.445000, -3.710000, 'Retiro, Madrid', 'Moncloa, Madrid', 7.40, 'sistema', 'Sin conductores disponibles'),
    (9, 21, 3,  'finalizado', '2026-04-22 08:00:00', '2026-04-22 08:01:00', '2026-04-22 08:05:00', '2026-04-22 08:33:00', 40.430000, -3.700000, 40.455000, -3.685000, 'Cuatro Caminos, Madrid', 'Plaza Castilla, Madrid', 6.90, NULL, NULL),
    (10, 22, 7, 'aceptado',   '2026-04-22 09:00:00', '2026-04-22 09:02:00', NULL, NULL, 41.380000, 2.160000, 41.395000, 2.180000, 'Raval, Barcelona', 'Glories, Barcelona', 5.60, NULL, NULL),
    (1, 23, 11, 'en_curso',   '2026-04-22 10:00:00', '2026-04-22 10:01:00', '2026-04-22 10:05:00', NULL, 39.470000, -0.380000, 39.490000, -0.360000, 'Mestalla, Valencia', 'Malvarrosa, Valencia', 8.30, NULL, NULL),
    (2, 24, 15, 'finalizado', '2026-04-22 11:00:00', '2026-04-22 11:03:00', '2026-04-22 11:07:00', '2026-04-22 11:39:00', 43.260000, -2.940000, 43.275000, -2.960000, 'Casco Viejo, Bilbao', 'San Ignacio, Bilbao', 7.10, NULL, NULL),
    (3, 25, 19, 'finalizado', '2026-04-22 12:00:00', '2026-04-22 12:02:00', '2026-04-22 12:06:00', '2026-04-22 12:31:00', 37.385000, -5.990000, 37.405000, -5.960000, 'Triana, Sevilla', 'Santa Justa, Sevilla', 7.90, NULL, NULL),
    (4, NULL, NULL, 'solicitado', '2026-04-22 13:15:00', NULL, NULL, NULL, 40.400000, -3.710000, 40.420000, -3.695000, 'Principe Pio, Madrid', 'Gran Via, Madrid', 4.80, NULL, NULL),
    (5, NULL, NULL, 'solicitado', '2026-04-22 14:00:00', NULL, NULL, NULL, 41.392000, 2.165000, 41.408000, 2.185000, 'Diagonal, Barcelona', 'Poblenou, Barcelona', 6.20, NULL, NULL);

-- 8. OFERTAS HISTORICAS

INSERT INTO oferta (
    id_viaje,
    id_conductor,
    fecha_envio,
    fecha_respuesta,
    estado_oferta,
    importe_ofrecido
) VALUES
    (1, 11, '2026-04-20 09:00:20', '2026-04-20 09:00:50', 'aceptada', 9.60),
    (1, 12, '2026-04-20 09:00:20', '2026-04-20 09:01:10', 'expirada', 9.60),
    (1, 21, '2026-04-20 09:00:20', '2026-04-20 09:01:10', 'expirada', 9.60),

    (2, 12, '2026-04-20 10:00:15', '2026-04-20 10:01:00', 'aceptada', 12.15),
    (2, 11, '2026-04-20 10:00:15', '2026-04-20 10:01:05', 'expirada', 12.15),
    (2, 21, '2026-04-20 10:00:15', '2026-04-20 10:01:05', 'expirada', 12.15),

    (3, 13, '2026-04-20 11:00:20', '2026-04-20 11:02:00', 'rechazada', 7.80),
    (3, 15, '2026-04-20 11:00:20', '2026-04-20 11:03:00', 'expirada', 7.80),

    (4, 13, '2026-04-21 08:15:20', '2026-04-21 08:15:50', 'aceptada', 7.35),
    (4, 22, '2026-04-21 08:15:20', '2026-04-21 08:16:10', 'expirada', 7.35),

    (5, 15, '2026-04-21 09:30:20', '2026-04-21 09:31:00', 'aceptada', 10.50),
    (5, 23, '2026-04-21 09:30:20', '2026-04-21 09:31:20', 'expirada', 10.50),

    (6, 17, '2026-04-21 11:00:20', '2026-04-21 11:00:45', 'aceptada', 8.55),
    (6, 24, '2026-04-21 11:00:20', '2026-04-21 11:01:00', 'expirada', 8.55),

    (7, 19, '2026-04-21 12:10:20', '2026-04-21 12:11:00', 'aceptada', 10.20),
    (7, 25, '2026-04-21 12:10:20', '2026-04-21 12:11:10', 'expirada', 10.20),

    (8, 11, '2026-04-21 13:00:20', NULL, 'expirada', 11.10),
    (8, 12, '2026-04-21 13:00:20', NULL, 'expirada', 11.10),

    (9, 21, '2026-04-22 08:00:20', '2026-04-22 08:00:55', 'aceptada', 10.35),
    (9, 11, '2026-04-22 08:00:20', '2026-04-22 08:01:00', 'expirada', 10.35),

    (10, 22, '2026-04-22 09:00:20', '2026-04-22 09:01:30', 'aceptada', 8.40),
    (10, 13, '2026-04-22 09:00:20', '2026-04-22 09:01:35', 'expirada', 8.40),
    (10, 27, '2026-04-22 09:00:20', '2026-04-22 09:01:40', 'expirada', 8.40),

    (11, 23, '2026-04-22 10:00:20', '2026-04-22 10:00:50', 'aceptada', 12.45),
    (11, 15, '2026-04-22 10:00:20', '2026-04-22 10:01:00', 'expirada', 12.45),
    (11, 28, '2026-04-22 10:00:20', '2026-04-22 10:01:10', 'expirada', 12.45),

    (12, 24, '2026-04-22 11:00:20', '2026-04-22 11:02:00', 'aceptada', 10.65),
    (12, 17, '2026-04-22 11:00:20', '2026-04-22 11:02:10', 'expirada', 10.65),

    (13, 25, '2026-04-22 12:00:20', '2026-04-22 12:01:00', 'aceptada', 11.85),
    (13, 19, '2026-04-22 12:00:20', '2026-04-22 12:01:10', 'expirada', 11.85),

    (14, 11, '2026-04-22 13:15:20', NULL, 'pendiente', 7.20),
    (14, 12, '2026-04-22 13:15:20', NULL, 'pendiente', 7.20),
    (14, 21, '2026-04-22 13:15:20', NULL, 'pendiente', 7.20),

    (15, 13, '2026-04-22 14:00:20', NULL, 'pendiente', 9.30),
    (15, 22, '2026-04-22 14:00:20', NULL, 'pendiente', 9.30),
    (15, 27, '2026-04-22 14:00:20', NULL, 'pendiente', 9.30);

-- 9. PAGOS HISTORICOS

INSERT INTO pago (
    id_viaje,
    importe_total,
    comision_company,
    importe_conductor,
    metodo_pago,
    estado_pago,
    fecha_pago
) VALUES
    (1, 11.52, 1.92, 9.60, 'tarjeta_credito', 'completado', '2026-04-20 09:26:00'),
    (2, 14.58, 2.43, 12.15, 'wallet', 'completado', '2026-04-20 10:36:00'),
    (4, 8.82, 1.47, 7.35, 'tarjeta_credito', 'completado', '2026-04-21 08:43:00'),
    (5, 12.60, 2.10, 10.50, 'efectivo', 'completado', '2026-04-21 10:06:00'),
    (6, 10.26, 1.71, 8.55, 'wallet', 'completado', '2026-04-21 11:29:00'),
    (7, 12.24, 2.04, 10.20, 'tarjeta_credito', 'completado', '2026-04-21 12:47:00'),
    (9, 12.42, 2.07, 10.35, 'wallet', 'completado', '2026-04-22 08:34:00'),
    (12, 12.78, 2.13, 10.65, 'efectivo', 'completado', '2026-04-22 11:40:00'),
    (13, 14.22, 2.37, 11.85, 'tarjeta_credito', 'completado', '2026-04-22 12:32:00');

-- 10. VALORACIONES

INSERT INTO valoracion (
    id_viaje,
    id_usuario_valorador,
    id_usuario_valorado,
    rol_valorado,
    puntuacion,
    comentario,
    fecha_valoracion
) VALUES
    (1, 1, 11, 'conductor', 5, 'Muy buen servicio', '2026-04-20 09:30:00'),
    (1, 11, 1, 'rider', 5, 'Cliente puntual', '2026-04-20 09:31:00'),
    (2, 2, 12, 'conductor', 4, 'Viaje correcto', '2026-04-20 10:40:00'),
    (2, 12, 2, 'rider', 5, 'Cliente amable', '2026-04-20 10:41:00'),
    (4, 4, 13, 'conductor', 5, 'Todo perfecto', '2026-04-21 08:50:00'),
    (4, 13, 4, 'rider', 5, 'Rider correcto', '2026-04-21 08:51:00'),
    (5, 5, 15, 'conductor', 4, 'Buen trayecto', '2026-04-21 10:10:00'),
    (5, 15, 5, 'rider', 4, 'Cliente serio', '2026-04-21 10:11:00'),
    (6, 6, 17, 'conductor', 5, 'Muy rapido', '2026-04-21 11:35:00'),
    (7, 7, 19, 'conductor', 4, 'Conduccion correcta', '2026-04-21 12:50:00'),
    (9, 9, 21, 'conductor', 5, 'Excelente', '2026-04-22 08:40:00'),
    (12, 2, 24, 'conductor', 4, 'Buen servicio', '2026-04-22 11:45:00'),
    (13, 3, 25, 'conductor', 5, 'Muy profesional', '2026-04-22 12:40:00');

-- 11. HISTORIAL DE ESTADOS
-- Se insertan manualmente como carga histórica de ejemplo.

INSERT INTO viaje_estado_log (
    id_viaje,
    estado_anterior,
    estado_nuevo,
    fecha_cambio,
    comentario
) VALUES
    (1, 'solicitado', 'aceptado',  '2026-04-20 09:01:00', 'Aceptacion inicial del viaje'),
    (1, 'aceptado',   'en_curso',  '2026-04-20 09:05:00', 'Inicio del trayecto'),
    (1, 'en_curso',   'finalizado','2026-04-20 09:25:00', 'Fin del trayecto'),

    (2, 'solicitado', 'aceptado',  '2026-04-20 10:02:00', 'Aceptacion inicial del viaje'),
    (2, 'aceptado',   'en_curso',  '2026-04-20 10:07:00', 'Inicio del trayecto'),
    (2, 'en_curso',   'finalizado','2026-04-20 10:35:00', 'Fin del trayecto'),

    (3, 'solicitado', 'cancelado', '2026-04-20 11:05:00', 'Cancelacion del rider'),

    (4, 'solicitado', 'aceptado',  '2026-04-21 08:16:00', 'Aceptacion inicial del viaje'),
    (4, 'aceptado',   'en_curso',  '2026-04-21 08:20:00', 'Inicio del trayecto'),
    (4, 'en_curso',   'finalizado','2026-04-21 08:42:00', 'Fin del trayecto'),

    (5, 'solicitado', 'aceptado',  '2026-04-21 09:32:00', 'Aceptacion inicial del viaje'),
    (5, 'aceptado',   'en_curso',  '2026-04-21 09:36:00', 'Inicio del trayecto'),
    (5, 'en_curso',   'finalizado','2026-04-21 10:05:00', 'Fin del trayecto'),

    (6, 'solicitado', 'aceptado',  '2026-04-21 11:01:00', 'Aceptacion inicial del viaje'),
    (6, 'aceptado',   'en_curso',  '2026-04-21 11:04:00', 'Inicio del trayecto'),
    (6, 'en_curso',   'finalizado','2026-04-21 11:28:00', 'Fin del trayecto'),

    (7, 'solicitado', 'aceptado',  '2026-04-21 12:12:00', 'Aceptacion inicial del viaje'),
    (7, 'aceptado',   'en_curso',  '2026-04-21 12:15:00', 'Inicio del trayecto'),
    (7, 'en_curso',   'finalizado','2026-04-21 12:46:00', 'Fin del trayecto'),

    (8, 'solicitado', 'cancelado', '2026-04-21 13:10:00', 'Cancelacion automatica por falta de servicio'),

    (9, 'solicitado', 'aceptado',  '2026-04-22 08:01:00', 'Aceptacion inicial del viaje'),
    (9, 'aceptado',   'en_curso',  '2026-04-22 08:05:00', 'Inicio del trayecto'),
    (9, 'en_curso',   'finalizado','2026-04-22 08:33:00', 'Fin del trayecto'),

    (10,'solicitado', 'aceptado',  '2026-04-22 09:02:00', 'Aceptacion inicial del viaje'),

    (11,'solicitado', 'aceptado',  '2026-04-22 10:01:00', 'Aceptacion inicial del viaje'),
    (11,'aceptado',   'en_curso',  '2026-04-22 10:05:00', 'Inicio del trayecto'),

    (12,'solicitado', 'aceptado',  '2026-04-22 11:03:00', 'Aceptacion inicial del viaje'),
    (12,'aceptado',   'en_curso',  '2026-04-22 11:07:00', 'Inicio del trayecto'),
    (12,'en_curso',   'finalizado','2026-04-22 11:39:00', 'Fin del trayecto'),

    (13,'solicitado', 'aceptado',  '2026-04-22 12:02:00', 'Aceptacion inicial del viaje'),
    (13,'aceptado',   'en_curso',  '2026-04-22 12:06:00', 'Inicio del trayecto'),
    (13,'en_curso',   'finalizado','2026-04-22 12:31:00', 'Fin del trayecto');