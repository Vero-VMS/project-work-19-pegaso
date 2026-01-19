# PW19 – Database NIS2/ACN (Registro asset, servizi, dipendenze e responsabilità)

Questo repository contiene il progetto di una base dati relazionale realizzata per il Project Work 19 del corso di laurea in Informatica (Pegaso), finalizzato alla progettazione di un registro centralizzato per la gestione degli asset, dei servizi, delle dipendenze da fornitori terzi e delle responsabilità organizzative, in conformità ai requisiti della direttiva NIS2 e ai profili richiesti dall’Agenzia per la Cybersicurezza Nazionale (ACN).

L’obiettivo del progetto è fornire una struttura dati coerente e normalizzata che consenta di:
- mantenere un inventario centralizzato degli asset e dei servizi critici;
- modellare le dipendenze tecniche e contrattuali da terze parti;
- associare ruoli e responsabilità organizzative;
- supportare attività di audit, controllo e compilazione dei profili ACN tramite viste e query di estrazione.

---

## Diagramma ER

Il seguente diagramma rappresenta il modello concettuale (Entità-Relazione) del database progettato per il Project Work 19, comprendente le entità principali, le relazioni e le tabelle associative utilizzate per modellare asset, servizi, dipendenze e responsabilità.

![Schema ER](docs/pw19_diagram_er.png)

---

## Struttura del repository

Il repository è organizzato nei seguenti file:

- `01_create_tables.sql`  
  Creazione delle tabelle principali (company, contact, asset, service, provider) e delle tabelle associative, con definizione di chiavi primarie, chiavi esterne e vincoli di integrità.

- `02_triggers_versioning.sql`  
  Definizione dei trigger e delle funzioni per la storicizzazione automatica degli asset e la gestione dello storico nella tabella `asset_history`.

- `03_insert_test_data.sql`  
  Popolamento del database con dati di test per la validazione dello schema e dei vincoli di integrità.

- `04_views_and_exports.sql`  
  Creazione di viste e query di estrazione per la produzione di output strutturati, esportabili in formato CSV, utili alla compilazione dei profili ACN.

- `05_queries_validation.sql`  
  Insieme di query di validazione per verificare la correttezza del modello dati, delle relazioni e delle dipendenze.

- `docs/data_dictionary.md`  
  Dizionario dei dati contenente la descrizione dettagliata di tutte le tabelle, degli attributi, delle chiavi e dei vincoli del modello relazionale.

- `docs/pw19_diagram_er.png`  
  Diagramma Entità-Relazione del database.


---

## Tecnologie utilizzate

- Database: PostgreSQL  
- Linguaggio: SQL (DDL, DML, trigger in PL/pgSQL)

---

## Esecuzione
1. Crea un database vuoto (es. `pw19_nis2`).
2. Esegui in ordine gli script:
   - `01_create_tables.sql` Creazione delle tabelle e dei vincoli.
   - `02_triggers_versioning.sql` Creazione dei trigger e delle funzioni per il versioning.
   - `03_insert_test_data.sql` Inserimento dei dati di test.
   - `04_views_and_exports.sql` Creazione delle viste e delle query di esportazione.

Al termine dell’esecuzione il database risulta pronto per l’interrogazione e per la produzione di output strutturati.
Il file `05_queries_validation.sql` contiene un insieme di query di validazione e di esempio, utilizzate per verificare la correttezza del modello dati e delle relazioni, ma non è necessario alla fase di inizializzazione del database.

---

## Contesto normativo

Il progetto si colloca nel contesto della direttiva europea NIS2 e delle indicazioni dell’Agenzia per la Cybersicurezza Nazionale (ACN) per la gestione degli asset, dei servizi critici e delle dipendenze da fornitori terzi.

---

## Riferimenti

- Direttiva (UE) 2022/2555 (NIS2) – Parlamento Europeo e Consiglio dell’Unione Europea  
- Agenzia per la Cybersicurezza Nazionale (ACN): https://www.acn.gov.it  
- Documentazione PostgreSQL: https://www.postgresql.org/docs/



