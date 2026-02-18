-- =========================================================
-- PW19 - Viste/Query per profilo ACN (output strutturato)
-- File: 06_views_and_exports.sql
-- Scopo: creare viste SQL utili a estrarre in modo ordinato:
--        - asset e servizi con criticità elevata
--        - dipendenze tra servizi e asset
--        - dipendenze tra servizi e fornitori terzi
--        - referenti interni (POC: Point of Contact / responsabili)
-- Le viste possono essere interrogate direttamente da pgAdmin oppure esportate in CSV.
-- =========================================================

-- Vista: elenco degli asset con criticità elevata (criticality >= 4)
-- Include anche il referente associato, se presente.
CREATE OR REPLACE VIEW v_acn_critical_assets AS
SELECT
  c.name                     AS company_name,
  a.asset_code,
  a.name                     AS asset_name,
  a.asset_type,
  a.location,
  a.criticality,
  a.status,
  co.full_name               AS asset_owner_name,
  co.role_title              AS asset_owner_role,
  co.email                   AS asset_owner_email,
  co.phone                   AS asset_owner_phone
FROM asset a
JOIN company c ON c.company_id = a.company_id
LEFT JOIN contact co ON co.contact_id = a.owner_contact_id
WHERE a.criticality >= 4
ORDER BY c.name, a.criticality DESC, a.asset_code;


-- Vista: elenco dei servizi con criticità elevata (criticality >= 4)
-- Include anche il referente del servizio, se presente.
CREATE OR REPLACE VIEW v_acn_critical_services AS
SELECT
  c.name                     AS company_name,
  s.service_code,
  s.name                     AS service_name,
  s.criticality,
  s.status,
  co.full_name               AS service_owner_name,
  co.role_title              AS service_owner_role,
  co.email                   AS service_owner_email,
  co.phone                   AS service_owner_phone
FROM service s
JOIN company c ON c.company_id = s.company_id
LEFT JOIN contact co ON co.contact_id = s.service_owner_contact_id
WHERE s.criticality >= 4
ORDER BY c.name, s.criticality DESC, s.service_code;


-- Vista: dipendenze servizio -> asset (tabella associativa service_asset)
-- Mostra per ogni servizio gli asset utilizzati e il loro ruolo/criticità nella dipendenza.
CREATE OR REPLACE VIEW v_acn_service_asset_dependencies AS
SELECT
  c.name         AS company_name,
  s.service_code,
  s.name         AS service_name,
  a.asset_code,
  a.name         AS asset_name,
  a.asset_type,
  sa.usage_role,
  sa.is_critical_dependency
FROM service_asset sa
JOIN service s ON s.service_id = sa.service_id
JOIN asset a ON a.asset_id = sa.asset_id
JOIN company c ON c.company_id = s.company_id
ORDER BY c.name, s.service_code, a.asset_code;


-- Vista: dipendenze servizio -> fornitore (tabella associativa service_provider)
-- Mostra per ogni servizio i fornitori coinvolti e le informazioni contrattuali/sintetiche (se presenti).
CREATE OR REPLACE VIEW v_acn_service_provider_dependencies AS
SELECT
  c.name         AS company_name,
  s.service_code,
  s.name         AS service_name,
  p.name         AS provider_name,
  p.provider_type,
  sp.dependency_type,
  sp.contract_id,
  sp.sla_notes,
  p.email        AS provider_email,
  p.phone        AS provider_phone
FROM service_provider sp
JOIN service s ON s.service_id = sp.service_id
JOIN provider p ON p.provider_id = sp.provider_id
JOIN company c ON c.company_id = s.company_id
ORDER BY c.name, s.service_code, p.name, sp.dependency_type;


-- Vista "profilo minimo" (una riga per servizio)
-- Aggrega in campi testuali gli asset e i fornitori collegati al servizio.
-- È utile quando serve un export compatto in CSV, ad esempio per una prima compilazione o un riepilogo.
CREATE OR REPLACE VIEW v_acn_profile_min AS
SELECT
  c.name AS company_name,
  s.service_code,
  s.name AS service_name,
  s.criticality AS service_criticality,
  COALESCE(own.full_name, '') AS service_owner,
  COALESCE(own.email, '')     AS service_owner_email,

  -- elenco asset (codice - nome)
  COALESCE(string_agg(DISTINCT a.asset_code || ' - ' || a.name, '; '), '') AS assets_used,

  -- elenco fornitori (nome - tipo - dipendenza)
  COALESCE(string_agg(DISTINCT p.name || ' (' || COALESCE(sp.dependency_type,'') || ')', '; '), '') AS third_party_dependencies

FROM service s
JOIN company c ON c.company_id = s.company_id
LEFT JOIN contact own ON own.contact_id = s.service_owner_contact_id
LEFT JOIN service_asset sa ON sa.service_id = s.service_id
LEFT JOIN asset a ON a.asset_id = sa.asset_id
LEFT JOIN service_provider sp ON sp.service_id = s.service_id
LEFT JOIN provider p ON p.provider_id = sp.provider_id
GROUP BY c.name, s.service_code, s.name, s.criticality, own.full_name, own.email
ORDER BY c.name, s.service_code;

-- =========================================================
-- ESEMPIO EXPORT CSV (da eseguire in psql)
-- \copy (SELECT * FROM v_acn_profile_min) TO 'acn_profile_min.csv' CSV HEADER;
-- =========================================================


