### Practica Ride Hailing - BBDD Avanazadas
### Autores: Javier Picazo, Alejandro Bernaldo de Quiros, Pablo Cerdeira y Jaime Ordovas
### Grupo: 3A

---

# Ride-Hailing Database

Base de datos relacional para una plataforma de ride-hailing sobre MySQL 8.0.

## Estructura del repositorio

```text
.
|- backup.sql
|- compose.yml
|- dashboard.sql
|- data.sql
|- DESIGN.md
|- permissions.sql
|- queries.sql
|- README.md
|- schema.sql
|- backups/
`- mysql/
   `- conf.d/
      `- custom.cnf
```

## Requisitos

- Docker y Docker Compose instalados

## Arrancar la base de datos

```bash
docker compose up -d
docker compose ps
docker exec -it ridehailing-db mysql -uroot -prootpass ridehailing
```

La primera vez que se levanta el contenedor, Docker ejecuta automaticamente estos
scripts en este orden:

1. `schema.sql`: crea la base de datos, tablas, indices, vistas, stored procedures y triggers.
2. `permissions.sql`: crea roles, usuarios y permisos.
3. `data.sql`: inserta los datos de prueba.

Los scripts de inicializacion solo se ejecutan si el volumen `mysql_data` esta vacio.
Para reiniciar desde cero:

```bash
docker compose down -v
docker compose up -d
```

## Ejecutar dashboards y consultas

```bash
docker exec -i ridehailing-db mysql -uroot -prootpass ridehailing < dashboard.sql
docker exec -i ridehailing-db mysql -uroot -prootpass ridehailing < queries.sql
```

`queries.sql` ya no define objetos del esquema: contiene operaciones de ejemplo,
llamadas de prueba a los stored procedures y consultas de negocio.

## Probar la concurrencia y el ciclo de vida

Sobre una base recien cargada con `data.sql`, podeis probar esta secuencia:

```sql
USE ridehailing;

CALL sp_aceptar_oferta(1, 22, @resultado);
SELECT @resultado;

CALL sp_iniciar_viaje(61, 22, @resultado);
SELECT @resultado;

CALL sp_finalizar_viaje(61, 8.500, 18.25, @resultado);
SELECT @resultado;
```

## Backup y restore

```bash
docker exec ridehailing-db mysqldump \
  -uroot -prootpass \
  --databases ridehailing \
  --single-transaction \
  --routines --triggers --events \
  --set-gtid-purged=OFF \
  | gzip > backups/backup_$(date +%Y%m%d_%H%M%S).sql.gz

zcat backups/backup_YYYYMMDD.sql.gz | \
  docker exec -i ridehailing-db mysql -uroot -prootpass
```

## Conectarse con distintos usuarios

```bash
docker exec -it ridehailing-db mysql -uapi_app -p'ApiApp_S3cur3!' ridehailing
docker exec -it ridehailing-db mysql -ubi_reports -p'BiReports_R3ad0nly!' ridehailing
```

## Parar y limpiar

```bash
docker compose down
docker compose down -v
```
