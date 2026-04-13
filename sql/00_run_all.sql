-- Purpose: Master runner that executes the full schema build in the correct order.
-- Usage: Run from SQL*Plus or SQL Developer to create objects, load data, and grant access.

PROMPT ==========================================
PROMPT EV Charging Network Management System
PROMPT Full Oracle Setup
PROMPT ==========================================

SET TIMING ON;
SET SERVEROUTPUT ON;

PROMPT Step 1/8: Creating tables...
@01_create_tables.sql

PROMPT Step 2/8: Creating sequences...
@02_create_sequences.sql

PROMPT Step 3/8: Loading data...
@03_load_data.sql

PROMPT Step 4/8: Creating indexes...
@04_create_indexes.sql

PROMPT Step 5/8: Creating views...
@05_create_views.sql

PROMPT Step 6/8: Creating PL/SQL objects...
@06_create_plsql.sql

PROMPT Step 7/8: Generating execution plans...
@07_execution_plans.sql

PROMPT Step 8/8: Granting privileges...
@08_grants.sql

PROMPT Setup complete. Run 09_test_objects.sql next.
