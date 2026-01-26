-- =========================================================
-- 05_queries_validation.sql
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
WHERE ah.asset_code = 'DB-001'
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

-- Fine file
