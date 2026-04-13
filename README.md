# EV Charging Network Oracle Project

This repository contains the core Oracle deliverables for an EV Charging Network Management System. It models the full lifecycle of a charging session, from customer and vehicle registration through station usage, meter telemetry, maintenance tracking, and session audit history.

The GitHub version is intentionally minimal: it keeps the main README, the root SQL runner, and the Oracle SQL source files.

## Overview

The project was designed as a database systems assignment with both logical modeling and physical optimization in mind. The schema covers:

- customers who own EVs
- vehicles linked to customers
- stations and connectors as the physical charging infrastructure
- tariffs used to price charging sessions
- charging sessions as the core transactional fact
- meter readings as high-volume telemetry
- maintenance tickets for operational support
- session audit logs for important business events

This gives the project a realistic operational shape instead of a simple CRUD example, and it creates a good setting for partitioning, clustered storage, PL/SQL logic, and execution-plan analysis.

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

## How the system works

A typical business flow in this schema is:

1. A customer registers and one or more vehicles are stored in the system.
2. A vehicle uses a specific connector at a charging station under a selected tariff.
3. A new row is created in `charging_sessions` when the charging event begins.
4. During the session, detailed consumption is captured in `meter_readings`.
5. The final session cost can be derived and validated through PL/SQL logic.
6. Operational events such as overdue unpaid sessions or status changes are written to `session_audit_log`.
7. Connector issues can be tracked separately in `maintenance_tickets`.

## Physical design highlights

- `charging_sessions` is range-partitioned into `P_SESSIONS_2024`, `P_SESSIONS_2025`, `P_SESSIONS_2026`, and `P_SESSIONS_FUTURE`
- `stations` and `connectors` use the `station_connector_cluster`
- the main performance indexes are:
  - `idx_session_status_start`
  - `idx_reading_session_time`

These choices were made to support both correctness and performance:

- partitioning helps manage and query the largest transactional table by time period
- clustered storage keeps frequently joined infrastructure tables physically close
- custom indexes support the reporting and execution-plan comparison queries

## Database logic

Beyond table creation and loading, the project includes:

- 2 views for reporting and analytical access
- 1 stored function for session-cost calculation
- 1 stored procedure for reviewing unpaid sessions
- 1 trigger for auditing session status changes
- grant statements for user `lkpeter`

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

## SQL script order

The project is split into focused setup stages:

- `sql/01_create_tables.sql`: tables, constraints, partitioning, and clustered storage
- `sql/02_create_sequences.sql`: sequence objects for key generation
- `sql/03_load_data.sql`: synthetic data loading
- `sql/04_create_indexes.sql`: performance indexes
- `sql/05_create_views.sql`: reporting views
- `sql/06_create_plsql.sql`: function, procedure, and trigger
- `sql/07_execution_plans.sql`: optimization and plan comparison queries
- `sql/08_grants.sql`: privileges for `lkpeter`
- `sql/09_test_objects.sql`: verification queries and behavior checks

## What stays local

The GitHub repo intentionally leaves out the broader local documentation set, screenshots, pictures, Word exports, editor settings, and saved execution logs. Those can still exist in the working folder, but `.gitignore` keeps the public repository focused on the core Oracle source only.

## Notes

- `charging_sessions` is range-partitioned by `session_start`
- `stations` and `connectors` use clustered storage on `station_id`
- the main performance indexes are `idx_session_status_start` and `idx_reading_session_time`
- the project includes two views, one stored function, one stored procedure, one trigger, and the required grants for `lkpeter`
