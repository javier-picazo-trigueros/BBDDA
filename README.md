# README — Ride-Hailing Database

## Estructura del proyecto

```
Practica1/
├── compose.yml                  # Docker: MySQL
├── schema.sql                   # DDL: tablas, índices, vistas
├── data.sql                     # Datos de prueba (carga masiva)
├── queries.sql                  # Consultas operativas + stored procedures
├── dashboard.sql                # Consultas para dashboards (BD y negocio)
├── backup.sql                   # Plan de backup y verificación post-restore
├── permissions.sql              # Usuarios, roles y permisos
├── triggers_auditoria.sql       # Triggers de auditoría
├── backup_mysql.sh              # Script de backup diario automatizado
├── DESIGN.md                    # Diseño, MER y decisiones técnicas
├── README.md                    # Este archivo
├── mysql/
│   ├── conf.d/
│   │   └── custom.cnf           # Configuración MySQL (binlog, slow log...)
│   └── init/                    # Scripts ejecutados automáticamente al arrancar
│       ├── 01_schema.sql
│       ├── 02_permissions.sql
│       └── 03_data.sql
├── scripts/
│   └── backup_mysql.sh          # Script de backup diario
└── backups/                     # Directorio donde se guardan los backups
```

---

## Requisitos

- Docker Desktop ≥ 24
- Puerto 3306 libre en el host

---

## Arranque rápido (primera vez)

```powershell
docker compose up -d
```

MySQL ejecuta automáticamente los scripts de `mysql/init/` en orden al primer arranque.
Esperar ~30 segundos y verificar:

```powershell
docker compose ps
```

Debe aparecer `mysql8` con estado `Up (healthy)`.

---

## Verificar carga de datos

```powershell
docker exec -it mysql8 mysql -uroot -prootpass ridehailing -e "
SELECT 'company'    AS tabla, COUNT(*) AS filas FROM company    UNION ALL
SELECT 'usuario',   COUNT(*) FROM usuario   UNION ALL
SELECT 'conductor', COUNT(*) FROM conductor UNION ALL
SELECT 'vehiculo',  COUNT(*) FROM vehiculo  UNION ALL
SELECT 'viaje',     COUNT(*) FROM viaje     UNION ALL
SELECT 'oferta',    COUNT(*) FROM oferta    UNION ALL
SELECT 'pago',      COUNT(*) FROM pago;
"
```

---

## Cargar datos manualmente (si el volumen ya existía)

En PowerShell usar `Get-Content` en lugar de `<`:

```powershell
Get-Content mysql\init\01_schema.sql      | docker exec -i mysql8 mysql -uroot -prootpass
Get-Content mysql\init\02_permissions.sql | docker exec -i mysql8 mysql -uroot -prootpass
Get-Content mysql\init\03_data.sql        | docker exec -i mysql8 mysql -uroot -prootpass
```

---

## Ejecutar consultas

```powershell
# Consultas operativas
Get-Content queries.sql    | docker exec -i mysql8 mysql -uroot -prootpass ridehailing

# Dashboard (métricas de BD y negocio)
Get-Content dashboard.sql  | docker exec -i mysql8 mysql -uroot -prootpass ridehailing

# Triggers de auditoría
Get-Content triggers_auditoria.sql | docker exec -i mysql8 mysql -uroot -prootpass ridehailing

# Verificación post-backup
Get-Content backup.sql     | docker exec -i mysql8 mysql -uroot -prootpass ridehailing
```

---

## Acceso a MySQL

| Método | Conexión | Usuario | Contraseña |
|--------|----------|---------|------------|
| Terminal | `docker exec -it mysql8 mysql -uroot -prootpass` | root | rootpass |
| Workbench / DBeaver | localhost:3306 | root | rootpass |
| API app | localhost:3306 | api_app | ApiApp_S3cur3! |

---

## Backup manual

```powershell
# Ejecutar desde Git Bash o WSL (el script es bash)
bash scripts/backup_mysql.sh

# Ver backups generados
ls backups/
```

El script genera un `.sql.gz` con fecha en `backups/` y elimina automáticamente
los backups con más de 7 días.

---

## Parar y limpiar

```powershell
# Parar sin borrar datos
docker compose down

# Parar y borrar todos los datos (¡destruye el volumen!)
docker compose down -v
```
