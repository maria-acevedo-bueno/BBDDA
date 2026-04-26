# CÓMO OPERAR SOBRE LA BASE DE DATOS

Este documento agrupa los comandos necesarios para iniciar la base de datos, cargar los datos de prueba y ejecutar los archivos .sql principales del proyecto.

## 1. Requisitos previos

Antes de empezar, comprobar que Docker y Docker Compose están instalados.

En Bash/PowerShell:

```bash
docker --version
docker compose version
```

## 2. Arrancar la base de datos con Docker Compose

Desde la carpeta raíz del proyecto, ejecutar:

En Bash/PowerShell:

```bash
docker compose up -d
```

Comprobar que el contenedor está levantado:

En Bash/Powershell:

```bash
docker compose ps
```

Ver los logs de MySQL:

En Bash/Powershell:

```bash
docker compose logs -f mysql
```

Comprobar que MySQL está listo:

En Bash/PowerShell:

```bash
docker exec -it mysql8 mysqladmin ping -h 127.0.0.1 -uroot -prootpass
```

Si la salida es:

```text
mysqld is alive
```

la base de datos está preparada para usarse.

## 3. Conectarse a MySQL

### 3.1 Conectarse desde dentro del contenedor

En Bash/PowerShell:

```bash
docker exec -it mysql8 mysql -uroot -prootpass
```

### 3.2 Conectarse desde la máquina local

En Bash/PowerShell:

```bash
mysql -h 127.0.0.1 -P 3306 -uroot -p
```

Cuando pida contraseña:

```text
rootpass
```

## 4. Cargar la base de datos

El orden recomendado para cargar los scripts es:

```text
1. schema.sql
2. data.sql
3. permissions.sql
```

> Cabe destacar que `schema.sql` elimina la base de datos anterior si existe y la vuelve a crear desde cero.

### 4.1 Cargar el esquema

En Bash:

```bash
docker exec -i mysql8 mysql -uroot -prootpass < sql/schema.sql
```

En PowerShell:

```powershell
Get-Content -Raw .\sql\schema.sql | docker exec -i mysql8 mysql -uroot -prootpass
```

### 4.2 Cargar los datos de prueba

En Bash:

```bash
docker exec -i mysql8 mysql -uroot -prootpass < sql/data.sql
```

En PowerShell:

```powershell
Get-Content -Raw .\sql\data.sql | docker exec -i mysql8 mysql -uroot -prootpass
```

### 4.3 Cargar permisos, roles y vistas

En Bash:

```bash
docker exec -i mysql8 mysql -uroot -prootpass < sql/permissions.sql
```

En PowerShell:

```powershell
Get-Content -Raw .\sql\permissions.sql | docker exec -i mysql8 mysql -uroot -prootpass
```

## 5. Comprobar que la carga ha funcionado

Entrar en MySQL:

En Bash:

```bash
docker exec -it mysql8 mysql -uroot -prootpass
```

En PowerShell:

```powershell
docker exec -it mysql8 mysql -uroot -prootpass
```

Dentro de MySQL:

```sql
USE ride_hailing;
SHOW TABLES;
```

Comprobar conteos básicos:

```sql
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
SELECT 'viaje', COUNT(*) FROM viaje
UNION ALL
SELECT 'oferta', COUNT(*) FROM oferta
UNION ALL
SELECT 'pago', COUNT(*) FROM pago;
```

Comprobar procedimientos almacenados:

```sql
SHOW PROCEDURE STATUS WHERE Db = 'ride_hailing';
```

Comprobar triggers:

```sql
SHOW TRIGGERS FROM ride_hailing;
```

Comprobar vistas:

```sql
SELECT TABLE_NAME
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'ride_hailing';
```

## 6. Ejecutar consultas operativas

El archivo `queries.sql` contiene consultas de operación y comprobación.

En Bash:

```bash
docker exec -i mysql8 mysql -uroot -prootpass < sql/queries.sql
```

En PowerShell:

```powershell
Get-Content -Raw .\sql\queries.sql | docker exec -i mysql8 mysql -uroot -prootpass
```

También se pueden ejecutar consultas manualmente entrando al cliente MySQL:

En Bash:

```bash
docker exec -it mysql8 mysql -uroot -prootpass
```

En PowerShell:

```powershell
docker exec -it mysql8 mysql -uroot -prootpass
```

Y después:

```sql
USE ride_hailing;
```

## 7. Ejecutar el dashboard

El archivo `dashboard.sql` contiene consultas para revisar métricas del sistema.

En Bash:

```bash
docker exec -i mysql8 mysql -uroot -prootpass < sql/dashboard.sql
```

En PowerShell:

```powershell
Get-Content -Raw .\sql\dashboard.sql | docker exec -i mysql8 mysql -uroot -prootpass
```

Para guardar la salida en un archivo en Bash:

```bash
docker exec -i mysql8 mysql -uroot -prootpass < sql/dashboard.sql > dashboard_output.txt
```

Para guardar la salida en PowerShell:

```powershell
Get-Content -Raw .\sql\dashboard.sql | docker exec -i mysql8 mysql -uroot -prootpass | Out-File dashboard_output.txt
```

## 8. Backup y restore

El archivo `backup.sql` documenta los comandos de backup y recuperación.

### 8.1 Crear backup de la base de datos

En Bash:

```bash
docker exec mysql8 mysqldump \
  -ubackup_user -pBackup_Pass_2026! \
  --databases ride_hailing \
  --single-transaction \
  --routines --triggers --events \
  --set-gtid-purged=OFF \
  > backup_ride_hailing_$(date +%Y%m%d).sql
```

En PowerShell:

```powershell
docker exec mysql8 mysqldump `
  -ubackup_user -pBackup_Pass_2026! `
  --databases ride_hailing `
  --single-transaction `
  --routines --triggers --events `
  --set-gtid-purged=OFF `
  > backup_ride_hailing.sql
```

### 8.2 Restaurar backup

En el nombre del archivo de backup, añadir la fecha que aparezca en el nombre del backup creado para cada comando

En Bash:

```bash
cat backup_ride_hailing_*.sql | docker exec -i mysql8 mysql -uroot -prootpass
```

O también:

```bash
docker exec -i mysql8 mysql -uroot -prootpass < backup_ride_hailing_*.sql
```

En PowerShell:

```powershell
Get-Content -Raw .\backup_ride_hailing_*.sql | docker exec -i mysql8 mysql -uroot -prootpass
```

### 8.3 Recuperación punto en el tiempo con PITR

Si el `binlog` está activo, se puede recuperar la base de datos hasta un momento concreto anterior a un error.

Comprobar primero que el `binlog` está activo:

```sql
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'binlog_format';
SHOW VARIABLES LIKE 'binlog_expire_logs_seconds';
SHOW BINARY LOGS;
```

Restaurar el backup completo anterior al error:

```bash
cat backup_ride_hailing.sql | docker exec -i mysql8 mysql -uroot -prootpass
```

Extraer del `binlog` los cambios hasta el punto de recuperación deseado:

```bash
docker exec mysql8 mysqlbinlog \
  --start-datetime="<fecha_hora_inicio>" \
  --stop-datetime="<fecha_hora_fin>" \
  /var/lib/mysql/mysql-bin.000001 > cambios.sql
```

Aplicar los cambios extraídos:

```bash
cat cambios.sql | docker exec -i mysql8 mysql -uroot -prootpass
```

### 8.4 Buscar una operación en el binlog

Para localizar una operación concreta en el `binlog`:

```bash
docker exec mysql8 mysqlbinlog \
  --start-datetime="<fecha_hora_inicio>" \
  --stop-datetime="<fecha_hora_fin>" \
  /var/lib/mysql/mysql-bin.000001 | grep -A5 -B5 "<operacion>"
```

También se puede extraer un tramo concreto por posiciones:

```bash
docker exec mysql8 mysqlbinlog \
  --start-position=<posicion_inicio> \
  --stop-position=<posicion_fin> \
  /var/lib/mysql/mysql-bin.000001 > cambios.sql
```

### 8.5 Snapshot consistente

Los snapshots pueden ser inconsistentes si MySQL está escribiendo. Para coordinarlos, se puede bloquear brevemente la lectura de tablas.

En MySQL:

```sql
FLUSH TABLES WITH READ LOCK;
```

Después se toma el snapshot desde la infraestructura correspondiente.

Al terminar:

```sql
UNLOCK TABLES;
```

En esta práctica el método principal sigue siendo `mysqldump`.

### 8.6 Script de backup con rotación

Otra opción es crear un archivo `backup_mysql.sh` para hacer un backup programado:

```bash
#!/bin/bash

FECHA=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/mysql"
RETENTION_DAYS=7

mkdir -p "${BACKUP_DIR}"

docker exec mysql8 mysqldump \
  -ubackup_user -p'<password_backup>' \
  --databases ride_hailing \
  --single-transaction \
  --routines --triggers --events \
  --set-gtid-purged=OFF \
  | gzip > "${BACKUP_DIR}/backup_ride_hailing_${FECHA}.sql.gz"

if [ $? -eq 0 ]; then
  echo "Backup creado correctamente"
else
  echo "ERROR: Backup falló" >&2
  exit 1
fi

find "${BACKUP_DIR}" -name "backup_ride_hailing_*.sql.gz" -mtime +${RETENTION_DAYS} -delete
```

Programar backup diario:

```bash
crontab -e
```

Añadir:

```bash
0 3 * * * /scripts/backup_mysql.sh >> /var/log/mysql_backup.log 2>&1
```

## 9. Parar o borrar el entorno

### 9.1 Parar el proyecto sin borrar datos

En Bash/PowerShell:

```bash
docker compose down
```

Los datos se conservan porque están guardados en el volumen de Docker.

### 9.2 Borrar contenedor y datos

En Bash/Powershell:

```bash
docker compose down -v
```

Esto elimina también el volumen de datos. Después será necesario volver a cargar:

```text
schema.sql
data.sql
permissions.sql
```

## 10. Iniciar la práctica desde cero

En Bash:

```bash
docker compose down -v
docker compose up -d
docker exec -i mysql8 mysql -uroot -prootpass < sql/schema.sql
docker exec -i mysql8 mysql -uroot -prootpass < sql/data.sql
docker exec -i mysql8 mysql -uroot -prootpass < sql/permissions.sql
docker exec -i mysql8 mysql -uroot -prootpass < sql/queries.sql
docker exec -i mysql8 mysql -uroot -prootpass < sql/dashboard.sql
```

En PowerShell:

```powershell
docker compose down -v
docker compose up -d
Get-Content -Raw .\sql\schema.sql | docker exec -i mysql8 mysql -uroot -prootpass
Get-Content -Raw .\sql\data.sql | docker exec -i mysql8 mysql -uroot -prootpass
Get-Content -Raw .\sql\permissions.sql | docker exec -i mysql8 mysql -uroot -prootpass
Get-Content -Raw .\sql\queries.sql | docker exec -i mysql8 mysql -uroot -prootpass
Get-Content -Raw .\sql\dashboard.sql | docker exec -i mysql8 mysql -uroot -prootpass
```