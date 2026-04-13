# EV Charging Network Oracle Project

This repository contains the core Oracle deliverables for an EV Charging Network Management System. The tracked GitHub version is intentionally minimal and keeps only the main README, the SQL runner, and the SQL source files.

## Project scope

- 9 relational tables
- 2 large tables:
  - `charging_sessions`: 100,000 rows
  - `meter_readings`: 110,000 rows
- 1 partitioned large table:
  - `charging_sessions` partitioned by `session_start`
- 1 clustered storage design:
  - `stations` and `connectors` clustered by `station_id`
- 2 views
- 1 stored function
- 1 stored procedure
- 1 trigger
- custom indexes and grants for `lkpeter`

## Physical design highlights

- `charging_sessions` is range-partitioned into `P_SESSIONS_2024`, `P_SESSIONS_2025`, `P_SESSIONS_2026`, and `P_SESSIONS_FUTURE`
- `stations` and `connectors` use the `station_connector_cluster`
- the main performance indexes are:
  - `idx_session_status_start`
  - `idx_reading_session_time`

## Repository layout

```text
sql/
  00_run_all.sql
  01_create_tables.sql
  02_create_sequences.sql
  03_load_data.sql
  04_create_indexes.sql
  05_create_views.sql
  06_create_plsql.sql
  07_execution_plans.sql
  08_grants.sql
  09_test_objects.sql
  10_live_screenshot_queries.sql

run_sqlplus_all.sql
README.md
```

## Prerequisites

- Oracle Database access
- SQL*Plus, SQLcl, or SQL Developer

## Running the Oracle project

There are two main entry points:

- `sql/00_run_all.sql`: the ordered schema setup script inside the `sql/` folder
- `run_sqlplus_all.sql`: a repo-root wrapper that runs the scripts and spools evidence files into `output_logs/`

If you want the saved evidence logs, run the root script from the repository root in SQL*Plus, SQLcl, or SQL Developer:

```sql
@run_sqlplus_all.sql
```

After setup, you can rerun validation with:

```sql
@sql/09_test_objects.sql
```

## What stays local

The GitHub repo intentionally leaves out local documentation assets, generated screenshots, Word exports, editor settings, and saved execution logs. Those can still exist in your working folder, but `.gitignore` keeps the public repository focused on the core Oracle project source.

## Notes

- `charging_sessions` is range-partitioned by `session_start`
- `stations` and `connectors` use clustered storage on `station_id`
- the main performance indexes are `idx_session_status_start` and `idx_reading_session_time`
- the project includes two views, one stored function, one stored procedure, one trigger, and the required grants for `lkpeter`
