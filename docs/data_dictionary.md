# Data Dictionary – Database NIS2 / ACN

Questo documento descrive la struttura del database progettato per il Project Work 19, illustrando per ciascuna tabella lo scopo, le chiavi, le relazioni e il significato dei singoli campi. 
Il data dictionary costituisce un supporto alla comprensione del modello dati ed è utilizzato come riferimento per la progettazione, la validazione e l’utilizzo delle query e delle viste di estrazione in ambito NIS2/ACN.

---

## Tabella: `company`

**Scopo**  
Consente di associare asset, servizi e contatti a un contesto aziendale e rende il modello estendibile a più aziende.

**Chiave primaria**
- `company_id`

**Relazioni**
- Referenziata da: `contact`, `asset`, `service`

**Campi**
- `company_id` (BIGSERIAL, PK, NOT NULL) – Identificativo univoco dell’azienda.
- `name` (VARCHAR, NOT NULL, UNIQUE) – Denominazione dell’azienda.
- `vat_number` (VARCHAR, NULL) – Partita IVA / codice fiscale.
- `sector` (VARCHAR, NULL) – Settore di attività.
- `country` (VARCHAR, NULL) – Paese dell’azienda.
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT now()) – Data di creazione del record.

---

## Tabella: `contact`

**Scopo**  
Rappresenta un responsabile o punto di contatto interno (es. IT Manager, Security Officer).

**Chiave primaria**
- `contact_id`

**Chiavi esterne**
- `company_id` → `company(company_id)` (ON DELETE CASCADE)

**Relazioni**
- Referenziata da: `asset.owner_contact_id`, `service.service_owner_contact_id`

**Campi**
- `contact_id` (BIGSERIAL, PK, NOT NULL) – Identificativo univoco del contatto.
- `company_id` (BIGINT, FK, NOT NULL) – Azienda di appartenenza.
- `full_name` (VARCHAR, NOT NULL) – Nome e cognome del responsabile.
- `role_title` (VARCHAR, NULL) – Ruolo o qualifica.
- `email` (VARCHAR, NULL) – Indirizzo email.
- `phone` (VARCHAR, NULL) – Numero di telefono.
- `is_primary_poc` (BOOLEAN, NOT NULL, DEFAULT false) – Indica se il contatto è punto di riferimento principale.
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT now()) – Data di creazione del record.

**Nota progettuale**  
L’associazione con asset e servizi è opzionale; in caso di eliminazione del contatto, i riferimenti vengono impostati a NULL (vedi `ON DELETE SET NULL`) per evitare la cancellazione dei dati tecnici.

---

## Tabella: `provider`

**Scopo**  
Rappresenta un fornitore terzo (cloud provider, ISP, software house, manutentore) coinvolto nell’erogazione dei servizi.

**Chiave primaria**
- `provider_id`

**Relazioni**
- Collegata ai servizi tramite la tabella associativa `service_provider`

**Campi**
- `provider_id` (BIGSERIAL, PK, NOT NULL) – Identificativo univoco del fornitore.
- `name` (VARCHAR, NOT NULL, UNIQUE) – Nome del fornitore.
- `provider_type` (VARCHAR, NULL) – Tipologia di fornitore.
- `country` (VARCHAR, NULL) – Paese del fornitore.
- `email` (VARCHAR, NULL) – Email di contatto.
- `phone` (VARCHAR, NULL) – Numero di telefono.
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT now()) – Data di creazione del record.

---

## Tabella: `asset`

**Scopo**  
Rappresenta un bene informatico o tecnologico rilevante per l’organizzazione (server, database, dispositivi di rete, risorse cloud).

**Chiave primaria**
- `asset_id`

**Chiavi esterne**
- `company_id` → `company(company_id)` (ON DELETE CASCADE)  
- `owner_contact_id` → `contact(contact_id)` (ON DELETE SET NULL)

**Vincoli principali**
- `UNIQUE (company_id, asset_code)` – Codice asset univoco per azienda.  
- `CHECK (criticality BETWEEN 1 AND 5)` – Valori ammessi per la criticità.  
- `CHECK (status IN ('ACTIVE','INACTIVE','RETIRED'))` – Stati ammessi.

**Campi**
- `asset_id` (BIGSERIAL, PK, NOT NULL) – Identificativo univoco dell’asset.
- `company_id` (BIGINT, FK, NOT NULL) – Azienda proprietaria.
- `asset_code` (VARCHAR(40), NOT NULL) – Codice interno dell’asset.
- `name` (VARCHAR(200), NOT NULL) – Nome descrittivo dell’asset.
- `asset_type` (VARCHAR(60), NOT NULL) – Tipologia (hardware, software, network, cloud).
- `description` (TEXT, NULL) – Descrizione dell’asset.
- `location` (VARCHAR(200), NULL) – Collocazione fisica o logica.
- `owner_contact_id` (BIGINT, FK, NULL) – Responsabile interno dell’asset.
- `criticality` (SMALLINT, NOT NULL, DEFAULT 3) – Livello di criticità (1–5).
- `status` (VARCHAR(30), NOT NULL, DEFAULT 'ACTIVE') – Stato dell’asset.
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT now()) – Data di creazione.
- `updated_at` (TIMESTAMPTZ, NOT NULL, DEFAULT now()) – Data ultimo aggiornamento.

---

## Tabella: `service`

**Scopo**  
Rappresenta un servizio IT/digitale erogato o utilizzato dall’organizzazione (portale clienti, email, fatturazione, autenticazione, ecc.).

**Chiave primaria**
- `service_id`

**Chiavi esterne**
- `company_id` → `company(company_id)` (ON DELETE CASCADE)  
- `service_owner_contact_id` → `contact(contact_id)` (ON DELETE SET NULL)

**Vincoli principali**
- `UNIQUE (company_id, service_code)` – Codice servizio univoco per azienda.  
- `CHECK (criticality BETWEEN 1 AND 5)` – Valori ammessi per la criticità.  
- `CHECK (status IN ('ACTIVE','INACTIVE','RETIRED'))` – Stati ammessi.

**Campi**
- `service_id` (BIGSERIAL, PK, NOT NULL) – Identificativo univoco del servizio.
- `company_id` (BIGINT, FK, NOT NULL) – Azienda proprietaria.
- `service_code` (VARCHAR(40), NOT NULL) – Codice interno del servizio (es. SVC-CRM).
- `name` (VARCHAR(200), NOT NULL) – Nome del servizio (es. “Portale Clienti”).
- `description` (TEXT, NULL) – Descrizione del servizio.
- `service_owner_contact_id` (BIGINT, FK, NULL) – Responsabile del servizio.
- `criticality` (SMALLINT, NOT NULL, DEFAULT 3) – Livello di criticità (1–5).
- `status` (VARCHAR(30), NOT NULL, DEFAULT 'ACTIVE') – Stato del servizio.
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT now()) – Data di creazione.
- `updated_at` (TIMESTAMPTZ, NOT NULL, DEFAULT now()) – Data ultimo aggiornamento.

**Indici (supporto alle query)** 
- `idx_service_company` su `company_id` per il filtraggio dei servizi per azienda.
- `idx_service_owner` su `service_owner_contact_id` per l’analisi delle responsabilità.
- `idx_service_criticality` su `criticality` per l’individuazione rapida dei servizi critici.

---

## Tabella associativa: `service_asset`

**Scopo**  
Modella la relazione molti-a-molti tra servizi e asset, rappresentando le dipendenze tecniche necessarie all’erogazione dei servizi.

**Chiave primaria**
- (`service_id`, `asset_id`)

**Chiavi esterne**
- `service_id` → `service(service_id)` (ON DELETE CASCADE)  
- `asset_id` → `asset(asset_id)` (ON DELETE RESTRICT) Un asset che supporta ancora un servizio non deve poter sparire.

**Campi**
- `service_id` (BIGINT, FK, NOT NULL) – Servizio coinvolto.
- `asset_id` (BIGINT, FK, NOT NULL) – Asset utilizzato.
- `usage_role` (VARCHAR(120), NULL) – Ruolo dell’asset nel servizio.
- `is_critical_dependency` (BOOLEAN, NOT NULL, DEFAULT true) – Indica se la dipendenza è considerata critica.
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT now()) – Data di creazione del record.

**Indice (supporto alle query)**
- `idx_sa_asset` su `asset_id`

---

## Tabella associativa: `service_provider`

**Scopo**  
Modella la relazione molti-a-molti tra servizi e fornitori terzi, descrivendo le dipendenze esterne (es. hosting, connettività, supporto).

**Chiave primaria**
- (`service_id`, `provider_id`, `dependency_type`)

**Chiavi esterne**
- `service_id` → `service(service_id)` (ON DELETE CASCADE)  
- `provider_id` → `provider(provider_id)` (ON DELETE RESTRICT) Non puoi eliminare un fornitore se è ancora una dipendenza attiva.

**Campi**
- `service_id` (BIGINT, FK, NOT NULL) – Servizio coinvolto.
- `provider_id` (BIGINT, FK, NOT NULL) – Fornitore coinvolto.
- `dependency_type` (VARCHAR(120), NOT NULL) – Tipo di dipendenza.
- `contract_id` (VARCHAR(80), NULL) – Identificativo del contratto (se disponibile).
- `sla_notes` (VARCHAR(200), NULL) – Note relative agli SLA.
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT now()) – Data di creazione del record.

**Indice (supporto alle query)**
- `idx_sp_provider` su `provider_id`

---

## Tabella: `asset_history`

**Scopo**  
Conserva lo storico delle versioni degli asset, consentendo la tracciabilità delle modifiche nel tempo a fini di audit e compliance.

**Chiave primaria**
- `history_id`

**Relazione logica**
- `asset_id` identifica l’asset a cui la versione si riferisce (collegamento logico con `asset.asset_id`).  
  *(Nota: nel CREATE TABLE non è definita una FK esplicita su `asset_id`.)* Anche se un asset viene cancellato, lo storico relativo resta.

**Campi**
- `history_id` (BIGSERIAL, PK, NOT NULL) – Identificativo univoco della versione storica.
- `asset_id` (BIGINT, NOT NULL) – Identificativo dell’asset versionato.
- `company_id` (BIGINT, NOT NULL) – Azienda di riferimento.
- `asset_code` (VARCHAR(40), NOT NULL) – Codice asset della versione.
- `name` (VARCHAR(200), NOT NULL) – Nome asset della versione.
- `asset_type` (VARCHAR(60), NOT NULL) – Tipologia asset della versione.
- `description` (TEXT, NULL) – Descrizione.
- `location` (VARCHAR(200), NULL) – Collocazione.
- `owner_contact_id` (BIGINT, NULL) – Responsabile associato alla versione.
- `criticality` (SMALLINT, NOT NULL) – Criticità della versione.
- `status` (VARCHAR(30), NOT NULL) – Stato della versione.
- `valid_from` (TIMESTAMPTZ, NOT NULL) – Inizio validità della versione.
- `valid_to` (TIMESTAMPTZ, NULL) – Fine validità (NULL se versione non “chiusa”).
- `changed_by` (VARCHAR(120), NULL) – Utente/sistema che ha effettuato la modifica.
- `change_reason` (VARCHAR(200), NULL) – Motivazione o descrizione della modifica.
- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT now()) – Data di inserimento nello storico.

**Indici (supporto alle query)**
- `idx_asset_history_asset` su `asset_id`
- `idx_asset_history_company` su `company_id`

---

# Modulo Framework

## Tabella: `fw_subcategory`

**Scopo**
Rappresenta le subcategory del Core del Framework Nazionale per la cybersecurity (requisiti standardizzati) utilizzate per la costruzione dei profili di sicurezza.

**Chiave primaria**

- `subcategory_id`

**Vincoli principali**

UNIQUE (code) – Codice univoco della subcategory.

**Campi**

- `subcategory_id` (BIGSERIAL, PK, NOT NULL) – Identificativo univoco della subcategory.

- `code` (VARCHAR(20), NOT NULL, UNIQUE) – Codice della subcategory (es. PR.AC-1).

- `name` (VARCHAR(200), NOT NULL) – Nome sintetico della subcategory.

- `description` (TEXT, NULL) – Descrizione estesa del requisito.

- `function_code` (VARCHAR(5), NOT NULL) – Codice funzione (es. ID, PR, DE, RS, RC).

- `category_code` (VARCHAR(20), NOT NULL) – Codice categoria (es. PR.AC).

**Indici (supporto alle query)**

- `idx_fw_subcategory_function` su `function_code`

- `idx_fw_subcategory_category` su `category_code`

---

## Tabella: `fw_control`

**Scopo**
Catalogo dei controlli di sicurezza (misure organizzative/tecniche) adottabili dall’organizzazione, utilizzati per mappare e soddisfare i requisiti (subcategory) del Framework Nazionale.

**Chiave primaria**

- `control_id`

**Vincoli principali**

UNIQUE (code) – Codice univoco del controllo.

**Campi**

- `control_id` (BIGSERIAL, PK, NOT NULL) – Identificativo univoco del controllo.

- `code` (VARCHAR(30), NOT NULL, UNIQUE) – Codice del controllo (es. CTRL-IAM).

- `name` (VARCHAR(200), NOT NULL) – Nome del controllo (es. “Gestione identità e accessi”).

- `description` (TEXT, NULL) – Descrizione del controllo.

---

## Tabella associativa: `fw_control_subcategory`

**Scopo**
Modella la relazione molti-a-molti tra controlli e subcategory. Un controllo può contribuire a più subcategory e una subcategory può essere coperta da più controlli.

**Chiave primaria**

- `(control_id, subcategory_id)`

**Chiavi esterne**

- `control_id` → fw_control(control_id) (ON DELETE CASCADE)

- `subcategory_id` → fw_subcategory(subcategory_id) (ON DELETE CASCADE)

**Campi**

- `control_id` (BIGINT, FK, NOT NULL) – Controllo associato.

- `subcategory_id` (BIGINT, FK, NOT NULL) – Subcategory associata.

**Indice (supporto alle query)**

- `idx_fw_ctrl_subcat_subcat` su `subcategory_id`

---

## Tabella: `fw_profile`

**Scopo**
Rappresenta un profilo di sicurezza per una specifica azienda, distinguendo tra profilo attuale (CURRENT) e profilo target (TARGET).

**Chiave primaria**

- `profile_id`

**Chiavi esterne**

- `company_id` → company(company_id) (ON DELETE CASCADE)

**Vincoli principali**

- `CHECK (profile_type IN ('CURRENT','TARGET'))` – Tipi ammessi di profilo.

- `UNIQUE (company_id, profile_type)` – Per ogni azienda sono ammessi al massimo un profilo CURRENT e un profilo TARGET.

**Campi**

- `profile_id` (BIGSERIAL, PK, NOT NULL) – Identificativo univoco del profilo.

- `company_id` (BIGINT, FK, NOT NULL) – Azienda a cui il profilo si riferisce.

- `profile_type` (VARCHAR(10), NOT NULL) – Tipo profilo (CURRENT / TARGET).

- `created_at` (TIMESTAMPTZ, NOT NULL, DEFAULT now()) – Data creazione del profilo.

- `notes` (TEXT, NULL) – Note descrittive sul profilo.

**Indice (supporto alle query)**

- `idx_fw_profile_company` su `company_id`

---

## Tabella: `fw_asset_control_assessment`

**Scopo**
Registra la valutazione (assessment) del livello di implementazione dei controlli di sicurezza sugli asset, nell’ambito di un profilo (CURRENT/TARGET).
La valutazione utilizza:

coverage (copertura del controllo)

maturity (livello di maturità del controllo)

**Chiave primaria**

- `assessment_id`

**Chiavi esterne**

- `profile_id` → fw_profile(profile_id) (ON DELETE CASCADE)

- `asset_id` → asset(asset_id) (ON DELETE CASCADE)

- `control_id` → fw_control(control_id) (ON DELETE CASCADE)

**Vincoli principali**

- `UNIQUE (profile_id, asset_id, control_id)` – Evita duplicati per lo stesso asset/controllo nello stesso profilo.

- `CHECK (coverage IN (0.0,0.2,0.4,0.6,0.8,1.0))` – Valori ammessi per la copertura.

- `CHECK (maturity BETWEEN 1 AND 5)` – Valori ammessi per la maturità (se presente).

Vincolo logico: se coverage = 0.0 allora maturity deve essere NULL (non applicabile).

**Campi**

- `assessment_id` (BIGSERIAL, PK, NOT NULL) – Identificativo univoco della valutazione.

- `profile_id` (BIGINT, FK, NOT NULL) – Profilo di riferimento (CURRENT/TARGET).

- `asset_id` (BIGINT, FK, NOT NULL) – Asset valutato.

- `control_id` (BIGINT, FK, NOT NULL) – Controllo valutato.

- `coverage` (NUMERIC(2,1), NOT NULL) – Copertura del controllo (0.0–1.0 a step 0.2).

- `maturity` (SMALLINT, NULL) – Livello maturità (1–5), NULL se coverage=0.

- `notes` (TEXT, NULL) – Note dell’assessment.

- `evidence` (TEXT, NULL) – Evidenze a supporto (documenti, configurazioni, procedure).

- `updated_at` (TIMESTAMPTZ, NOT NULL, DEFAULT now()) – Timestamp ultimo aggiornamento.

**Indici (supporto alle query)**

- `idx_fw_asset_assessment_profile su profile_id`

- `idx_fw_asset_assessment_asset su asset_id`

- `idx_fw_asset_assessment_control su control_id`

---

## Tabella: `fw_service_control_assessment`

**Scopo**
Registra la valutazione (assessment) del livello di implementazione dei controlli di sicurezza sui servizi, nell’ambito di un profilo (CURRENT/TARGET), con gli stessi criteri di coverage e maturity utilizzati per gli asset.

**Chiave primaria**

- `assessment_id`

**Chiavi esterne**

- `profile_id` → fw_profile(profile_id) (ON DELETE CASCADE)

- `service_id` → service(service_id) (ON DELETE CASCADE)

- `control_id` → fw_control(control_id) (ON DELETE CASCADE)

**Vincoli principali**

- `UNIQUE (profile_id, service_id, control_id)` – Evita duplicati per lo stesso servizio/controllo nello stesso profilo.

- `CHECK (coverage IN (0.0,0.2,0.4,0.6,0.8,1.0))`

- `CHECK (maturity BETWEEN 1 AND 5)`

Vincolo logico: se coverage = 0.0 allora maturity deve essere NULL.

**Campi**

- `assessment_id` (BIGSERIAL, PK, NOT NULL) – Identificativo univoco della valutazione.

- `profile_id` (BIGINT, FK, NOT NULL) – Profilo di riferimento.

- `service_id` (BIGINT, FK, NOT NULL) – Servizio valutato.

- `control_id` (BIGINT, FK, NOT NULL) – Controllo valutato.

- `coverage` (NUMERIC(2,1), NOT NULL) – Copertura del controllo.

- `maturity` (SMALLINT, NULL) – Livello maturità (1–5), NULL se coverage=0.

- `notes` (TEXT, NULL) – Note dell’assessment.

- `evidence` (TEXT, NULL) – Evidenze a supporto.

- `updated_at` (TIMESTAMPTZ, NOT NULL, DEFAULT now()) – Timestamp ultimo aggiornamento.

**Indici (supporto alle query)**

- `idx_fw_service_assessment_profile su profile_id`

- `idx_fw_service_assessment_service su service_id`

- `idx_fw_service_assessment_control su control_id`

---
**Nota progettuale (Framework)**

Le tabelle `fw_subcategory` e `fw_control` rappresentano rispettivamente il riferimento normativo (requisiti) e il catalogo dei controlli applicabili. Il profilo (CURRENT/TARGET) è modellato tramite fw_profile. Gli assessment su asset e servizi consentono la produzione di viste SQL per l’export dei profili e la gap analysis (TARGET–CURRENT).

---
## Tabella: `incident`

Scopo
Registra gli eventi di sicurezza rilevati dall’organizzazione, in coerenza con gli obblighi previsti dalla Direttiva NIS2.
Consente di tracciare informazioni descrittive, stato dell’incidente, livello di gravità e indicazione di “incidente significativo” ai fini degli obblighi di notifica.

Chiave primaria

- `incident_id`

Relazioni

Referenziata da: incident_asset, incident_notification

FK verso: company

Campi

- `incident_id` (BIGSERIAL, PK, NOT NULL) – Identificativo univoco dell’incidente.

- `company_id` (BIGINT, FK, NOT NULL) – Azienda a cui l’incidente è associato.

- `incident_code` (VARCHAR, NOT NULL) – Codice identificativo leggibile (es. INC-2026-001), univoco per azienda.

- `title` (VARCHAR, NOT NULL) – Titolo sintetico dell’incidente.

- `description` (TEXT, NULL) – Descrizione dettagliata dell’evento.

- `detected_at` (TIMESTAMPTZ, NOT NULL) – Data e ora di rilevazione dell’incidente.

- `occurred_at` (TIMESTAMPTZ, NULL) – Data e ora presunta di accadimento.

- `closed_at` (TIMESTAMPTZ, NULL) – Data di chiusura dell’incidente.

- `severity` (VARCHAR, NOT NULL) – Livello di gravità (LOW, MEDIUM, HIGH, CRITICAL).

- `status` (VARCHAR, NOT NULL) – Stato corrente dell’incidente (OPEN, UNDER_ANALYSIS, CONTAINED, RESOLVED, CLOSED).

- `is_significant` (BOOLEAN, NOT NULL) – Indica se l’incidente è classificato come significativo ai fini NIS2.

- `notes` (TEXT, NULL) – Annotazioni interne.

---

## Tabella: `incident_asset`

Scopo
Modella la relazione molti-a-molti tra incidenti e asset.
Consente di indicare quali asset siano stati coinvolti o impattati da uno specifico evento di sicurezza.

Chiave primaria

- `(incident_id, asset_id)`

Relazioni

FK verso: incident

FK verso: asset

Campi

- `incident_id` (BIGINT, PK, FK, NOT NULL) – Identificativo dell’incidente.

- `asset_id` (BIGINT, PK, FK, NOT NULL) – Identificativo dell’asset coinvolto.

- `impact_type` (VARCHAR, NULL) – Tipo di impatto (CONFIDENTIALITY, INTEGRITY, AVAILABILITY, OTHER).

- `impact_notes` (TEXT, NULL) – Descrizione dell’impatto sull’asset.

---

## Tabella: `incident_notification`

Scopo
Traccia le notifiche inviate all’autorità competente (es. ACN) in relazione a un incidente significativo, in conformità agli obblighi di notifica previsti dalla NIS2.

Chiave primaria

- `notification_id`

Relazioni

FK verso: incident

Campi

- `notification_id` (BIGSERIAL, PK, NOT NULL) – Identificativo univoco della notifica.

- `incident_id` (BIGINT, FK, NOT NULL) – Incidente a cui la notifica si riferisce.

- `notification_type` (VARCHAR, NOT NULL) – Tipologia di notifica (EARLY_24H, FULL_72H, FINAL_1M).

- `authority` (VARCHAR, NOT NULL) – Autorità destinataria (default: ACN).

- `status` (VARCHAR, NOT NULL) – Stato della notifica (DRAFT, SENT, ACKNOWLEDGED, CANCELLED).

- `due_at` (TIMESTAMPTZ, NULL) – Scadenza teorica prevista per l’invio.

- `sent_at` (TIMESTAMPTZ, NULL) – Data e ora effettiva di invio.

- `reference_code` (VARCHAR, NULL) – Codice o protocollo assegnato dall’autorità.

- `content_summary` (TEXT, NULL) – Sintesi del contenuto trasmesso.
