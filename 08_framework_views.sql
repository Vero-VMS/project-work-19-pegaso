-- =========================================================
-- 08_framework_views.sql
-- Viste per esportare porzioni di profilo secondo Framework Nazionale:
-- - Dettaglio ASSET e SERVICE
-- - Filtri CURRENT / TARGET
-- - Summary per subcategory
-- - Gap analysis (TARGET - CURRENT)
-- =========================================================

-- ---------------------------------------------------------
-- A) Viste ASSET
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW v_fw_asset_profile_detail AS
SELECT
  co.name AS company_name,
  p.profile_type,
  a.asset_code,
  a.name AS asset_name,
  a.asset_type,
  a.criticality AS asset_criticality,

  ctl.code AS control_code,
  ctl.name AS control_name,

  sc.code AS subcategory_code,
  sc.function_code,
  sc.category_code,
  sc.name AS subcategory_name,

  ass.coverage,
  ass.maturity,
  ass.updated_at,
  ass.notes,
  ass.evidence
FROM fw_asset_control_assessment ass
JOIN fw_profile p ON p.profile_id = ass.profile_id
JOIN company co ON co.company_id = p.company_id
JOIN asset a ON a.asset_id = ass.asset_id
JOIN fw_control ctl ON ctl.control_id = ass.control_id
LEFT JOIN fw_control_subcategory cs ON cs.control_id = ctl.control_id
LEFT JOIN fw_subcategory sc ON sc.subcategory_id = cs.subcategory_id
ORDER BY co.name, p.profile_type, a.asset_code, ctl.code, sc.code;

CREATE OR REPLACE VIEW v_fw_asset_profile_current AS
SELECT * FROM v_fw_asset_profile_detail
WHERE profile_type = 'CURRENT';

CREATE OR REPLACE VIEW v_fw_asset_profile_target AS
SELECT * FROM v_fw_asset_profile_detail
WHERE profile_type = 'TARGET';

-- ---------------------------------------------------------
-- B) Viste SERVICE
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW v_fw_service_profile_detail AS
SELECT
  co.name AS company_name,
  p.profile_type,
  s.service_code,
  s.name AS service_name,
  s.criticality AS service_criticality,

  ctl.code AS control_code,
  ctl.name AS control_name,

  sc.code AS subcategory_code,
  sc.function_code,
  sc.category_code,
  sc.name AS subcategory_name,

  ass.coverage,
  ass.maturity,
  ass.updated_at,
  ass.notes,
  ass.evidence
FROM fw_service_control_assessment ass
JOIN fw_profile p ON p.profile_id = ass.profile_id
JOIN company co ON co.company_id = p.company_id
JOIN service s ON s.service_id = ass.service_id
JOIN fw_control ctl ON ctl.control_id = ass.control_id
LEFT JOIN fw_control_subcategory cs ON cs.control_id = ctl.control_id
LEFT JOIN fw_subcategory sc ON sc.subcategory_id = cs.subcategory_id
ORDER BY co.name, p.profile_type, s.service_code, ctl.code, sc.code;

CREATE OR REPLACE VIEW v_fw_service_profile_current AS
SELECT * FROM v_fw_service_profile_detail
WHERE profile_type = 'CURRENT';

CREATE OR REPLACE VIEW v_fw_service_profile_target AS
SELECT * FROM v_fw_service_profile_detail
WHERE profile_type = 'TARGET';

-- ---------------------------------------------------------
-- C) Summary per subcategory (ASSET + SERVICE)
--    Utile per mostrare confrontabilità e aggregazione
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW v_fw_subcategory_summary_asset AS
SELECT
  company_name,
  profile_type,
  subcategory_code,
  function_code,
  category_code,
  subcategory_name,
  ROUND(AVG(coverage)::numeric, 2) AS avg_coverage,
  ROUND(AVG(maturity)::numeric, 2) AS avg_maturity,
  COUNT(DISTINCT asset_code) AS items_in_scope,
  COUNT(DISTINCT control_code) AS controls_linked
FROM v_fw_asset_profile_detail
WHERE subcategory_code IS NOT NULL
GROUP BY
  company_name, profile_type, subcategory_code, function_code, category_code, subcategory_name
ORDER BY company_name, profile_type, subcategory_code;

CREATE OR REPLACE VIEW v_fw_subcategory_summary_service AS
SELECT
  company_name,
  profile_type,
  subcategory_code,
  function_code,
  category_code,
  subcategory_name,
  ROUND(AVG(coverage)::numeric, 2) AS avg_coverage,
  ROUND(AVG(maturity)::numeric, 2) AS avg_maturity,
  COUNT(DISTINCT service_code) AS items_in_scope,
  COUNT(DISTINCT control_code) AS controls_linked
FROM v_fw_service_profile_detail
WHERE subcategory_code IS NOT NULL
GROUP BY
  company_name, profile_type, subcategory_code, function_code, category_code, subcategory_name
ORDER BY company_name, profile_type, subcategory_code;

-- ---------------------------------------------------------
-- D) Gap analysis (TARGET - CURRENT) su ASSET (per control)
--    Super utile per "valutazione" e voto alto
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW v_fw_asset_gap_by_control AS
SELECT
  cur.company_name,
  cur.asset_code,
  cur.asset_name,
  cur.control_code,
  cur.control_name,
  cur.coverage AS current_coverage,
  tar.coverage AS target_coverage,
  (tar.coverage - cur.coverage) AS coverage_gap,
  cur.maturity AS current_maturity,
  tar.maturity AS target_maturity,
  (tar.maturity - cur.maturity) AS maturity_gap
FROM (
  SELECT DISTINCT company_name, asset_code, asset_name, control_code, control_name, coverage, maturity
  FROM v_fw_asset_profile_current
  WHERE subcategory_code IS NOT NULL
) cur
JOIN (
  SELECT DISTINCT company_name, asset_code, asset_name, control_code, control_name, coverage, maturity
  FROM v_fw_asset_profile_target
  WHERE subcategory_code IS NOT NULL
) tar
ON cur.company_name = tar.company_name
AND cur.asset_code = tar.asset_code
AND cur.control_code = tar.control_code
ORDER BY cur.company_name, cur.asset_code, cur.control_code;

-- ---------------------------------------------------------
-- Suggerimenti export CSV (psql):
-- \copy (SELECT * FROM v_fw_asset_profile_current)  TO 'fw_asset_profile_current.csv'  CSV HEADER;
-- \copy (SELECT * FROM v_fw_asset_profile_target)   TO 'fw_asset_profile_target.csv'   CSV HEADER;
-- \copy (SELECT * FROM v_fw_service_profile_current)TO 'fw_service_profile_current.csv'CSV HEADER;
-- \copy (SELECT * FROM v_fw_service_profile_target) TO 'fw_service_profile_target.csv' CSV HEADER;
-- \copy (SELECT * FROM v_fw_asset_gap_by_control)   TO 'fw_asset_gap_by_control.csv'   CSV HEADER;
