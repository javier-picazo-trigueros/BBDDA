### Practica Ride Hailing - BBDD Avanazadas
### Autores: Javier Picazo, Alejandro Bernaldo de Quiros, Pablo Cerdeira y Jaime Ordovás
### Grupo: 3A

---

# Ride-Hailing Database
Base de datos relacional para una plataforma de ride-hailing sobre MySQL 8.0.

## Estructura del repositorio
├── init/
│   └── schema.sql        # Creacion de BD, tablas, indices, vistas y triggers
│   └── permissions.sql   # Roles, usuarios y permisos
│   └── data.sql          # Carga masiva de datos de prueba
├── .gitignore
├── backup.sql            # Plan de backup, verificacion y comandos PITR
├── compose.yml           # Docker Compose para despliegue
├── dashboard.sql         # Dashboards de BD y de negocio
├── mysql/
│   └── custom.cnf        # Configuracion de MySQL
├── DESIGN.md             # Diseño con Mermaid, decisiones, indices
├── queries.sql           # Consultas operativas, SPs con locks y transacciones
├── README.md             # Detalles e instrucciones de arranque y funcionamiento
└── presentacion.pdf      # Presentacion para la defensa

## Requisitos
- Docker y Docker Compose instalados

## Arrancar la base de datos
```bash
# 1. Levantar el contenedor (primera vez carga schema + datos automaticamente)
docker compose up -d

# 2. Verificar que esta sano
docker compose ps

# 3. Conectarse a MySQL
docker exec -it ridehailing-db mysql -uroot -prootpass ridehailing
```

La primera vez que se levanta el contenedor, Docker ejecuta automaticamente en orden:
1. `schema.sql` — Crea la BD `ridehailing`, tablas, indices, vistas y triggers.
2. `data.sql` — Inserta datos de prueba (5 companies, 30 usuarios, 10 vehículos, 60+ viajes, ofertas y pagos).
3. `permissions.sql` — Crea roles y usuarios de BD.

Los scripts de init solo se ejecutan si el volumen `mysql_data` está vacio. Para reiniciar desde cero: `docker compose down -v && docker compose up -d`.

## Ejecutar dashboards
```bash
# Dashboard de metricas de base de datos
docker exec -i ridehailing-db mysql -uroot -prootpass ridehailing < dashboard.sql

# Consultas operativas
docker exec -i ridehailing-db mysql -uroot -prootpass ridehailing < queries.sql
```

## Probar la concurrencia (aceptar oferta)
```sql
-- Conectarse a MySQL y ejecutar:
USE ridehailing;

-- Aceptar la oferta 1 por el conductor 21 (del 1 al 20 son riders)
CALL sp_aceptar_oferta(1, 21, @resultado);
SELECT @resultado;
```

## Backup y restore
```bash
# Backup completo
docker exec ridehailing-db mysqldump \
  -uroot -prootpass \
  --databases ridehailing \
  --single-transaction \
  --routines --triggers --events \
  --set-gtid-purged=OFF \
  | gzip > backups/backup_$(date +%Y%m%d_%H%M%S).sql.gz

# Restore
zcat backups/backup_YYYYMMDD.sql.gz | \
  docker exec -i ridehailing-db mysql -uroot -prootpass
```

## Conectarse con distintos usuarios
```bash
# API backend (lectura + escritura operativa)
docker exec -it ridehailing-db mysql -uapi_app -p'ApiApp_S3cur3!' ridehailing

# Reporting (solo lectura sobre vistas)
docker exec -it ridehailing-db mysql -ubi_reports -p'BiReports_R3ad0nly!' ridehailing
```

## Parar y limpiar
```bash
# Parar (conserva datos)
docker compose down

# Parar y borrar datos (siguiente up recarga todo desde cero)
docker compose down -v
```