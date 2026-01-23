-- =========================================================
-- PW19 - NIS2/ACN Registry (PostgreSQL)
-- File: 01_create_tables.sql
-- Scopo: creare schema relazionale, vincoli e indici
-- =========================================================

-- Pulizia (necessaria in caso venga rieseguito)
DROP TABLE IF EXISTS service_provider CASCADE;
DROP TABLE IF EXISTS service_asset CASCADE;
DROP TABLE IF EXISTS asset_history CASCADE;
DROP TABLE IF EXISTS service CASCADE;
DROP TABLE IF EXISTS asset CASCADE;
DROP TABLE IF EXISTS provider CASCADE;
DROP TABLE IF EXISTS contact CASCADE;
DROP TABLE IF EXISTS company CASCADE;

-- =========================================================
-- 1) AZIENDA
-- =========================================================
CREATE TABLE company (
  company_id      BIGSERIAL PRIMARY KEY,
  name            VARCHAR(200) NOT NULL,
  vat_number      VARCHAR(32),
  sector          VARCHAR(120),
  country         VARCHAR(80) DEFAULT 'Italia',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_company_name ON company (name);

-- =========================================================
-- 2) CONTATTI / RESPONSABILI
-- =========================================================
CREATE TABLE contact (
  contact_id      BIGSERIAL PRIMARY KEY,
  company_id      BIGINT NOT NULL REFERENCES company(company_id) ON DELETE CASCADE,
  full_name       VARCHAR(150) NOT NULL,
  role_title      VARCHAR(150) NOT NULL,        -- es. IT Manager, CISO, Service Owner
  email           VARCHAR(200),
  phone           VARCHAR(50),
  is_primary_poc  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_contact_company ON contact(company_id);
CREATE INDEX idx_contact_role ON contact(role_title);

-- =========================================================
-- 3) FORNITORI TERZI
-- =========================================================
CREATE TABLE provider (
  provider_id     BIGSERIAL PRIMARY KEY,
  name            VARCHAR(200) NOT NULL,
  provider_type   VARCHAR(120),                 -- es. Cloud provider, ISP, Software house
  country         VARCHAR(80),
  email           VARCHAR(200),
  phone           VARCHAR(50),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_provider_name ON provider(name);

-- =========================================================
-- 4) ASSET
-- =========================================================
CREATE TABLE asset (
  asset_id        BIGSERIAL PRIMARY KEY,
  company_id      BIGINT NOT NULL REFERENCES company(company_id) ON DELETE CASCADE,
  asset_code      VARCHAR(40) NOT NULL,         -- codice interno (es. SRV-001)
  name            VARCHAR(200) NOT NULL,        -- es. "DB Produzione"
  asset_type      VARCHAR(60) NOT NULL,         -- HARDWARE / SOFTWARE / NETWORK / CLOUD / OTHER
  description     TEXT,
  location        VARCHAR(200),                 -- es. "Data Center Milano" o "Cloud EU-West"
  owner_contact_id BIGINT REFERENCES contact(contact_id) ON DELETE SET NULL,
  criticality     SMALLINT NOT NULL DEFAULT 3 CHECK (criticality BETWEEN 1 AND 5),  -- 1=bassa, 5=alta
  status          VARCHAR(30) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE','RETIRED')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_asset_company_code UNIQUE (company_id, asset_code)
);

CREATE INDEX idx_asset_company ON asset(company_id);
CREATE INDEX idx_asset_owner ON asset(owner_contact_id);
CREATE INDEX idx_asset_criticality ON asset(criticality);

-- =========================================================
-- 5) SERVIZI
-- =========================================================
CREATE TABLE service (
  service_id      BIGSERIAL PRIMARY KEY,
  company_id      BIGINT NOT NULL REFERENCES company(company_id) ON DELETE CASCADE,
  service_code    VARCHAR(40) NOT NULL,         -- es. SVC-CRM
  name            VARCHAR(200) NOT NULL,        -- es. "Portale Clienti"
  description     TEXT,
  service_owner_contact_id BIGINT REFERENCES contact(contact_id) ON DELETE SET NULL,
  criticality     SMALLINT NOT NULL DEFAULT 3 CHECK (criticality BETWEEN 1 AND 5),
  status          VARCHAR(30) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE','RETIRED')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_service_company_code UNIQUE (company_id, service_code)
);

CREATE INDEX idx_service_company ON service(company_id);
CREATE INDEX idx_service_owner ON service(service_owner_contact_id);
CREATE INDEX idx_service_criticality ON service(criticality);

-- =========================================================
-- 6) RELAZIONE SERVIZIO <-> ASSET (molti-a-molti)
-- =========================================================
CREATE TABLE service_asset (
  service_id      BIGINT NOT NULL REFERENCES service(service_id) ON DELETE CASCADE,
  asset_id        BIGINT NOT NULL REFERENCES asset(asset_id) ON DELETE RESTRICT,
  usage_role      VARCHAR(120), -- es. "DB", "Web server", "Storage", "Network"
  is_critical_dependency BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (service_id, asset_id)
);

CREATE INDEX idx_sa_asset ON service_asset(asset_id);

-- =========================================================
-- 7) RELAZIONE SERVIZIO <-> FORNITORE (molti-a-molti)
-- =========================================================
CREATE TABLE service_provider (
  service_id      BIGINT NOT NULL REFERENCES service(service_id) ON DELETE CASCADE,
  provider_id     BIGINT NOT NULL REFERENCES provider(provider_id) ON DELETE RESTRICT,
  dependency_type VARCHAR(120) NOT NULL,        -- es. "Hosting", "Connettività", "Supporto"
  contract_id     VARCHAR(80),
  sla_notes       VARCHAR(200),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (service_id, provider_id, dependency_type)
);

CREATE INDEX idx_sp_provider ON service_provider(provider_id);

-- =========================================================
-- 8) STORICO / VERSIONING ASSET
--    (tabella che registra versioni precedenti quando un asset cambia)
-- =========================================================
CREATE TABLE asset_history (
  history_id      BIGSERIAL PRIMARY KEY,
  asset_id        BIGINT NOT NULL,
  company_id      BIGINT NOT NULL,
  asset_code      VARCHAR(40) NOT NULL,
  name            VARCHAR(200) NOT NULL,
  asset_type      VARCHAR(60) NOT NULL,
  description     TEXT,
  location        VARCHAR(200),
  owner_contact_id BIGINT,
  criticality     SMALLINT NOT NULL,
  status          VARCHAR(30) NOT NULL,
  valid_from      TIMESTAMPTZ NOT NULL,
  valid_to        TIMESTAMPTZ,  -- NULL = versione corrente nello storico non “chiusa”
  changed_by      VARCHAR(120), -- opzionale: utente/sistema
  change_reason   VARCHAR(200), -- opzionale: motivo modifica
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_asset_history_asset ON asset_history(asset_id);
CREATE INDEX idx_asset_history_company ON asset_history(company_id);

