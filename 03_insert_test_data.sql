-- =========================================================
-- PW19 - Dati di test (simulati)
-- File: 03_insert_test_data.sql
-- Scopo: inserire un dataset fittizio per verificare:
--        - corretto popolamento delle tabelle
--        - rispetto dei vincoli di integrità (PK/FK, vincoli, ecc.)
--        - funzionamento delle query e delle viste di estrazione
-- Vengono usate subquery/SELECT per recuperare gli ID generati,
--       così lo script resta riproducibile anche su database “vuoti”.
-- =========================================================

-- 1) Azienda
INSERT INTO company (name, vat_number, sector, country)
VALUES ('Azienda Demo S.p.A.', 'IT12345678901', 'Servizi digitali', 'Italia');

-- Recupero company_id tramite SELECT:
-- in questo modo non devo inserire manualmente l’ID e lo script resta eseguibile
-- indipendentemente dai valori generati automaticamente dal database.
-- 2) Contatti / Responsabili
INSERT INTO contact (company_id, full_name, role_title, email, phone, is_primary_poc)
SELECT company_id, 'Giulia Rossi', 'IT Manager', 'giulia.rossi@demo.it', '+39 02 0000001', TRUE
FROM company WHERE name='Azienda Demo S.p.A.';

INSERT INTO contact (company_id, full_name, role_title, email, phone, is_primary_poc)
SELECT company_id, 'Marco Bianchi', 'Security Officer (CISO)', 'marco.bianchi@demo.it', '+39 02 0000002', FALSE
FROM company WHERE name='Azienda Demo S.p.A.';

INSERT INTO contact (company_id, full_name, role_title, email, phone, is_primary_poc)
SELECT company_id, 'Sara Verdi', 'Service Owner - Portale Clienti', 'sara.verdi@demo.it', '+39 02 0000003', FALSE
FROM company WHERE name='Azienda Demo S.p.A.';

-- 3) Fornitori
INSERT INTO provider (name, provider_type, country, email, phone)
VALUES
  ('CloudOne', 'Cloud provider', 'Italia', 'support@cloudone.example', '+39 02 1111111'),
  ('NetFast', 'ISP / Connettività', 'Italia', 'noc@netfast.example', '+39 02 2222222'),
  ('SoftMaintain', 'Software house / Supporto', 'Italia', 'help@softmaintain.example', '+39 02 3333333');

-- 4) Asset
-- Gli asset vengono collegati all’azienda (company_id) e a un responsabile (owner_contact_id).
-- owner_contact_id viene recuperato con una subquery sulla tabella contact, per evitare valori scritti a mano nel codice e rendere lo script eseguibile anche su database vuoti o appena creati.
-- Asset_type è un valore testuale (es. HARDWARE/SOFTWARE/NETWORK/CLOUD/OTHER) usato per classificare l’asset.
INSERT INTO asset (company_id, asset_code, name, asset_type, description, location, owner_contact_id, criticality, status)
SELECT c.company_id, 'SRV-001', 'Server Applicativo', 'HARDWARE',
       'Server fisico dedicato alle applicazioni core', 'Data Center Milano',
       (SELECT contact_id FROM contact WHERE full_name='Giulia Rossi' AND c.company_id=contact.company_id),
       4, 'ACTIVE'
FROM company c WHERE c.name='Azienda Demo S.p.A.';

INSERT INTO asset (company_id, asset_code, name, asset_type, description, location, owner_contact_id, criticality, status)
SELECT c.company_id, 'DB-001', 'Database Produzione', 'SOFTWARE',
       'Database relazionale per dati transazionali', 'Data Center Milano',
       (SELECT contact_id FROM contact WHERE full_name='Giulia Rossi' AND c.company_id=contact.company_id),
       5, 'ACTIVE'
FROM company c WHERE c.name='Azienda Demo S.p.A.';

INSERT INTO asset (company_id, asset_code, name, asset_type, description, location, owner_contact_id, criticality, status)
SELECT c.company_id, 'NET-001', 'Firewall Perimetrale', 'NETWORK',
       'Dispositivo di sicurezza perimetrale', 'Sede Centrale',
       (SELECT contact_id FROM contact WHERE full_name='Marco Bianchi' AND c.company_id=contact.company_id),
       5, 'ACTIVE'
FROM company c WHERE c.name='Azienda Demo S.p.A.';

INSERT INTO asset (company_id, asset_code, name, asset_type, description, location, owner_contact_id, criticality, status)
SELECT c.company_id, 'CLD-001', 'Storage Cloud', 'CLOUD',
       'Storage per backup e archiviazione', 'CloudOne - Region EU',
       (SELECT contact_id FROM contact WHERE full_name='Marco Bianchi' AND c.company_id=contact.company_id),
       4, 'ACTIVE'
FROM company c WHERE c.name='Azienda Demo S.p.A.';

-- 5) Servizi
-- I servizi sono collegati all’azienda e a un responsabile (service_owner_contact_id).
-- Anche in questo caso l’ID del contatto viene recuperato tramite subquery.
INSERT INTO service (company_id, service_code, name, description, service_owner_contact_id, criticality, status)
SELECT c.company_id, 'SVC-PORT', 'Portale Clienti',
       'Servizio web per accesso clienti e consultazione dati',
       (SELECT contact_id FROM contact WHERE full_name='Sara Verdi' AND c.company_id=contact.company_id),
       5, 'ACTIVE'
FROM company c WHERE c.name='Azienda Demo S.p.A.';

INSERT INTO service (company_id, service_code, name, description, service_owner_contact_id, criticality, status)
SELECT c.company_id, 'SVC-EMAIL', 'Servizio Email',
       'Servizio di posta elettronica aziendale',
       (SELECT contact_id FROM contact WHERE full_name='Giulia Rossi' AND c.company_id=contact.company_id),
       4, 'ACTIVE'
FROM company c WHERE c.name='Azienda Demo S.p.A.';

-- 6) Collegamenti Servizio <-> Asset (tabella associativa)
-- Popolo la relazione molti-a-molti tra servizi e asset.
-- usage_role descrive come l’asset viene utilizzato dal servizio.
-- is_critical_dependency indica se l’asset è una dipendenza critica per l’erogazione del servizio.
INSERT INTO service_asset (service_id, asset_id, usage_role, is_critical_dependency)
SELECT s.service_id, a.asset_id, 'Web/App Server', TRUE
FROM service s, asset a
WHERE s.service_code='SVC-PORT' AND a.asset_code='SRV-001';

INSERT INTO service_asset (service_id, asset_id, usage_role, is_critical_dependency)
SELECT s.service_id, a.asset_id, 'Database', TRUE
FROM service s, asset a
WHERE s.service_code='SVC-PORT' AND a.asset_code='DB-001';

INSERT INTO service_asset (service_id, asset_id, usage_role, is_critical_dependency)
SELECT s.service_id, a.asset_id, 'Security Gateway', TRUE
FROM service s, asset a
WHERE s.service_code='SVC-PORT' AND a.asset_code='NET-001';

INSERT INTO service_asset (service_id, asset_id, usage_role, is_critical_dependency)
SELECT s.service_id, a.asset_id, 'Backup/Storage', TRUE
FROM service s, asset a
WHERE s.service_code='SVC-PORT' AND a.asset_code='CLD-001';

INSERT INTO service_asset (service_id, asset_id, usage_role, is_critical_dependency)
SELECT s.service_id, a.asset_id, 'Security Gateway', TRUE
FROM service s, asset a
WHERE s.service_code='SVC-EMAIL' AND a.asset_code='NET-001';

INSERT INTO service_asset (service_id, asset_id, usage_role, is_critical_dependency)
SELECT s.service_id, a.asset_id, 'Mailbox/Storage', TRUE
FROM service s, asset a
WHERE s.service_code='SVC-EMAIL' AND a.asset_code='CLD-001';

-- 7) Collegamenti Servizio <-> Fornitore (tabella associativa)
-- Popolo la relazione molti-a-molti tra servizi e fornitori.
-- dependency_type descrive la natura della dipendenza (es. hosting, connettività, supporto).
-- contract_id e sla_notes permettono di registrare informazioni contrattuali in modo sintetico.
INSERT INTO service_provider (service_id, provider_id, dependency_type, contract_id, sla_notes)
SELECT s.service_id, p.provider_id, 'Hosting', 'CTR-001', 'SLA 99.9%'
FROM service s, provider p
WHERE s.service_code='SVC-PORT' AND p.name='CloudOne';

INSERT INTO service_provider (service_id, provider_id, dependency_type, contract_id, sla_notes)
SELECT s.service_id, p.provider_id, 'Connettività', 'CTR-002', 'Linea primaria'
FROM service s, provider p
WHERE s.service_code='SVC-PORT' AND p.name='NetFast';

INSERT INTO service_provider (service_id, provider_id, dependency_type, contract_id, sla_notes)
SELECT s.service_id, p.provider_id, 'Supporto applicativo', 'CTR-003', 'Manutenzione correttiva'
FROM service s, provider p
WHERE s.service_code='SVC-PORT' AND p.name='SoftMaintain';

INSERT INTO service_provider (service_id, provider_id, dependency_type, contract_id, sla_notes)
SELECT s.service_id, p.provider_id, 'Connettività', 'CTR-002', 'Linea primaria'
FROM service s, provider p
WHERE s.service_code='SVC-EMAIL' AND p.name='NetFast';


-- 8) Test storicizzazione (asset_history)
-- Eseguo un aggiornamento controllato su un asset per generare almeno una riga nello storico,
-- così è possibile verificare concretamente il funzionamento del trigger di versioning.

-- 1° update: cambia la criticità (da 4 a 3)
UPDATE asset
SET criticality = 3
WHERE asset_code = 'SRV-001';

-- 2° update: cambia lo stato (da ACTIVE a INACTIVE)
UPDATE asset
SET status = 'INACTIVE'
WHERE asset_code = 'SRV-001';

