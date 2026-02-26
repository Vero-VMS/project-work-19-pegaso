# PW19 – Database NIS2/ACN (Registro asset, servizi, dipendenze e responsabilità)

Questo repository contiene il progetto di una base dati relazionale realizzata per il Project Work 19 del corso di laurea in Informatica (Pegaso), finalizzato alla progettazione di un registro centralizzato per la gestione degli asset, dei servizi, delle dipendenze da fornitori terzi e delle responsabilità organizzative, in conformità ai requisiti della direttiva NIS2 e ai profili richiesti dall’Agenzia per la Cybersicurezza Nazionale (ACN).

L’obiettivo del progetto è fornire una struttura dati coerente e normalizzata che consenta di:
- mantenere un inventario centralizzato degli asset e dei servizi critici;
- modellare le dipendenze tecniche e contrattuali da terze parti;
- associare ruoli e responsabilità organizzative;
- supportare attività di audit, controllo e compilazione dei profili ACN tramite viste e query di estrazione;
- integrare un livello di assessment della sicurezza basato sul Framework Nazionale per la Cybersecurity, tramite la gestione di controlli, subcategory e profili attuale (CURRENT) e target (TARGET).

---

## Diagramma ER

Il seguente diagramma rappresenta il modello concettuale (Entità-Relazione) del database progettato per il Project Work 19, comprendente le entità principali, le relazioni e le tabelle associative utilizzate per modellare asset, servizi, dipendenze e responsabilità.
Il modello introduce un modulo di assessment del Framework Nazionale che collega asset e servizi ai controlli di sicurezza e alle subcategory normative, consentendo la generazione del profilo di sicurezza attuale e target.
Inoltre, il diagramma include un modulo dedicato alla gestione degli incidenti di sicurezza, progettato come estensione modulare coerente con gli obblighi previsti dalla Direttiva NIS2. Tale modulo consente di registrare eventi incidentali, associare gli asset coinvolti tramite un’entità associativa molti-a-molti e tracciare le notifiche verso l’autorità competente (es. ACN), in conformità ai requisiti di early warning e reporting previsti dalla normativa.

L’architettura complessiva mantiene una separazione logica tra:

- gestione inventariale e governance degli asset,

- assessment dei controlli secondo Framework,

- gestione reattiva degli incidenti.

Questa suddivisione consente modularità, riusabilità ed estensibilità futura del sistema.
![Schema ER](docs/PW19_DiagramER.png)

---

## Struttura del repository

Il repository è organizzato nei seguenti file:

- `01_create_tables.sql`
Creazione delle tabelle principali (company, contact, asset, service, provider) e delle tabelle associative, con definizione di chiavi primarie, chiavi esterne e vincoli di integrità.

- `02_triggers_versioning.sql`
Definizione dei trigger e delle funzioni per la storicizzazione automatica degli asset e la gestione dello storico nella tabella asset_history.

- `03_insert_test_data.sql`
Popolamento del database con dati di test per la validazione dello schema e dei vincoli di integrità.

- `04_framework_tables.sql`
Introduzione delle tabelle del Framework Nazionale: subcategory, controlli, mapping controllo–subcategory, profili CURRENT/TARGET e tabelle di assessment su asset e servizi.

- `05_framework_seed.sql`
Inserimento di un dataset dimostrativo per il framework (controlli, subcategory e valutazioni di sicurezza).

- `06_views_and_exports.sql`
Creazione di viste e query di estrazione per la produzione di output strutturati utili alla compilazione dei profili ACN.

- `07_framework_views.sql`
Viste dedicate alla generazione del profilo di sicurezza secondo il Framework Nazionale (profili CURRENT e TARGET e gap analysis).

- `08_incident_module.sql`
Introduzione del modulo di gestione degli incidenti di sicurezza, in coerenza con gli obblighi previsti dalla Direttiva NIS2. Il modulo consente di registrare eventi incidentali, associare gli asset coinvolti e tracciare le notifiche verso l’autorità competente (early warning 24h, notifica 72h, relazione finale).

- `08b_incident_seed.sql`
Inserimento di un dataset dimostrativo relativo a incidenti e notifiche, utile per verificare il corretto funzionamento delle relazioni e delle viste.

- `08c_incident_views.sql`
Viste dedicate alla reportistica degli incidenti e allo stato delle notifiche, utili per verificare la conformità temporale agli obblighi NIS2.

- `09_queries_validation.sql`
Insieme di query di validazione per verificare la correttezza del modello dati, delle relazioni e delle dipendenze.

- `docs/data_dictionary.md`
Dizionario dei dati contenente la descrizione dettagliata di tutte le tabelle, inclusi gli elementi del framework di sicurezza.

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

- `01_create_tables.sql` – Creazione delle tabelle e dei vincoli

- `02_triggers_versioning.sql` – Versioning degli asset

- `03_insert_test_data.sql` – Inserimento dati di test

- `04_framework_tables.sql` – Strutture del Framework Nazionale

- `05_framework_seed.sql` – Popolamento assessment sicurezza

- `06_views_and_exports.sql` – Viste ACN inventariali

- `07_framework_views.sql` – Viste profilo sicurezza e gap analysis

- `08_incident_module.sql` – Modulo gestione incidenti e notifiche NIS2  

- `08c_incident_views.sql` – Viste incidenti e stato notifiche  

- `08b_incident_seed.sql` – Dataset dimostrativo incidenti  

Al termine dell’esecuzione il database risulta pronto per l’interrogazione e per la produzione di output strutturati.

Il file `09_queries_validation.sql` contiene query di verifica e di esempio, utili per controllare la correttezza del modello dati ma non necessari alla fase di inizializzazione.

---

## Export CSV per profilo ACN

Le viste consentono di produrre output strutturati esportabili in formato CSV utili alla compilazione dei profili richiesti dall’Agenzia per la Cybersicurezza Nazionale (ACN).

In ambiente PostgreSQL è possibile esportare i risultati delle viste tramite il comando `\copy`, eseguito da client come psql o pgAdmin.

Esempio di esportazione del profilo minimo:

`\copy (SELECT * FROM v_acn_profile_min) TO 'acn_profile_min.csv' CSV HEADER;`

In modo analogo è possibile esportare:

Asset critici:
`\copy (SELECT * FROM v_acn_critical_assets) TO 'acn_critical_assets.csv' CSV HEADER;`

Servizi critici:
`\copy (SELECT * FROM v_acn_critical_services) TO 'acn_critical_services.csv' CSV HEADER;`

Dipendenze tecniche servizio–asset:
`\copy (SELECT * FROM v_acn_service_asset_dependencies) TO 'acn_service_asset_dependencies.csv' CSV HEADER;`

Dipendenze da fornitori terzi:
`\copy (SELECT * FROM v_acn_service_provider_dependencies) TO 'acn_service_provider_dependencies.csv' CSV HEADER;`

I file CSV generati costituiscono un esempio di output strutturato direttamente utilizzabile come base per la compilazione dei profili ACN.

---

## Contesto normativo

Il progetto si colloca nel contesto della direttiva europea NIS2 e delle indicazioni dell’Agenzia per la Cybersicurezza Nazionale (ACN) per la gestione degli asset, dei servizi critici e delle dipendenze da fornitori terzi. Oltre alla gestione inventariale e al modulo di assessment dei controlli (profili CURRENT e TARGET), il progetto integra un’estensione dedicata alla tracciabilità degli incidenti di sicurezza e agli obblighi di notifica previsti dalla Direttiva NIS2. 
Tale modulo consente di registrare incidenti significativi, associare gli asset coinvolti e monitorare le comunicazioni verso l’autorità competente (ACN), in linea con i requisiti di early warning (24h), notifica completa (72h) e relazione finale.

---

## Architettura logica del modulo Framework

Il modulo di assessment della sicurezza è stato progettato secondo un approccio modulare e normalizzato, con l’obiettivo di separare in modo chiaro la definizione dei controlli normativi dalla loro applicazione operativa su asset e servizi aziendali.

In particolare, il modello distingue:

- la definizione astratta dei controlli di sicurezza;

- la loro classificazione attraverso le subcategory del Framework Nazionale per la Cybersecurity;

- la relazione tra controlli e asset/servizi oggetto di valutazione;

- la misurazione del livello di implementazione corrente (CURRENT);

- la definizione del livello di sicurezza desiderato (TARGET).

Questa separazione logica consente di mantenere i controlli come entità riutilizzabili e indipendenti dagli oggetti valutati, evitando duplicazioni e garantendo maggiore flessibilità del sistema. L’associazione tra controlli e asset/servizi avviene tramite tabelle di assessment dedicate, che permettono di registrare in modo strutturato lo stato di conformità e il livello di maturità raggiunto.

La presenza dei profili CURRENT e TARGET rende possibile effettuare in modo diretto analisi di scostamento (gap analysis), utili per individuare le aree di miglioramento e supportare processi di pianificazione degli interventi di sicurezza.

---

## Architettura logica del modulo Incident Management

Il modulo di gestione incidenti è stato progettato come estensione indipendente rispetto al modulo Framework, mantenendo separazione tra:

- gestione preventiva e assessment dei controlli;
- gestione reattiva degli eventi incidentali.

L’architettura prevede:

- una entità `incident` collegata alla company;
- una relazione molti-a-molti tra incident e asset per modellare l’impatto;
- una entità `incident_notification` per tracciare le comunicazioni verso l’autorità competente.

---

## Riferimenti

- Direttiva (UE) 2022/2555 (NIS2) – Parlamento Europeo e Consiglio dell’Unione Europea  
- Agenzia per la Cybersicurezza Nazionale (ACN): https://www.acn.gov.it  
- Documentazione PostgreSQL: https://www.postgresql.org/docs/















