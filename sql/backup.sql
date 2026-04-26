USE ride_hailing;

-- RPO: 24 horas con backup diario.
-- RTO: restauración manual.
-- Método principal: mysqldump.
-- Mejora posible: PITR (si el binlog está activo)

-- Los comandos de backup son ejecutados por el backup_user

-- La configuración de custom.cnf nos permite realizar PITR durante 7 días si se conserva el backup completo y los binlogs necesarios.

-- OPCIONES DE BACKUP HACIENDO USO DE MYSQLDUMP

-- BACKUP LÓGICO:

/* 
   docker exec mysql8 mysqldump \
   -ubackup_user -pBackup1234 \
   --databases ride_hailing \
   --single-transaction \
   --routines --triggers --events \
   --set-gtid-purged=OFF \
   > backup_ride_hailing_$(date +%Y%m%d).sql
*/

-- BACKUP COMPLETO DEL SERVIDOR (Incluye todas las bases de datos):
-- Este backup se recomienda ejecutarlo con root o con un usuario administrador.

/* 
   docker exec mysql8 mysqldump \
   -uroot -prootpass \
   --all-databases \
   --single-transaction \
   --routines --triggers --events \
   --set-gtid-purged=OFF \
   > backup_full_$(date +%Y%m%d).sql
*/

-- BACKUP DE TABLAS CONCRETAS

/* 
   docker exec mysql8 mysqldump \
   -ubackup_user -pBackup1234 \
   --single-transaction \
   ride_hailing \
   company \
   usuario \
   rider \
   conductor \
   vehiculo \
   conductor_vehiculo \
   viaje \
   oferta \
   pago \
   valoracion \
   viaje_estado_log \
   audit_operacion \
   > backup_tablas_ride_hailing_$(date +%Y%m%d).sql
*/

-- RESTAURAR UN BACKUP:

-- Para restaurar un backup, se recomienda usar un usuario root.

-- Opción con cat:
-- cat backup_ride_hailing.sql | docker exec -i mysql8 mysql -uroot -prootpass

-- Opción con redirección:
-- docker exec -i mysql8 mysql -uroot -prootpass < backup_ride_hailing.sql

-- COMPROBACIONES DESPUÉS DEL RESTORE:

-- Se comprueba si la base de datos existe
SHOW DATABASES;
USE ride_hailing;

-- Se comprueban las tablas
SHOW TABLES;

-- Conteo de datos dentro de las diferentes tablas
SELECT 'company' AS tabla, COUNT(*) AS filas FROM company
UNION ALL
SELECT 'usuario', COUNT(*) FROM usuario
UNION ALL
SELECT 'rider', COUNT(*) FROM rider
UNION ALL
SELECT 'conductor', COUNT(*) FROM conductor
UNION ALL
SELECT 'vehiculo', COUNT(*) FROM vehiculo
UNION ALL
SELECT 'conductor_vehiculo', COUNT(*) FROM conductor_vehiculo
UNION ALL
SELECT 'viaje', COUNT(*) FROM viaje
UNION ALL
SELECT 'oferta', COUNT(*) FROM oferta
UNION ALL
SELECT 'pago', COUNT(*) FROM pago
UNION ALL
SELECT 'valoracion', COUNT(*) FROM valoracion
UNION ALL
SELECT 'viaje_estado_log', COUNT(*) FROM viaje_estado_log
UNION ALL
SELECT 'audit_operacion', COUNT(*) FROM audit_operacion;

-- Comprobación de claves foráneas
SELECT
    TABLE_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'ride_hailing'
  AND REFERENCED_TABLE_NAME IS NOT NULL;

-- Comprobación de procedimientos almacenados.
SHOW PROCEDURE STATUS WHERE Db = 'ride_hailing';

-- Comprobación de triggers y vistas:
SHOW TRIGGERS FROM ride_hailing;
SELECT
    TABLE_NAME,
    IS_UPDATABLE
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'ride_hailing';

-- SE COMPRUEBA SI SE PUEDE HACER PITR
-- Para que PITR sea viable, log_bin debe estar ON y binlog_format debería ser ROW (custom.cnf está configurado para ello).
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'binlog_format';
SHOW VARIABLES LIKE 'binlog_expire_logs_seconds';
SHOW BINARY LOGS;