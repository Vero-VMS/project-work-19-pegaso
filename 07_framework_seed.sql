-- =========================================================
-- 07_framework_seed.sql
-- Dati demo per Framework Nazionale:
-- - Subcategory (campione)
-- - Controlli (campione)
-- - Mapping controllo-subcategory
-- - Profili CURRENT/TARGET per "Azienda Demo S.p.A."
-- - Assessment su alcuni ASSET e alcuni SERVICE del dataset
-- =========================================================

-- ---------------------------------------------------------
-- 1) Subcategory (campione)
-- ---------------------------------------------------------
INSERT INTO fw_subcategory (code, name, description, function_code, category_code)
VALUES
  ('ID.AM-1','Inventario asset','Inventario di asset fisici e logici mantenuto e aggiornato','ID','ID.AM'),
  ('ID.AM-2','Inventario software','Inventario software e componenti applicativi mantenuto','ID','ID.AM'),
  ('ID.SC-1','Supply chain','Dipendenze e requisiti di sicurezza su fornitori gestiti','ID','ID.SC'),

  ('PR.AC-1','Gestione accessi','Identità e credenziali gestite e verificate','PR','PR.AC'),
  ('PR.AC-4','Least privilege','Principio del minimo privilegio applicato','PR','PR.AC'),
  ('PR.DS-1','Protezione dati','Dati protetti in transito e a riposo','PR','PR.DS'),
  ('PR.IP-3','Change management','Processi di gestione modifiche formalizzati','PR','PR.IP'),

  ('DE.CM-1','Monitoraggio eventi','Eventi e attività monitorati per rilevare anomalie','DE','DE.CM'),
  ('RS.RP-1','Incident response plan','Piano di risposta agli incidenti stabilito','RS','RS.RP'),
  ('RC.RP-1','Recovery plan','Piano di ripristino e continuità definito','RC','RC.RP')
ON CONFLICT (code) DO NOTHING;

-- ---------------------------------------------------------
-- 2) Controlli (campione)
-- ---------------------------------------------------------
INSERT INTO fw_control (code, name, description)
VALUES
  ('CTRL-INV','Gestione inventario','Procedure e responsabilità per inventario e classificazione'),
  ('CTRL-IAM','Gestione identità e accessi','Account lifecycle, MFA, provisioning/deprovisioning'),
  ('CTRL-ENC','Cifratura dati','Cifratura at-rest/in-transit e gestione chiavi'),
  ('CTRL-CHG','Gestione cambiamenti','Approvals, tracciamento modifiche, patching'),
  ('CTRL-MON','Monitoraggio e logging','Raccolta log, alerting, review'),
  ('CTRL-SUP','Gestione fornitori','Valutazione requisiti sicurezza su terze parti')
ON CONFLICT (code) DO NOTHING;

-- ---------------------------------------------------------
-- 3) Mapping controllo <-> subcategory
-- ---------------------------------------------------------
WITH c AS (SELECT control_id, code FROM fw_control),
     s AS (SELECT subcategory_id, code FROM fw_subcategory)
INSERT INTO fw_control_subcategory (control_id, subcategory_id)
SELECT c.control_id, s.subcategory_id
FROM c
JOIN s ON (
  (c.code='CTRL-INV' AND s.code IN ('ID.AM-1','ID.AM-2'))
  OR
  (c.code='CTRL-IAM' AND s.code IN ('PR.AC-1','PR.AC-4'))
  OR
  (c.code='CTRL-ENC' AND s.code IN ('PR.DS-1'))
  OR
  (c.code='CTRL-CHG' AND s.code IN ('PR.IP-3'))
  OR
  (c.code='CTRL-MON' AND s.code IN ('DE.CM-1','RS.RP-1'))
  OR
  (c.code='CTRL-SUP' AND s.code IN ('ID.SC-1'))
)
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------
-- 4) Profili CURRENT/TARGET per l'azienda demo
-- ---------------------------------------------------------
WITH demo AS (
  SELECT company_id
  FROM company
  WHERE name = 'Azienda Demo S.p.A.'
)
INSERT INTO fw_profile (company_id, profile_type, notes)
SELECT company_id, 'CURRENT', 'Profilo attuale (demo)'
FROM demo
ON CONFLICT (company_id, profile_type) DO NOTHING;

WITH demo AS (
  SELECT company_id
  FROM company
  WHERE name = 'Azienda Demo S.p.A.'
)
INSERT INTO fw_profile (company_id, profile_type, notes)
SELECT company_id, 'TARGET', 'Profilo target (demo)'
FROM demo
ON CONFLICT (company_id, profile_type) DO NOTHING;

-- ---------------------------------------------------------
-- 5) Assessment su ASSET (usa asset_code esistenti nel tuo seed)
-- ---------------------------------------------------------
WITH
demo AS (SELECT company_id FROM company WHERE name='Azienda Demo S.p.A.'),
p AS (
  SELECT profile_id, profile_type
  FROM fw_profile
  WHERE company_id = (SELECT company_id FROM demo)
),
a AS (
  SELECT asset_id, asset_code
  FROM asset
  WHERE company_id = (SELECT company_id FROM demo)
    AND asset_code IN ('DB-001','CLD-001','NET-001','SRV-001')
),
c AS (SELECT control_id, code FROM fw_control)
INSERT INTO fw_asset_control_assessment (profile_id, asset_id, control_id, coverage, maturity, notes, evidence)
SELECT
  (SELECT profile_id FROM p WHERE profile_type='CURRENT'),
  a.asset_id,
  c.control_id,
  v.coverage,
  v.maturity,
  v.notes,
  v.evidence
FROM a
JOIN LATERAL (
  VALUES
    ('DB-001','CTRL-INV',1.0,3,'Asset censito e classificato','Registro asset/CMDB'),
    ('DB-001','CTRL-IAM',0.6,2,'MFA parziale','Policy IAM'),
    ('DB-001','CTRL-ENC',0.4,2,'Cifratura parziale','TLS/KMS parziale'),
    ('DB-001','CTRL-CHG',0.6,2,'Change management in uso','Ticketing'),

    ('CLD-001','CTRL-INV',0.8,3,'Inventario cloud semi-automatizzato','Report provider'),
    ('CLD-001','CTRL-ENC',0.6,3,'Cifratura storage principale','KMS/Policy'),

    ('NET-001','CTRL-INV',1.0,3,'Firewall censito','Asset register'),
    ('NET-001','CTRL-MON',0.6,2,'Logging presente, alerting migliorabile','SIEM base'),

    ('SRV-001','CTRL-INV',1.0,3,'Server censito','CMDB'),
    ('SRV-001','CTRL-MON',0.4,2,'Monitoraggio base','Monitoring tool')
) AS v(asset_code, control_code, coverage, maturity, notes, evidence)
  ON v.asset_code = a.asset_code
JOIN c ON c.code = v.control_code
ON CONFLICT (profile_id, asset_id, control_id) DO NOTHING;

-- TARGET asset (obiettivi più alti)
WITH
demo AS (SELECT company_id FROM company WHERE name='Azienda Demo S.p.A.'),
p AS (
  SELECT profile_id, profile_type
  FROM fw_profile
  WHERE company_id = (SELECT company_id FROM demo)
),
a AS (
  SELECT asset_id, asset_code
  FROM asset
  WHERE company_id = (SELECT company_id FROM demo)
    AND asset_code IN ('DB-001','CLD-001','NET-001','SRV-001')
),
c AS (SELECT control_id, code FROM fw_control)
INSERT INTO fw_asset_control_assessment (profile_id, asset_id, control_id, coverage, maturity, notes, evidence)
SELECT
  (SELECT profile_id FROM p WHERE profile_type='TARGET'),
  a.asset_id,
  c.control_id,
  v.coverage,
  v.maturity,
  v.notes,
  v.evidence
FROM a
JOIN LATERAL (
  VALUES
    ('DB-001','CTRL-IAM',1.0,4,'MFA completo e provisioning controllato','Roadmap IAM'),
    ('DB-001','CTRL-ENC',1.0,4,'Cifratura completa at-rest/in-transit','Roadmap encryption'),
    ('DB-001','CTRL-MON',0.8,3,'Alerting avanzato','Roadmap SIEM'),

    ('CLD-001','CTRL-SUP',0.8,3,'Valutazione periodica provider','Vendor assessment'),

    ('NET-001','CTRL-MON',0.8,3,'Correlazione eventi migliorata','SIEM roadmap'),
    ('SRV-001','CTRL-CHG',0.8,3,'Patching e change più strutturati','Change/Patch roadmap')
) AS v(asset_code, control_code, coverage, maturity, notes, evidence)
  ON v.asset_code = a.asset_code
JOIN c ON c.code = v.control_code
ON CONFLICT (profile_id, asset_id, control_id) DO NOTHING;

-- ---------------------------------------------------------
-- 6) Assessment su SERVICE (usa service_code esistenti nel tuo seed)
-- ---------------------------------------------------------
WITH
demo AS (SELECT company_id FROM company WHERE name='Azienda Demo S.p.A.'),
p AS (
  SELECT profile_id, profile_type
  FROM fw_profile
  WHERE company_id = (SELECT company_id FROM demo)
),
s AS (
  SELECT service_id, service_code
  FROM service
  WHERE company_id = (SELECT company_id FROM demo)
    AND service_code IN ('SVC-PORT','SVC-EMAIL')
),
c AS (SELECT control_id, code FROM fw_control)
INSERT INTO fw_service_control_assessment (profile_id, service_id, control_id, coverage, maturity, notes, evidence)
SELECT
  (SELECT profile_id FROM p WHERE profile_type='CURRENT'),
  s.service_id,
  c.control_id,
  v.coverage,
  v.maturity,
  v.notes,
  v.evidence
FROM s
JOIN LATERAL (
  VALUES
    ('SVC-PORT','CTRL-IAM',0.6,2,'Accessi utenti gestiti, MFA parziale','Policy accessi'),
    ('SVC-PORT','CTRL-MON',0.4,2,'Monitoraggio base del servizio','Log applicativi'),

    ('SVC-EMAIL','CTRL-IAM',0.6,2,'MFA non completo su tutti gli account','IAM notes'),
    ('SVC-EMAIL','CTRL-SUP',0.6,2,'Dipendenza terza parte gestita ma non formalizzata','Contratto/SLA')
) AS v(service_code, control_code, coverage, maturity, notes, evidence)
  ON v.service_code = s.service_code
JOIN c ON c.code = v.control_code
ON CONFLICT (profile_id, service_id, control_id) DO NOTHING;

-- TARGET service (obiettivi più alti)
WITH
demo AS (SELECT company_id FROM company WHERE name='Azienda Demo S.p.A.'),
p AS (
  SELECT profile_id, profile_type
  FROM fw_profile
  WHERE company_id = (SELECT company_id FROM demo)
),
s AS (
  SELECT service_id, service_code
  FROM service
  WHERE company_id = (SELECT company_id FROM demo)
    AND service_code IN ('SVC-PORT','SVC-EMAIL')
),
c AS (SELECT control_id, code FROM fw_control)
INSERT INTO fw_service_control_assessment (profile_id, service_id, control_id, coverage, maturity, notes, evidence)
SELECT
  (SELECT profile_id FROM p WHERE profile_type='TARGET'),
  s.service_id,
  c.control_id,
  v.coverage,
  v.maturity,
  v.notes,
  v.evidence
FROM s
JOIN LATERAL (
  VALUES
    ('SVC-PORT','CTRL-IAM',1.0,4,'MFA completo e revisione privilegi','Roadmap IAM'),
    ('SVC-PORT','CTRL-MON',0.8,3,'SLO/SLA e alerting avanzato','Roadmap monitoring'),

    ('SVC-EMAIL','CTRL-IAM',1.0,4,'Account governance completa','Roadmap IAM'),
    ('SVC-EMAIL','CTRL-SUP',0.8,3,'Requisiti contrattuali di sicurezza formalizzati','Vendor governance')
) AS v(service_code, control_code, coverage, maturity, notes, evidence)
  ON v.service_code = s.service_code
JOIN c ON c.code = v.control_code
ON CONFLICT (profile_id, service_id, control_id) DO NOTHING;
