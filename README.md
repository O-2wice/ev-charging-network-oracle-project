# EV Charging Network Oracle Project

This project implements an Oracle database for an EV charging network management system. It models customers, vehicles, charging stations, connectors, tariffs, charging sessions, meter readings, maintenance tickets, and session audit records.

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

## Main Database Features

- synthetic test data generated inside Oracle with PL/SQL
- partitioned large session table for time-based querying
- clustered storage for station and connector access
- reporting views for completed sessions and connector utilization
- PL/SQL logic for session-cost calculation and unpaid-session review
- execution-plan comparison showing the effect of indexing

## SQL Files

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

## How To Run

Run the full project from SQL*Plus, SQLcl, or SQL Developer:

```sql
@run_sqlplus_all.sql
```

This creates the schema objects, loads the synthetic data, creates indexes and views, defines the PL/SQL objects, runs grants, and executes the verification scripts.

To rerun the verification queries separately:

```sql
@sql/09_test_objects.sql
```

## Repository

GitHub repository: <https://github.com/O-2wice/ev-charging-network-oracle-project>
