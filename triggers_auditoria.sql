-- ============================================================
-- triggers_auditoria.sql  —  Triggers de auditoría
-- Se pueden añadir al final de schema.sql
-- ============================================================

USE ridehailing;

DELIMITER $$

-- Auditar cambios de estado en viaje
DROP TRIGGER IF EXISTS trg_viaje_audit_update$$
CREATE TRIGGER trg_viaje_audit_update
AFTER UPDATE ON viaje
FOR EACH ROW
BEGIN
  IF NOT (OLD.estado <=> NEW.estado) THEN
    INSERT INTO auditoria (tabla, operacion, id_registro, campo, valor_old, valor_new, usuario_bd)
    VALUES ('viaje', 'UPDATE', NEW.id_viaje, 'estado', OLD.estado, NEW.estado, USER());
  END IF;
END$$

-- Auditar INSERT de ofertas
DROP TRIGGER IF EXISTS trg_oferta_audit_insert$$
CREATE TRIGGER trg_oferta_audit_insert
AFTER INSERT ON oferta
FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, campo, valor_new, usuario_bd)
  VALUES ('oferta', 'INSERT', NEW.id_oferta, 'estado', NEW.estado, USER());
END$$

-- Auditar cambio de estado de oferta
DROP TRIGGER IF EXISTS trg_oferta_audit_update$$
CREATE TRIGGER trg_oferta_audit_update
AFTER UPDATE ON oferta
FOR EACH ROW
BEGIN
  IF NOT (OLD.estado <=> NEW.estado) THEN
    INSERT INTO auditoria (tabla, operacion, id_registro, campo, valor_old, valor_new, usuario_bd)
    VALUES ('oferta', 'UPDATE', NEW.id_oferta, 'estado', OLD.estado, NEW.estado, USER());
  END IF;
END$$

DELIMITER ;
