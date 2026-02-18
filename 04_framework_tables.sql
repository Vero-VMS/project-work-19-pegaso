-- =========================================================
-- 04_framework_tables.sql
-- Framework Nazionale - Profili (CURRENT/TARGET) e Assessment
-- Estensione: assessment su ASSET e su SERVICE
-- Target: PostgreSQL
-- =========================================================

-- ---------------------------------------------------------
-- 1) Subcategory (Framework Core) - elenco requisiti
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS fw_subcategory (
  subcategory_id BIGSERIAL PRIMARY KEY,
  code           VARCHAR(20) NOT NULL UNIQUE,  -- es. PR.AC-1
  name           VARCHAR(200) NOT NULL,
  description    TEXT,
  function_code  VARCHAR(5)  NOT NULL,         -- ID, PR, DE, RS, RC
  category_code  VARCHAR(20) NOT NULL          -- es. PR.AC
);

CREATE INDEX IF NOT EXISTS idx_fw_subcategory_function ON fw_subcategory(function_code);
CREATE INDEX IF NOT EXISTS idx_fw_subcategory_category  ON fw_subcategory(category_code);

-- ---------------------------------------------------------
-- 2) Controlli - misure concrete
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS fw_control (
  control_id   BIGSERIAL PRIMARY KEY,
  code         VARCHAR(30) NOT NULL UNIQUE,   -- es. CTRL-IAM
  name         VARCHAR(200) NOT NULL,
  description  TEXT
);

-- ---------------------------------------------------------
-- 3) Mapping controllo <-> subcategory (molti-a-molti)
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS fw_control_subcategory (
  control_id     BIGINT NOT NULL REFERENCES fw_control(control_id) ON DELETE CASCADE,
  subcategory_id BIGINT NOT NULL REFERENCES fw_subcategory(subcategory_id) ON DELETE CASCADE,
  PRIMARY KEY (control_id, subcategory_id)
);

CREATE INDEX IF NOT EXISTS idx_fw_ctrl_subcat_subcat ON fw_control_subcategory(subcategory_id);

-- ---------------------------------------------------------
-- 4) Profilo (CURRENT / TARGET) per azienda
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS fw_profile (
  profile_id   BIGSERIAL PRIMARY KEY,
  company_id   BIGINT NOT NULL REFERENCES company(company_id) ON DELETE CASCADE,
  profile_type VARCHAR(10) NOT NULL CHECK (profile_type IN ('CURRENT','TARGET')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  notes        TEXT,
  CONSTRAINT uq_fw_profile_company_type UNIQUE (company_id, profile_type)
);

CREATE INDEX IF NOT EXISTS idx_fw_profile_company ON fw_profile(company_id);

-- ---------------------------------------------------------
-- 5) Assessment su ASSET: asset <-> controllo in un profilo
-- coverage: 0..1 step 0.2
-- maturity: 1..5, NULL se coverage=0
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS fw_asset_control_assessment (
  assessment_id BIGSERIAL PRIMARY KEY,
  profile_id    BIGINT NOT NULL REFERENCES fw_profile(profile_id) ON DELETE CASCADE,
  asset_id      BIGINT NOT NULL REFERENCES asset(asset_id) ON DELETE CASCADE,
  control_id    BIGINT NOT NULL REFERENCES fw_control(control_id) ON DELETE CASCADE,

  coverage      NUMERIC(2,1) NOT NULL
               CHECK (coverage IN (0.0,0.2,0.4,0.6,0.8,1.0)),

  maturity      SMALLINT NULL
               CHECK (maturity BETWEEN 1 AND 5),

  notes         TEXT,
  evidence      TEXT,
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_fw_asset_assessment UNIQUE (profile_id, asset_id, control_id),
  CONSTRAINT ck_fw_asset_cov_mat CHECK (
    (coverage = 0.0 AND maturity IS NULL)
    OR
    (coverage > 0.0 AND maturity IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_fw_asset_assessment_profile ON fw_asset_control_assessment(profile_id);
CREATE INDEX IF NOT EXISTS idx_fw_asset_assessment_asset   ON fw_asset_control_assessment(asset_id);
CREATE INDEX IF NOT EXISTS idx_fw_asset_assessment_control ON fw_asset_control_assessment(control_id);

-- ---------------------------------------------------------
-- 6) Assessment su SERVICE: service <-> controllo in un profilo
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS fw_service_control_assessment (
  assessment_id BIGSERIAL PRIMARY KEY,
  profile_id    BIGINT NOT NULL REFERENCES fw_profile(profile_id) ON DELETE CASCADE,
  service_id    BIGINT NOT NULL REFERENCES service(service_id) ON DELETE CASCADE,
  control_id    BIGINT NOT NULL REFERENCES fw_control(control_id) ON DELETE CASCADE,

  coverage      NUMERIC(2,1) NOT NULL
               CHECK (coverage IN (0.0,0.2,0.4,0.6,0.8,1.0)),

  maturity      SMALLINT NULL
               CHECK (maturity BETWEEN 1 AND 5),

  notes         TEXT,
  evidence      TEXT,
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_fw_service_assessment UNIQUE (profile_id, service_id, control_id),
  CONSTRAINT ck_fw_service_cov_mat CHECK (
    (coverage = 0.0 AND maturity IS NULL)
    OR
    (coverage > 0.0 AND maturity IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_fw_service_assessment_profile ON fw_service_control_assessment(profile_id);
CREATE INDEX IF NOT EXISTS idx_fw_service_assessment_service ON fw_service_control_assessment(service_id);
CREATE INDEX IF NOT EXISTS idx_fw_service_assessment_control ON fw_service_control_assessment(control_id);

-- ---------------------------------------------------------
-- 7) Trigger: coerenza company tra profilo e asset
-- ---------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_fw_validate_asset_company()
RETURNS TRIGGER AS $$
DECLARE
  v_profile_company BIGINT;
  v_asset_company   BIGINT;
BEGIN
  SELECT company_id INTO v_profile_company
  FROM fw_profile
  WHERE profile_id = NEW.profile_id;

  SELECT company_id INTO v_asset_company
  FROM asset
  WHERE asset_id = NEW.asset_id;

  IF v_profile_company IS NULL THEN
    RAISE EXCEPTION 'fw_profile % non trovato', NEW.profile_id;
  END IF;

  IF v_asset_company IS NULL THEN
    RAISE EXCEPTION 'asset % non trovato', NEW.asset_id;
  END IF;

  IF v_profile_company <> v_asset_company THEN
    RAISE EXCEPTION
      'Incoerenza company: profilo company_id=% ma asset company_id=%',
      v_profile_company, v_asset_company;
  END IF;

  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_fw_validate_asset_company ON fw_asset_control_assessment;

CREATE TRIGGER trg_fw_validate_asset_company
BEFORE INSERT OR UPDATE ON fw_asset_control_assessment
FOR EACH ROW
EXECUTE FUNCTION fn_fw_validate_asset_company();

-- ---------------------------------------------------------
-- 8) Trigger: coerenza company tra profilo e service
-- ---------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_fw_validate_service_company()
RETURNS TRIGGER AS $$
DECLARE
  v_profile_company BIGINT;
  v_service_company BIGINT;
BEGIN
  SELECT company_id INTO v_profile_company
  FROM fw_profile
  WHERE profile_id = NEW.profile_id;

  SELECT company_id INTO v_service_company
  FROM service
  WHERE service_id = NEW.service_id;

  IF v_profile_company IS NULL THEN
    RAISE EXCEPTION 'fw_profile % non trovato', NEW.profile_id;
  END IF;

  IF v_service_company IS NULL THEN
    RAISE EXCEPTION 'service % non trovato', NEW.service_id;
  END IF;

  IF v_profile_company <> v_service_company THEN
    RAISE EXCEPTION
      'Incoerenza company: profilo company_id=% ma service company_id=%',
      v_profile_company, v_service_company;
  END IF;

  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_fw_validate_service_company ON fw_service_control_assessment;

CREATE TRIGGER trg_fw_validate_service_company
BEFORE INSERT OR UPDATE ON fw_service_control_assessment
FOR EACH ROW
EXECUTE FUNCTION fn_fw_validate_service_company();

