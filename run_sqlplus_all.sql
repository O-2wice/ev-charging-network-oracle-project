-- Run this file from the repository root with SQL*Plus, SQLcl, or
-- SQL Developer "Run Script" (F5). It overwrites output_logs/*.txt
-- with genuine client-side spooled output.

SET ECHO ON
SET FEEDBACK ON
SET HEADING ON
SET VERIFY OFF
SET TERMOUT ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100
SET LONG 100000
SET LONGCHUNKSIZE 100000
SET TAB OFF
SET TRIMSPOOL ON
SET TIMING ON

PROMPT ==========================================
PROMPT EV Charging Network Management System
PROMPT SQL*Plus / SQL Developer Evidence Run
PROMPT ==========================================
PROMPT Output files will be written to output_logs/

SPOOL output_logs/01_create_tables_output.txt
PROMPT ==========================================
PROMPT Running sql/01_create_tables.sql
PROMPT ==========================================
@sql/01_create_tables.sql
SPOOL OFF

SPOOL output_logs/02_create_sequences_output.txt
PROMPT ==========================================
PROMPT Running sql/02_create_sequences.sql
PROMPT ==========================================
@sql/02_create_sequences.sql
SPOOL OFF

SPOOL output_logs/03_load_data_output.txt
PROMPT ==========================================
PROMPT Running sql/03_load_data.sql
PROMPT ==========================================
@sql/03_load_data.sql
SPOOL OFF

SPOOL output_logs/04_create_indexes_output.txt
PROMPT ==========================================
PROMPT Running sql/04_create_indexes.sql
PROMPT ==========================================
@sql/04_create_indexes.sql
SPOOL OFF

SPOOL output_logs/05_create_views_output.txt
PROMPT ==========================================
PROMPT Running sql/05_create_views.sql
PROMPT ==========================================
@sql/05_create_views.sql
SPOOL OFF

SPOOL output_logs/06_create_plsql_output.txt
PROMPT ==========================================
PROMPT Running sql/06_create_plsql.sql
PROMPT ==========================================
@sql/06_create_plsql.sql
SPOOL OFF

SPOOL output_logs/07_execution_plans_output.txt
PROMPT ==========================================
PROMPT Running sql/07_execution_plans.sql
PROMPT ==========================================
@sql/07_execution_plans.sql
SPOOL OFF

SPOOL output_logs/08_grants_output.txt
PROMPT ==========================================
PROMPT Running sql/08_grants.sql
PROMPT ==========================================
@sql/08_grants.sql
SPOOL OFF

SPOOL output_logs/09_test_objects_output.txt
PROMPT ==========================================
PROMPT Running sql/09_test_objects.sql
PROMPT ==========================================
@sql/09_test_objects.sql
SPOOL OFF

PROMPT ==========================================
PROMPT SQL*Plus evidence run complete
PROMPT Review output_logs/*.txt and regenerate docs/screenshots next.
PROMPT ==========================================
