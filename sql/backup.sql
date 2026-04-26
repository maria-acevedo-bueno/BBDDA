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
   --set-gtid-purged=OFF \> backup_ride_hailing_$(date +%Y%m%d).sql
*/

-- BACKUP COMPLETO DEL SERVIDOR (Incluye todas las bases de datos):

/* 
   docker exec mysql8 mysqldump \
   -ubackup_user -pBackup1234 \
   --all-databases \
   --single-transaction \
   --routines --triggers --events \
   --set-gtid-purged=OFF \
   > backup_full_$(date +%Y%m%d).sql
*/
-- Además:
-- Si el usuario backup_user no tuviera permisos suficientes para exportar todas las bases de datos del servidor, el backup completo debería ejecutarse con una cuenta administrativa. 
-- Para la práctica, el backup principal es el del esquema ride_hailing.

-- 4. BACKUP DE TABLAS CONCRETAS:
-- Útil para exportar solo las tablas principales de la práctica.
-- Incluye conductor_vehiculo, porque es la tabla que relaciona conductores y vehículos y forma parte del modelo funcional.
-- Incluye audit_operacion, porque forma parte de la auditoría básica.
-- También se debe ejecutar en terminal.

/* 
   docker exec mysql8 mysqldump \
   -ubackup_user -pBackup_Pass_2026! \
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

-- 5. RESTAURAR UN BACKUP:
-- Ejecutar en terminal.
-- Para restaurar un dump que contiene CREATE DATABASE / USE / CREATE TABLE, en esta práctica es más coherente usar root, 
-- ya que admin_user tiene privilegios sobre ride_hailing.* pero no privilegios globales de creación.

-- Opción con cat:
-- cat backup_ride_hailing.sql | docker exec -i mysql8 mysql -uroot -prootpass

-- Opción con redirección:
-- docker exec -i mysql8 mysql -uroot -prootpass < backup_ride_hailing.sql

-- 6. COMPROBACIONES DESPUÉS DEL RESTORE:

-- Se debe comprobar que la base existe:
SHOW DATABASES;
USE ride_hailing;

-- Se comprueban las tablas:
SHOW TABLES;

-- Conteos básicos:
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

-- Se comprueban claves foráneas declaradas.
SELECT
    TABLE_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'ride_hailing'
  AND REFERENCED_TABLE_NAME IS NOT NULL;

-- Se comprueban procedimientos almacenados.
SHOW PROCEDURE STATUS WHERE Db = 'ride_hailing';

-- Se comprueban triggers y vistas:
SHOW TRIGGERS FROM ride_hailing;
SELECT
    TABLE_NAME,
    IS_UPDATABLE
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'ride_hailing';

-- 7. SE COMBRUEBA SI SE PUEDE HACER PITR:
-- PITR = restaurar un backup y aplicar binlogs hasta un momento concreto.
-- Para que PITR sea viable, log_bin debe estar ON y binlog_format debería ser ROW.
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'binlog_format';
SHOW VARIABLES LIKE 'binlog_expire_logs_seconds';
SHOW BINARY LOGS;

-- 8. EJEMPLO DE PITR:
-- Caso: se quiere recuperar hasta antes de un DELETE accidental.
-- Ajustar fechas y nombre de binlog al caso real.
-- Se ejecuta en terminal.

-- 1) Restaurar el backup completo:
-- cat backup_ride_hailing_10_00.sql | docker exec -i mysql8 mysql -uroot -prootpass

-- 2) Extraer cambios hasta antes del error.
-- El nombre del archivo coincide con log_bin=mysql-bin del custom.cnf:
/* 
   docker exec mysql8 mysqlbinlog \
   --start-datetime="2026-04-25 10:00:00" \
   --stop-datetime="2026-04-25 10:29:59" \
   /var/lib/mysql/mysql-bin.000001 > cambios.sql
*/
-- 3) Aplicar cambios:
-- cat cambios.sql | docker exec -i mysql8 mysql -uroot -prootpas

-- 9. BUSCAR UNA OPERACIÓN EN EL BINLOG:
-- Ejemplo para localizar un DELETE.
-- Ejecutar en terminal.
/*
   docker exec mysql8 mysqlbinlog \
   --start-datetime="2026-04-25 10:25:00" \
   --stop-datetime="2026-04-25 10:35:00" \
   /var/lib/mysql/mysql-bin.000001 | grep -A5 -B5 "DELETE"
*/
-- También se puede recuperar por posiciones:
/*
   docker exec mysql8 mysqlbinlog \
   --start-position=154 \
   --stop-position=12345 \
   /var/lib/mysql/mysql-bin.000001 > cambios.sql
*/
-- 10. SNAPSHOT CONSISTENTE:
-- Los snapshots pueden ser inconsistentes si MySQL está escribiendo.
-- Para coordinarlo, se puede bloquear brevemente la lectura de tablas.
-- En esta práctica el método principal es mysqldump, pero se documenta
-- el patrón visto en el temario.

-- Ejecutar en MySQL antes del snapshot:
-- FLUSH TABLES WITH READ LOCK;

-- Tomar el snapshot desde la infraestructura correspondiente.

-- Liberar después:
-- UNLOCK TABLES;

-- 11. SCRIPT DE BACKUP CON ROTACIÓN:
-- Guardar como backup_mysql.sh.
-- Se ejecuta desde el sistema, no desde MySQL.
/*
   #!/bin/bash
   FECHA=$(date +%Y%m%d_%H%M%S)
   BACKUP_DIR="/backups/mysql"
   RETENTION_DAYS=7

   mkdir -p "${BACKUP_DIR}"

   docker exec mysql8 mysqldump \
   -ubackup_user -pBackup_Pass_2026! \
   --databases ride_hailing \
   --single-transaction \
   --routines --triggers --events \
   --set-gtid-purged=OFF \
   | gzip > "${BACKUP_DIR}/backup_ride_hailing_${FECHA}.sql.gz"

   if [ $? -eq 0 ]; then
     echo "Backup creado: backup_ride_hailing_${FECHA}.sql.gz"
   else
     echo "ERROR: Backup falló" >&2
     exit 1
   fi

   find "${BACKUP_DIR}" -name "backup_ride_hailing_*.sql.gz" -mtime +${RETENTION_DAYS} -delete
   echo "Backups con más de ${RETENTION_DAYS} días eliminados"
*/

-- Programar backup diario a las 3:00:
-- crontab -e
-- 0 3 * * * /scripts/backup_mysql.sh >> /var/log/mysql_backup.log 2>&1
