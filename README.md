# EV Charging Network Oracle Project

This project implements an Oracle database for an EV charging network management system. It models customers, vehicles, charging stations, connectors, tariffs, charging sessions, meter readings, maintenance tickets, and session audit records.

## ER Diagram

<p align="center">
  <img src="https://raw.githubusercontent.com/O-2wice/ev-charging-network-oracle-project/main/docs/er_diagram_live.png" alt="ER diagram of the EV Charging Network Oracle Project" width="900">
</p>

The schema is centered on `charging_sessions`, which connects the customer, vehicle, connector, and tariff dimensions to the main charging event. `meter_readings` stores session telemetry, `maintenance_tickets` captures operational problems at connector level, and `session_audit_log` records important business events created by the trigger and procedure logic.

## Project Summary

- 9 relational tables
- 100,000 rows in `charging_sessions`
- 110,000 rows in `meter_readings`
- range partitioning on `charging_sessions(session_start)`
- clustered storage for `stations` and `connectors`
- 2 views
- 1 stored function
- 1 stored procedure
- 1 trigger
- indexes and execution-plan analysis

## Design Highlights

- `charging_sessions` is the main high-volume transactional table and is partitioned by date to support time-based reporting and partition pruning
- `stations` and `connectors` use clustered storage because they are frequently accessed together in infrastructure and utilization queries
- synthetic test data is generated inside Oracle with PL/SQL rather than imported from CSV files
- the project includes two complex reporting views, stored PL/SQL logic, and an execution-plan comparison showing the effect of indexing

## Main Tables

- `customers`: customer master data
- `vehicles`: EVs linked to customers
- `stations`: charging locations
- `connectors`: charging points installed at stations
- `tariffs`: pricing definitions
- `charging_sessions`: main transactional charging records
- `meter_readings`: session telemetry readings
- `maintenance_tickets`: operational issue tracking
- `session_audit_log`: audit history for important events

## SQL Files

```text
sql/
  00_run_all.sql          -- dev-only: lightweight rebuilder, run from inside sql/
  01_create_tables.sql
  02_create_sequences.sql
  03_load_data.sql
  04_create_indexes.sql
  05_create_views.sql
  06_create_plsql.sql
  07_execution_plans.sql
  08_grants.sql
  09_test_objects.sql

run_sqlplus_all.sql       -- main runner: spools output to output_logs/
README.md
```

## How To Run

Run the full project from SQL*Plus, SQLcl, or SQL Developer (repo root):

```sql
@run_sqlplus_all.sql
```

This creates the schema objects, loads the synthetic data, creates indexes and views, defines the PL/SQL objects, runs grants, executes the verification scripts, and spools output to `output_logs/`.

To rerun the verification queries separately:

```sql
@sql/09_test_objects.sql
```
---

## Related Repository

The same EV Charging domain is also implemented as a MongoDB NoSQL extension in a separate repository:

**[ev-charging-mongodb](https://github.com/O-2wice/ev-charging-mongodb)** — Oracle data migrated to MongoDB; 10 queries covering DDL, DML, and complex aggregation pipelines; Oracle vs MongoDB comparison.

The two repositories are independent. The MongoDB repo migrates from this Oracle schema and references the same nine entities, but has no git dependency on this project.
