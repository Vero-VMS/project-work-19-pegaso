-- =========================================================
-- 08c_incident_views.sql
-- Viste utili per reportistica incidenti e notifiche
-- =========================================================

CREATE OR REPLACE VIEW v_incident_detail AS
SELECT
  co.name AS company_name,
  i.incident_code,
  i.title,
  i.severity,
  i.status,
  i.is_significant,
  i.detected_at,
  i.occurred_at,
  i.closed_at,
  a.asset_code,
  a.name AS asset_name,
  ia.impact_type,
  ia.impact_notes
FROM incident i
JOIN company co ON co.company_id = i.company_id
LEFT JOIN incident_asset ia ON ia.incident_id = i.incident_id
LEFT JOIN asset a ON a.asset_id = ia.asset_id
ORDER BY co.name, i.detected_at DESC, i.incident_code, a.asset_code;

CREATE OR REPLACE VIEW v_incident_notifications AS
SELECT
  co.name AS company_name,
  i.incident_code,
  i.title,
  i.severity,
  i.is_significant,
  n.notification_type,
  n.authority,
  n.status AS notification_status,
  n.due_at,
  n.sent_at,
  n.reference_code
FROM incident_notification n
JOIN incident i ON i.incident_id = n.incident_id
JOIN company co ON co.company_id = i.company_id
ORDER BY co.name, i.incident_code, n.notification_type;
