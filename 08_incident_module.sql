-- =========================================================
-- 08_incident_module.sql
-- Estensione NIS2: gestione incidenti + obblighi di notifica
-- Target: PostgreSQL
-- =========================================================

-- ---------------------------------------------------------
-- A) Incident (evento di sicurezza)
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS incident (
  incident_id     BIGSERIAL PRIMARY KEY,
  company_id      BIGINT NOT NULL REFERENCES company(company_id) ON DELETE CASCADE,

  incident_code   VARCHAR(30) NOT NULL,
  title           VARCHAR(200) NOT NULL,
  description     TEXT,

  detected_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  occurred_at     TIMESTAMPTZ NULL,
  closed_at       TIMESTAMPTZ NULL,

  severity        VARCHAR(10) NOT NULL CHECK (severity IN ('LOW','MEDIUM','HIGH','CRITICAL')),
  status          VARCHAR(20) NOT NULL CHECK (status IN ('OPEN','UNDER_ANALYSIS','CONTAINED','RESOLVED','CLOSED')),

  is_significant  BOOLEAN NOT NULL DEFAULT FALSE,  -- incidente "significativo" ai fini NIS2 (flag)
  notes           TEXT,

  CONSTRAINT uq_incident_company_code UNIQUE (company_id, incident_code),
  CONSTRAINT ck_incident_dates CHECK (
    (closed_at IS NULL) OR (closed_at >= detected_at)
  )
);

CREATE INDEX IF NOT EXISTS idx_incident_company   ON incident(company_id);
CREATE INDEX IF NOT EXISTS idx_incident_status    ON incident(status);
CREATE INDEX IF NOT EXISTS idx_incident_detected  ON incident(detected_at);

-- ---------------------------------------------------------
-- B) Collegamento Incident <-> Asset (N-M)
-- (stesso incidente può impattare più asset e viceversa)
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS incident_asset (
  incident_id BIGINT NOT NULL REFERENCES incident(incident_id) ON DELETE CASCADE,
  asset_id    BIGINT NOT NULL REFERENCES asset(asset_id) ON DELETE CASCADE,

  impact_type VARCHAR(20) NULL CHECK (impact_type IN ('CONFIDENTIALITY','INTEGRITY','AVAILABILITY','OTHER')),
  impact_notes TEXT,

  PRIMARY KEY (incident_id, asset_id)
);

CREATE INDEX IF NOT EXISTS idx_incident_asset_asset ON incident_asset(asset_id);

-- ---------------------------------------------------------
-- C) Notifiche verso autorità (early warning / 72h / final)
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS incident_notification (
  notification_id   BIGSERIAL PRIMARY KEY,
  incident_id       BIGINT NOT NULL REFERENCES incident(incident_id) ON DELETE CASCADE,

  notification_type VARCHAR(12) NOT NULL CHECK (notification_type IN ('EARLY_24H','FULL_72H','FINAL_1M')),
  authority         VARCHAR(80) NOT NULL DEFAULT 'ACN',

  status            VARCHAR(12) NOT NULL CHECK (status IN ('DRAFT','SENT','ACKNOWLEDGED','CANCELLED')),
  due_at            TIMESTAMPTZ NULL,
  sent_at           TIMESTAMPTZ NULL,

  reference_code    VARCHAR(80) NULL,  -- eventuale protocollo/ID comunicazione
  content_summary   TEXT NULL,

  CONSTRAINT uq_incident_notification UNIQUE (incident_id, notification_type),
  CONSTRAINT ck_notification_dates CHECK (
    (sent_at IS NULL) OR (due_at IS NULL) OR (sent_at >= (due_at - INTERVAL '365 days'))
  )
);

CREATE INDEX IF NOT EXISTS idx_inc_notif_incident ON incident_notification(incident_id);
CREATE INDEX IF NOT EXISTS idx_inc_notif_status   ON incident_notification(status);
CREATE INDEX IF NOT EXISTS idx_inc_notif_due      ON incident_notification(due_at);

-- ---------------------------------------------------------
-- D) Trigger coerenza company: incident_asset deve rispettare company
-- ---------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_incident_validate_asset_company()
RETURNS TRIGGER AS $$
DECLARE
  v_inc_company BIGINT;
  v_asset_company BIGINT;
BEGIN
  SELECT company_id INTO v_inc_company
  FROM incident
  WHERE incident_id = NEW.incident_id;

  SELECT company_id INTO v_asset_company
  FROM asset
  WHERE asset_id = NEW.asset_id;

  IF v_inc_company IS NULL THEN
    RAISE EXCEPTION 'incident % non trovato', NEW.incident_id;
  END IF;

  IF v_asset_company IS NULL THEN
    RAISE EXCEPTION 'asset % non trovato', NEW.asset_id;
  END IF;

  IF v_inc_company <> v_asset_company THEN
    RAISE EXCEPTION
      'Incoerenza company: incident company_id=% ma asset company_id=%',
      v_inc_company, v_asset_company;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_incident_validate_asset_company ON incident_asset;

CREATE TRIGGER trg_incident_validate_asset_company
BEFORE INSERT OR UPDATE ON incident_asset
FOR EACH ROW
EXECUTE FUNCTION fn_incident_validate_asset_company();
