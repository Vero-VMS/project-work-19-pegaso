# PW19 – Database NIS2/ACN (Registro asset, servizi, dipendenze e responsabilità)

Repository di supporto al Project Work 19 (Tema 2: Privacy e sicurezza aziendale).
Obiettivo: progettare e realizzare una base dati relazionale per catalogare asset, servizi, dipendenze da terze parti e responsabilità, in modo da supportare la produzione di output strutturati utili ai profili richiesti dall’ACN nell’ambito NIS2.

## Contenuto
- `sql/01_create_tables.sql`  
  Crea tabelle, vincoli e indici (schema relazionale normalizzato).
- `sql/02_triggers_versioning.sql`  
  Trigger e funzioni per mantenere lo storico (versioning) delle modifiche agli asset.
- `sql/03_insert_test_data.sql`  
  Dataset simulato (azienda demo, asset, servizi, fornitori, dipendenze).
- `sql/04_views_and_exports.sql`  
  Viste e query per estrazione dati (anche esportabile in CSV).

## Requisiti (opzionali)
- PostgreSQL (consigliato) + client `psql`  
  Nota: ai fini del PW è sufficiente anche la consegna degli script.

## Esecuzione (se vuoi testare davvero)
1. Crea un database vuoto (es. `pw19_nis2`).
2. Esegui in ordine gli script:
   - `01_create_tables.sql`
   - `02_triggers_versioning.sql`
   - `03_insert_test_data.sql`
   - `04_views_and_exports.sql`

Esempio (psql):
```bash
psql -d pw19_nis2 -f sql/01_create_tables.sql
psql -d pw19_nis2 -f sql/02_triggers_versioning.sql
psql -d pw19_nis2 -f sql/03_insert_test_data.sql
psql -d pw19_nis2 -f sql/04_views_and_exports.sql
