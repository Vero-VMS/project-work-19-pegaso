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

