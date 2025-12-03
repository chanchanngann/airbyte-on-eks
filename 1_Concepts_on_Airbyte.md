## Main Components of Airbyte

1. Airbyte Webapp (`airbyte-webapp`) 
  - frontend UI
2. Airbyte Server (`airbyte-server`)
  - the backend API for Airbyte.
  - handles orchestration, job scheduling, connector management.
  - everything you do on airbyte webapp goes through this API
3. Temporal (Airbyte scheduler)
  - orchestrator
  - schedules jobs requested by the Airbyte API, e.g. sync, check, discover
  - jobs are pushed into a queue.
4. Airbyte Workers (`airbyte-worker`)
  - pulls jobs from the queue and execute them.
  - launches connectors in isolated containers.
5. AirbyteDB (postgres)
  - stores all connections' metadata, configs, frequency...

## How Airbyte components interact?

1. **User** configures a sync in **Webapp** (UI).
2. **Webapp** calls **Server API**.
3. **Server API** stores config in **Postgres DB** and creates jobs.
4. **Temporal** schedule jobs.
5. **Worker** pulls the jobs & spins up temporary **Connector pods** (Source + Destination).
6. **Source Connector** extracts → passes data → **Destination Connector** loads.
7. **Logs & metadata** go back to **Postgres DB** for tracking.
8. **UI** shows job status & logs by querying **Server API**.
   
```ruby
                ┌──────────────────┐
                │   Airbyte UI     │
                │  (Webapp Pod)    │
                └───────▲──────────┘
                        │ REST API
                        ▼
                ┌──────────────────┐      ┌──────────────────┐
                │  Airbyte Server  │ ──>  │  Postgres DB     │  
                │   (API Backend)  │      │ (Persistence)    │
                └───────▲──────────┘      └──────────────────┘
                        │                Stores config + job definitions + job status
                        │ Create job 
                        ▼     
                ┌──────────────────┐
                │   Temporal       │
                │ (Orchestrator)   │
                └───────▲──────────┘
                        │ 
	                    │ Worker pulls jobs from the queue
                        ▼
                ┌──────────────────┐
                │   Worker Pod     │
                │ (Runs job logic) │
                └───────▲──────────┘
                        │ Launches isolated
                        │ connector containers
                        ▼
        ┌─────────────────────┐       ┌──────────────────────┐
        │ Source Connector Pod│  -->  │ Destination Connector│
        │     (Postgres)      │       │        (S3)          │
        └─────────────────────┘       └──────────────────────┘
                          Extract → Load Data
                          
                        

```