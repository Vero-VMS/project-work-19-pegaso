-- =========================================================
-- PW19 - Versioning/Storico Asset
-- File: 02_triggers_versioning.sql
-- Scopo: mantenere storico asset ad ogni UPDATE
-- =========================================================

-- Funzione: aggiorna updated_at e salva la versione precedente in asset_history
CREATE OR REPLACE FUNCTION fn_asset_versioning()
RETURNS TRIGGER AS $$
BEGIN
  -- Chiude la versione precedente nello storico (se esiste una "aperta")
  UPDATE asset_history
    SET valid_to = now()
  WHERE asset_id = OLD.asset_id
    AND valid_to IS NULL;

  -- Inserisce snapshot della riga precedente
  INSERT INTO asset_history (
    asset_id, company_id, asset_code, name, asset_type, description, location,
    owner_contact_id, criticality, status,
    valid_from, valid_to, changed_by, change_reason
  )
  VALUES (
    OLD.asset_id, OLD.company_id, OLD.asset_code, OLD.name, OLD.asset_type, OLD.description, OLD.location,
    OLD.owner_contact_id, OLD.criticality, OLD.status,
    OLD.updated_at, NULL, current_user, 'UPDATE asset'
  );

  -- Aggiorna timestamp riga corrente
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_asset_versioning ON asset;

CREATE TRIGGER trg_asset_versioning
BEFORE UPDATE ON asset
FOR EACH ROW
EXECUTE FUNCTION fn_asset_versioning();


-- (Opzionale) trigger per aggiornare updated_at anche sui servizi
CREATE OR REPLACE FUNCTION fn_touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_service_touch ON service;

CREATE TRIGGER trg_service_touch
BEFORE UPDATE ON service
FOR EACH ROW
EXECUTE FUNCTION fn_touch_updated_at();

