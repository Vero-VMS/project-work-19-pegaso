-- =========================================================
-- 08b_incident_seed.sql
-- Seed demo incidenti + notifiche (Azienda Demo S.p.A.)
-- =========================================================

WITH demo AS (
  SELECT company_id FROM company WHERE name = 'Azienda Demo S.p.A.'
)
INSERT INTO incident (company_id, incident_code, title, description, severity, status, is_significant, detected_at)
SELECT
  company_id,
  'INC-2026-001',
  'Interruzione servizio email',
  'Degrado del servizio e-mail con impatto su disponibilità. Analisi in corso.',
  'HIGH',
  'UNDER_ANALYSIS',
  TRUE,
  now() - interval '2 days'
FROM demo
ON CONFLICT (company_id, incident_code) DO NOTHING;

-- collega l'incidente ad un asset (usa asset_code esistente, es. SRV-001 o NET-001)
WITH
demo AS (SELECT company_id FROM company WHERE name='Azienda Demo S.p.A.'),
inc AS (
  SELECT incident_id FROM incident
  WHERE company_id = (SELECT company_id FROM demo)
    AND incident_code = 'INC-2026-001'
),
a AS (
  SELECT asset_id FROM asset
  WHERE company_id = (SELECT company_id FROM demo)
    AND asset_code IN ('SRV-001')
)
INSERT INTO incident_asset (incident_id, asset_id, impact_type, impact_notes)
SELECT (SELECT incident_id FROM inc), asset_id, 'AVAILABILITY', 'Impatto sulla disponibilità del servizio'
FROM a
ON CONFLICT DO NOTHING;

-- notifiche: early warning + full report (demo)
WITH
demo AS (SELECT company_id FROM company WHERE name='Azienda Demo S.p.A.'),
inc AS (
  SELECT incident_id, detected_at FROM incident
  WHERE company_id = (SELECT company_id FROM demo)
    AND incident_code = 'INC-2026-001'
)
INSERT INTO incident_notification (incident_id, notification_type, authority, status, due_at, sent_at, content_summary)
SELECT
  incident_id,
  'EARLY_24H',
  'ACN',
  'SENT',
  detected_at + interval '24 hours',
  detected_at + interval '20 hours',
  'Early warning: incidente significativo, prime misure di contenimento avviate'
FROM inc
ON CONFLICT (incident_id, notification_type) DO NOTHING;

WITH
demo AS (SELECT company_id FROM company WHERE name='Azienda Demo S.p.A.'),
inc AS (
  SELECT incident_id, detected_at FROM incident
  WHERE company_id = (SELECT company_id FROM demo)
    AND incident_code = 'INC-2026-001'
)
INSERT INTO incident_notification (incident_id, notification_type, authority, status, due_at, sent_at, content_summary)
SELECT
  incident_id,
  'FULL_72H',
  'ACN',
  'DRAFT',
  detected_at + interval '72 hours',
  NULL,
  'Bozza notifica 72h: impatto, IOC preliminari, misure adottate e piano di remediation'
FROM inc
ON CONFLICT (incident_id, notification_type) DO NOTHING;
