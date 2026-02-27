-- =========================================================
-- 09_queries_validation.sql
-- Query di validazione e verifica del modello dati (PW19)
-- =========================================================
-- Scopo: eseguire controlli rapidi per verificare:
--   - popolamento e consistenza dei dati di test
--   - assenza di duplicati e incoerenze logiche
--   - correttezza delle relazioni (1-N e N-M)
--   - corretto funzionamento della storicizzazione (asset_history)
--
-- Queste query vanno eseguite dopo la creazione dello schema (01..02),
--       dopo l’inserimento dei dati di test (03) e dopo viste/query (04).
-- =========================================================

-- ---------------------------------------------------------
-- A) PANORAMICA RAPIDA (conteggi principali)
-- ---------------------------------------------------------

-- Q01: Conteggio aziende
SELECT COUNT(*) AS companies
FROM company;

-- Q02: Conteggio contatti
SELECT COUNT(*) AS contacts
FROM contact;

-- Q03: Conteggio asset
SELECT COUNT(*) AS assets
FROM asset;

-- Q04: Conteggio servizi
SELECT COUNT(*) AS services
FROM service;

-- Q05: Conteggio fornitori
SELECT COUNT(*) AS providers
FROM provider;

-- Q06: Conteggio relazioni servizio-asset
SELECT COUNT(*) AS service_asset_links
FROM service_asset;

-- Q07: Conteggio relazioni servizio-provider
SELECT COUNT(*) AS service_provider_links
FROM service_provider;

-- Q08: Conteggio righe storico asset
SELECT COUNT(*) AS asset_history_rows
FROM asset_history;


-- ---------------------------------------------------------
-- B) COERENZA ANAGRAFICA / DUPLICATI
-- ---------------------------------------------------------

-- Q09: Controllo duplicati company (nome) - se il modello lo consente non deve tornare righe duplicate
SELECT name, COUNT(*) AS cnt
FROM company
GROUP BY name
HAVING COUNT(*) > 1;

-- Q10: Controllo duplicati company (vat_number) - se previsto univoco
SELECT vat_number, COUNT(*) AS cnt
FROM company
WHERE vat_number IS NOT NULL
GROUP BY vat_number
HAVING COUNT(*) > 1;

-- Q11: Controllo duplicati asset_code per azienda (deve essere univoco)
SELECT company_id, asset_code, COUNT(*) AS cnt
FROM asset
GROUP BY company_id, asset_code
HAVING COUNT(*) > 1;

-- Q12: Controllo duplicati service_code per azienda (deve essere univoco)
SELECT company_id, service_code, COUNT(*) AS cnt
FROM service
GROUP BY company_id, service_code
HAVING COUNT(*) > 1;


-- ---------------------------------------------------------
-- C) VALIDAZIONE RANGE / VALORI AMMESSI (consistenza logica)
-- ---------------------------------------------------------

-- Q13: Asset con criticality fuori range (1..5) - dovrebbe tornare 0 righe
SELECT *
FROM asset
WHERE criticality < 1 OR criticality > 5;

-- Q14: Service con criticality fuori range (1..5) - dovrebbe tornare 0 righe
SELECT *
FROM service
WHERE criticality < 1 OR criticality > 5;

-- Q15: Asset con status non ammesso - dovrebbe tornare 0 righe
SELECT *
FROM asset
WHERE status NOT IN ('ACTIVE','INACTIVE','RETIRED');

-- Q16: Service con status non ammesso - dovrebbe tornare 0 righe
SELECT *
FROM service
WHERE status NOT IN ('ACTIVE','INACTIVE','RETIRED');


-- ---------------------------------------------------------
-- D) COERENZA RELAZIONI 1-N (company → contact/asset/service)
-- ---------------------------------------------------------

-- Q17: Contatti senza company (non dovrebbe esistere se FK NOT NULL)
SELECT c.*
FROM contact c
LEFT JOIN company co ON co.company_id = c.company_id
WHERE co.company_id IS NULL;

-- Q18: Asset senza company (non dovrebbe esistere se FK NOT NULL)
SELECT a.*
FROM asset a
LEFT JOIN company co ON co.company_id = a.company_id
WHERE co.company_id IS NULL;

-- Q19: Service senza company (non dovrebbe esistere se FK NOT NULL)
SELECT s.*
FROM service s
LEFT JOIN company co ON co.company_id = s.company_id
WHERE co.company_id IS NULL;


-- ---------------------------------------------------------
-- E) COERENZA RESPONSABILI (owner/service_owner)
-- ---------------------------------------------------------

-- Q20: Asset con owner_contact_id che non esiste (dovrebbe tornare 0 righe)
SELECT a.*
FROM asset a
LEFT JOIN contact c ON c.contact_id = a.owner_contact_id
WHERE a.owner_contact_id IS NOT NULL
  AND c.contact_id IS NULL;

-- Q21: Service con service_owner_contact_id che non esiste (dovrebbe tornare 0 righe)
SELECT s.*
FROM service s
LEFT JOIN contact c ON c.contact_id = s.service_owner_contact_id
WHERE s.service_owner_contact_id IS NOT NULL
  AND c.contact_id IS NULL;

-- Q22: (consistenza) Owner asset appartenente a company diversa (da evitare)
SELECT a.asset_id, a.company_id AS asset_company, a.owner_contact_id,
       c.company_id AS contact_company
FROM asset a
JOIN contact c ON c.contact_id = a.owner_contact_id
WHERE a.owner_contact_id IS NOT NULL
  AND a.company_id <> c.company_id;

-- Q23: (consistenza) Owner service appartenente a company diversa (da evitare)
SELECT s.service_id, s.company_id AS service_company, s.service_owner_contact_id,
       c.company_id AS contact_company
FROM service s
JOIN contact c ON c.contact_id = s.service_owner_contact_id
WHERE s.service_owner_contact_id IS NOT NULL
  AND s.company_id <> c.company_id;


-- ---------------------------------------------------------
-- F) VALIDAZIONE RELAZIONI N-M (service_asset / service_provider)
-- ---------------------------------------------------------

-- Q24: Righe service_asset con service_id non valido (dovrebbe tornare 0 righe)
SELECT sa.*
FROM service_asset sa
LEFT JOIN service s ON s.service_id = sa.service_id
WHERE s.service_id IS NULL;

-- Q25: Righe service_asset con asset_id non valido (dovrebbe tornare 0 righe)
SELECT sa.*
FROM service_asset sa
LEFT JOIN asset a ON a.asset_id = sa.asset_id
WHERE a.asset_id IS NULL;

-- Q26: Righe service_provider con service_id non valido (dovrebbe tornare 0 righe)
SELECT sp.*
FROM service_provider sp
LEFT JOIN service s ON s.service_id = sp.service_id
WHERE s.service_id IS NULL;

-- Q27: Righe service_provider con provider_id non valido (dovrebbe tornare 0 righe)
SELECT sp.*
FROM service_provider sp
LEFT JOIN provider p ON p.provider_id = sp.provider_id
WHERE p.provider_id IS NULL;

-- Q28: (consistenza) Service_asset: servizio e asset devono appartenere alla stessa company
SELECT sa.service_id, s.company_id AS service_company,
       sa.asset_id, a.company_id AS asset_company
FROM service_asset sa
JOIN service s ON s.service_id = sa.service_id
JOIN asset a ON a.asset_id = sa.asset_id
WHERE s.company_id <> a.company_id;

-- Q29: Provider effettivamente usati (collegati ad almeno un servizio)
SELECT p.provider_id, p.name, COUNT(DISTINCT sp.service_id) AS linked_services
FROM provider p
JOIN service_provider sp ON sp.provider_id = p.provider_id
GROUP BY p.provider_id, p.name
ORDER BY linked_services DESC, p.name;

-- Q29b: Provider non collegati ad alcun servizio (dato potenzialmente incompleto)
SELECT p.provider_id, p.name
FROM provider p
LEFT JOIN service_provider sp ON sp.provider_id = p.provider_id
WHERE sp.provider_id IS NULL
ORDER BY p.name;


-- ---------------------------------------------------------
-- G) QUERY “UTILI” PER DIMOSTRARE CHE IL MODELLO FUNZIONA
-- ---------------------------------------------------------

-- Q30: Elenco asset critici (>=4) con responsabile
SELECT a.asset_code, a.name, a.criticality, a.status,
       c.full_name AS owner_name, c.role_title AS owner_role
FROM asset a
LEFT JOIN contact c ON c.contact_id = a.owner_contact_id
WHERE a.criticality >= 4
ORDER BY a.criticality DESC, a.asset_code;

-- Q31: Elenco servizi critici (>=4) con responsabile
SELECT s.service_code, s.name, s.criticality, s.status,
       c.full_name AS owner_name, c.role_title AS owner_role
FROM service s
LEFT JOIN contact c ON c.contact_id = s.service_owner_contact_id
WHERE s.criticality >= 4
ORDER BY s.criticality DESC, s.service_code;

-- Q32: Dipendenze di un servizio (asset usati) - esempio su SVC-PORT
SELECT s.service_code, s.name AS service_name,
       a.asset_code, a.name AS asset_name,
       sa.usage_role, sa.is_critical_dependency
FROM service s
JOIN service_asset sa ON sa.service_id = s.service_id
JOIN asset a ON a.asset_id = sa.asset_id
WHERE s.service_code = 'SVC-PORT'
ORDER BY a.asset_code;

-- Q33: Dipendenze di un servizio (fornitori coinvolti) - esempio su SVC-PORT
SELECT s.service_code, s.name AS service_name,
       p.name AS provider_name,
       sp.dependency_type, sp.contract_id, sp.sla_notes
FROM service s
JOIN service_provider sp ON sp.service_id = s.service_id
JOIN provider p ON p.provider_id = sp.provider_id
WHERE s.service_code = 'SVC-PORT'
ORDER BY p.name, sp.dependency_type;

-- Q34: Impatto di un asset: quali servizi dipendono da DB-001 (asset critico tipico)
SELECT a.asset_code, a.name AS asset_name,
       s.service_code, s.name AS service_name,
       sa.usage_role, sa.is_critical_dependency
FROM asset a
JOIN service_asset sa ON sa.asset_id = a.asset_id
JOIN service s ON s.service_id = sa.service_id
WHERE a.asset_code = 'DB-001'
ORDER BY s.service_code;

-- Q35: Impatto di un provider: quali servizi dipendono da CloudOne
SELECT p.name AS provider_name,
       s.service_code, s.name AS service_name,
       sp.dependency_type, sp.contract_id
FROM provider p
JOIN service_provider sp ON sp.provider_id = p.provider_id
JOIN service s ON s.service_id = sp.service_id
WHERE p.name = 'CloudOne'
ORDER BY s.service_code, sp.dependency_type;


-- ---------------------------------------------------------
-- H) VALIDAZIONE STORICO (asset_history)
-- In questa sezione verifico che il trigger di versioning produca righe coerenti e non sovrapposte nel tempo.
-- ---------------------------------------------------------

-- Q36: Storico per un asset (tutte le versioni)
-- (filtra per asset_code a scelta)
SELECT ah.asset_code, ah.name, ah.criticality, ah.status,
       ah.valid_from, ah.valid_to, ah.changed_by, ah.change_reason
FROM asset_history ah
WHERE ah.asset_code = 'SRV-001'
ORDER BY ah.valid_from DESC;

-- Q37: Controllo sovrapposizioni temporali nello storico
-- (per lo stesso asset non dovrebbero esserci intervalli sovrapposti)
SELECT h1.asset_id, h1.history_id AS h1_id, h2.history_id AS h2_id,
       h1.valid_from AS h1_from, COALESCE(h1.valid_to, now()) AS h1_to,
       h2.valid_from AS h2_from, COALESCE(h2.valid_to, now()) AS h2_to
FROM asset_history h1
JOIN asset_history h2
  ON h1.asset_id = h2.asset_id
 AND h1.history_id < h2.history_id
WHERE h1.valid_from < COALESCE(h2.valid_to, now())
  AND h2.valid_from < COALESCE(h1.valid_to, now());

-- Q38: Asset che hanno owner cambiato nel tempo (esempio di audit)
SELECT ah.asset_code,
       COUNT(DISTINCT ah.owner_contact_id) AS distinct_owners
FROM asset_history ah
GROUP BY ah.asset_code
HAVING COUNT(DISTINCT ah.owner_contact_id) > 1
ORDER BY distinct_owners DESC;


-- ---------------------------------------------------------
-- I) QUERY DI “QUALITÀ” (facoltative, utili per report)
-- ---------------------------------------------------------

-- Q39: Contatti marcati come Primary POC per company
SELECT co.name AS company_name,
       c.full_name, c.email, c.phone, c.role_title
FROM company co
JOIN contact c ON c.company_id = co.company_id
WHERE c.is_primary_poc = TRUE
ORDER BY co.name;

-- Q40: Servizi senza dipendenze (né asset né provider) - utile per controlli
SELECT s.service_code, s.name
FROM service s
LEFT JOIN service_asset sa ON sa.service_id = s.service_id
LEFT JOIN service_provider sp ON sp.service_id = s.service_id
WHERE sa.service_id IS NULL
  AND sp.service_id IS NULL
ORDER BY s.service_code;

-- Q41: Asset non collegati ad alcun servizio (potenziale asset inutilizzato)
SELECT a.asset_code, a.name, a.status
FROM asset a
LEFT JOIN service_asset sa ON sa.asset_id = a.asset_id
WHERE sa.asset_id IS NULL
ORDER BY a.asset_code;

-- Q42: Distribuzione criticità asset (statistiche)
SELECT criticality, COUNT(*) AS cnt
FROM asset
GROUP BY criticality
ORDER BY criticality;

-- Q43: Distribuzione criticità servizi (statistiche)
SELECT criticality, COUNT(*) AS cnt
FROM service
GROUP BY criticality
ORDER BY criticality;

-- ---------------------------------------------------------
-- J) VALIDAZIONE FRAMEWORK (controlli, subcategory, profili)
-- Scopo: dimostrare che la parte "profilo" include:
--   - controlli e subcategory (mapping completo)
--   - profili CURRENT/TARGET per azienda
--   - assessment coerenti con company e con regole coverage/maturity
-- ---------------------------------------------------------

-- Q44: Subcategory presenti nel framework (conteggio)
SELECT COUNT(*) AS fw_subcategories
FROM fw_subcategory;

-- Q45: Controlli presenti nel framework (conteggio)
SELECT COUNT(*) AS fw_controls
FROM fw_control;

-- Q46: Controlli senza subcategory (NON dovrebbero esistere)
-- Se torna righe, significa che il profilo/framework non include subcategory per quei controlli.
SELECT
  c.control_id, c.code AS control_code, c.name AS control_name
FROM fw_control c
LEFT JOIN fw_control_subcategory cs ON cs.control_id = c.control_id
WHERE cs.control_id IS NULL
ORDER BY c.code;

-- Q47: Subcategory senza controlli (può essere accettabile, ma segnala copertura incompleta)
SELECT
  s.subcategory_id, s.code AS subcategory_code, s.name AS subcategory_name
FROM fw_subcategory s
LEFT JOIN fw_control_subcategory cs ON cs.subcategory_id = s.subcategory_id
WHERE cs.subcategory_id IS NULL
ORDER BY s.code;

-- Q48: Verifica che per ogni company esista al massimo un profilo CURRENT e uno TARGET
-- (grazie al vincolo UNIQUE non dovrebbe mai tornare righe)
SELECT company_id, profile_type, COUNT(*) AS cnt
FROM fw_profile
GROUP BY company_id, profile_type
HAVING COUNT(*) > 1;

-- Q49: Assessment ASSET orfani (profile / asset / control non validi) - dovrebbe tornare 0 righe
SELECT a.*
FROM fw_asset_control_assessment a
LEFT JOIN fw_profile p ON p.profile_id = a.profile_id
LEFT JOIN asset s ON s.asset_id = a.asset_id
LEFT JOIN fw_control c ON c.control_id = a.control_id
WHERE p.profile_id IS NULL OR s.asset_id IS NULL OR c.control_id IS NULL;

-- Q50: Assessment SERVICE orfani (profile / service / control non validi) - dovrebbe tornare 0 righe
SELECT a.*
FROM fw_service_control_assessment a
LEFT JOIN fw_profile p ON p.profile_id = a.profile_id
LEFT JOIN service s ON s.service_id = a.service_id
LEFT JOIN fw_control c ON c.control_id = a.control_id
WHERE p.profile_id IS NULL OR s.service_id IS NULL OR c.control_id IS NULL;

-- Q51: Coerenza company tra profilo e asset (dovrebbe tornare 0 righe)
-- (il trigger già la impedisce, ma questa query è "evidence" per la tesi)
SELECT
  a.assessment_id,
  p.company_id AS profile_company,
  asst.company_id AS asset_company
FROM fw_asset_control_assessment a
JOIN fw_profile p ON p.profile_id = a.profile_id
JOIN asset asst ON asst.asset_id = a.asset_id
WHERE p.company_id <> asst.company_id;

-- Q52: Coerenza company tra profilo e service (dovrebbe tornare 0 righe)
SELECT
  a.assessment_id,
  p.company_id AS profile_company,
  srv.company_id AS service_company
FROM fw_service_control_assessment a
JOIN fw_profile p ON p.profile_id = a.profile_id
JOIN service srv ON srv.service_id = a.service_id
WHERE p.company_id <> srv.company_id;

-- Q53: Controlli presenti nel TARGET ma assenti nel CURRENT (per ASSET)
-- Utile per dimostrare che la gap analysis intercetta controlli mancanti.
SELECT
  tar.company_name,
  tar.asset_code,
  tar.control_code,
  tar.control_name
FROM (
  SELECT DISTINCT company_name, asset_code, control_code, control_name
  FROM v_fw_asset_profile_target
  WHERE subcategory_code IS NOT NULL
) tar
LEFT JOIN (
  SELECT DISTINCT company_name, asset_code, control_code
  FROM v_fw_asset_profile_current
  WHERE subcategory_code IS NOT NULL
) cur
ON cur.company_name = tar.company_name
AND cur.asset_code = tar.asset_code
AND cur.control_code = tar.control_code
WHERE cur.control_code IS NULL
ORDER BY tar.company_name, tar.asset_code, tar.control_code;

-- Q54: Controlli presenti nel TARGET ma assenti nel CURRENT (per SERVICE)
SELECT
  tar.company_name,
  tar.service_code,
  tar.control_code,
  tar.control_name
FROM (
  SELECT DISTINCT company_name, service_code, control_code, control_name
  FROM v_fw_service_profile_target
  WHERE subcategory_code IS NOT NULL
) tar
LEFT JOIN (
  SELECT DISTINCT company_name, service_code, control_code
  FROM v_fw_service_profile_current
  WHERE subcategory_code IS NOT NULL
) cur
ON cur.company_name = tar.company_name
AND cur.service_code = tar.service_code
AND cur.control_code = tar.control_code
WHERE cur.control_code IS NULL
ORDER BY tar.company_name, tar.service_code, tar.control_code;

-- Q55: Copertura media per funzione del Framework (ASSET)
-- Mostra il livello medio di implementazione CURRENT/TARGET
-- aggregato per funzione (ID, PR, DE, RS, RC)

SELECT
  company_name,
  profile_type,
  function_code,
  ROUND(AVG(coverage)::numeric, 2) AS avg_coverage,
  ROUND(AVG(maturity)::numeric, 2) AS avg_maturity,
  COUNT(DISTINCT control_code) AS controls_considered
FROM v_fw_asset_profile_detail
WHERE subcategory_code IS NOT NULL
GROUP BY company_name, profile_type, function_code
ORDER BY company_name, profile_type, function_code;

-- Q56: Copertura media per funzione del Framework (SERVICE)

SELECT
  company_name,
  profile_type,
  function_code,
  ROUND(AVG(coverage)::numeric, 2) AS avg_coverage,
  ROUND(AVG(maturity)::numeric, 2) AS avg_maturity,
  COUNT(DISTINCT control_code) AS controls_considered
FROM v_fw_service_profile_detail
WHERE subcategory_code IS NOT NULL
GROUP BY company_name, profile_type, function_code
ORDER BY company_name, profile_type, function_code;

-- ---------------------------------------------------------
-- K) VALIDAZIONE INCIDENTI (NIS2 - incident management & notification)
-- Scopo: dimostrare che il modulo incidenti supporta:
--   - registrazione incidenti significativi
--   - associazione ad asset impattati (N-M)
--   - tracciamento delle notifiche (24h / 72h / 1 mese)
--   - coerenza company tra incident e asset collegati
-- ---------------------------------------------------------

-- Q57: Conteggio incidenti, collegamenti incident-asset e notifiche
SELECT COUNT(*) AS incidents
FROM incident;

SELECT COUNT(*) AS incident_asset_links
FROM incident_asset;

SELECT COUNT(*) AS incident_notifications
FROM incident_notification;

-- Q58: Incidenti significativi (flag) e loro stato
SELECT
  i.incident_code,
  i.severity,
  i.status,
  i.detected_at,
  i.closed_at
FROM incident i
WHERE i.is_significant = TRUE
ORDER BY i.detected_at DESC, i.incident_code;

-- Q59: Incidenti significativi senza alcuna notifica (NON dovrebbe accadere in un processo maturo)
-- Utile come controllo di completezza del processo di notifica.
SELECT
  co.name AS company_name,
  i.incident_code,
  i.severity,
  i.status,
  i.detected_at
FROM incident i
JOIN company co ON co.company_id = i.company_id
LEFT JOIN incident_notification n ON n.incident_id = i.incident_id
WHERE i.is_significant = TRUE
GROUP BY co.name, i.incident_id, i.incident_code, i.severity, i.status, i.detected_at
HAVING COUNT(n.notification_id) = 0
ORDER BY co.name, i.detected_at DESC;

-- Q60: Verifica unicità notifiche per tipo (vincolo UNIQUE dovrebbe impedire duplicati)
-- Se torna righe, significa che esistono più notifiche dello stesso tipo per lo stesso incidente.
SELECT incident_id, notification_type, COUNT(*) AS cnt
FROM incident_notification
GROUP BY incident_id, notification_type
HAVING COUNT(*) > 1;

-- Q61: Notifiche inviate oltre la scadenza (sent_at > due_at) - dovrebbe tornare 0 righe nei casi corretti
SELECT
  co.name AS company_name,
  i.incident_code,
  n.notification_type,
  n.due_at,
  n.sent_at,
  (n.sent_at - n.due_at) AS delay
FROM incident_notification n
JOIN incident i ON i.incident_id = n.incident_id
JOIN company co ON co.company_id = i.company_id
WHERE n.sent_at IS NOT NULL
  AND n.due_at IS NOT NULL
  AND n.sent_at > n.due_at
ORDER BY co.name, i.incident_code, n.notification_type;

-- Q62: Incidenti significativi senza EARLY WARNING 24h (controllo "processo")
-- Nota: non impone che sia SENT, controlla che esista almeno la notifica di tipo EARLY_24H.
SELECT
  co.name AS company_name,
  i.incident_code,
  i.detected_at
FROM incident i
JOIN company co ON co.company_id = i.company_id
LEFT JOIN incident_notification n
  ON n.incident_id = i.incident_id
 AND n.notification_type = 'EARLY_24H'
WHERE i.is_significant = TRUE
  AND n.notification_id IS NULL
ORDER BY co.name, i.detected_at DESC;

-- Q63: Coerenza company tra incident e asset collegati (dovrebbe tornare 0 righe)
-- (il trigger già la impedisce, ma questa query è "evidence" per la tesi)
SELECT
  ia.incident_id,
  i.company_id AS incident_company,
  ia.asset_id,
  a.company_id AS asset_company
FROM incident_asset ia
JOIN incident i ON i.incident_id = ia.incident_id
JOIN asset a ON a.asset_id = ia.asset_id
WHERE i.company_id <> a.company_id;

-- Q64: Asset più impattati (numero di incidenti associati) - utile per report
SELECT
  co.name AS company_name,
  a.asset_code,
  a.name AS asset_name,
  COUNT(DISTINCT ia.incident_id) AS incidents_count
FROM incident_asset ia
JOIN incident i ON i.incident_id = ia.incident_id
JOIN company co ON co.company_id = i.company_id
JOIN asset a ON a.asset_id = ia.asset_id
GROUP BY co.name, a.asset_code, a.name
ORDER BY incidents_count DESC, a.asset_code;
-- Fine file
