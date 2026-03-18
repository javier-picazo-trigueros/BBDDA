# README — Ride-Hailing Database

## Estructura del proyecto

```
ride-hailing-db/
├── compose.yml                    # Docker: MySQL + Prometheus + Grafana
├── schema.sql                     # DDL: tablas, índices, vistas
├── data.sql                       # Datos de prueba
├── queries.sql                    # Consultas operativas + stored procedures
├── dashboard.sql                  # Consultas para dashboards
├── backup.sql                     # Plan de backup / verificación post-restore
├── permissions.sql                # Usuarios y permisos
├── DESIGN.md                      # Diseño y MER
├── mysql/
│   └── conf.d/
│       └── custom.cnf             # Configuración MySQL (binlog, slow log, etc.)
├── mysql/init/                    # Scripts ejecutados automáticamente al arrancar
├── monitoring/
│   └── prometheus.yml             # Configuración de Prometheus
├── scripts/
│   └── backup_mysql.sh            # Script de backup diario
└── backups/                       # Directorio de backups (creado automáticamente)
```

---

## Requisitos

- Docker Desktop ≥ 24 (o Docker Engine + Compose plugin)
- Puerto 3306, 3000, 9090, 9104 libres en el host

---

## Arranque rápido

### 1. Copiar los scripts de inicialización

```bash
cp schema.sql      mysql/init/01_schema.sql
cp permissions.sql mysql/init/02_permissions.sql
cp data.sql        mysql/init/03_data.sql
```

> MySQL ejecuta automáticamente todos los `.sql` de `mysql/init/` en orden alfabético al primer arranque.

### 2. Levantar los servicios

```bash
docker compose up -d
```

Esperar a que MySQL esté listo (health check):

```bash
docker compose ps          # verificar estado
docker compose logs -f mysql  # ver logs en tiempo real
```

### 3. Verificar la carga de datos

```bash
docker exec -it mysql8 mysql -uroot -prootpass ridehailing \
  -e "SELECT COUNT(*) FROM viaje;"
```

---

## Acceso a los servicios

| Servicio | URL / Conexión | Credenciales |
|----------|----------------|-------------|
| MySQL | `localhost:3306` | root / rootpass |
| Grafana | http://localhost:3000 | admin / grafana_pass |
| Prometheus | http://localhost:9090 | — |
| mysqld_exporter | http://localhost:9104/metrics | — |

---

## Cargar datos de prueba manualmente

Si no usas la inicialización automática:

```bash
# Crear esquema
docker exec -i mysql8 mysql -uroot -prootpass < schema.sql

# Crear usuarios y permisos
docker exec -i mysql8 mysql -uroot -prootpass < permissions.sql

# Cargar datos
docker exec -i mysql8 mysql -uroot -prootpass < data.sql
```

---

## Ejecutar consultas

```bash
# Consultas operativas
docker exec -i mysql8 mysql -uroot -prootpass < queries.sql

# Dashboard
docker exec -i mysql8 mysql -uroot -prootpass ridehailing < dashboard.sql

# Verificación post-backup
docker exec -i mysql8 mysql -uroot -prootpass ridehailing < backup.sql
```

---

## Configurar dashboard en Grafana

1. Abrir http://localhost:3000 (admin / grafana_pass)
2. **Configuration → Data Sources → Add data source → Prometheus**
   - URL: `http://prometheus:9090`
   - Save & Test
3. **Dashboards → Import → ID: `7362`** (MySQL Overview)
4. Seleccionar Prometheus como data source → Import

Para el dashboard de negocio, ejecutar `dashboard.sql` directamente en MySQL Workbench o DBeaver conectado a `localhost:3306`.

---

## Backup manual

```bash
# Ejecutar backup ahora
bash scripts/backup_mysql.sh

# Ver backups disponibles
ls -lh backups/
```

Para programar el backup diario en cron (desde el host):

```bash
crontab -e
# Añadir:
0 3 * * * cd /ruta/a/ride-hailing-db && bash scripts/backup_mysql.sh >> /var/log/ridehailing_backup.log 2>&1
```

---

## Parar y limpiar

```bash
# Parar sin borrar datos
docker compose down

# Parar y borrar todos los datos (¡cuidado!)
docker compose down -v
```
