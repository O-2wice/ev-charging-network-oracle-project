SET SERVEROUTPUT ON;
SET LINESIZE 200;
SET PAGESIZE 50;

-- Row counts confirm that the full synthetic load completed.
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers UNION ALL
SELECT 'vehicles', COUNT(*) FROM vehicles UNION ALL
SELECT 'stations', COUNT(*) FROM stations UNION ALL
SELECT 'connectors', COUNT(*) FROM connectors UNION ALL
SELECT 'tariffs', COUNT(*) FROM tariffs UNION ALL
SELECT 'charging_sessions', COUNT(*) FROM charging_sessions UNION ALL
SELECT 'meter_readings', COUNT(*) FROM meter_readings UNION ALL
SELECT 'maintenance_tickets', COUNT(*) FROM maintenance_tickets UNION ALL
SELECT 'session_audit_log', COUNT(*) FROM session_audit_log;

PROMPT === Clustered table verification ===

-- Verify that stations and connectors were created inside the shared cluster.
SELECT table_name, cluster_name
FROM user_tables
WHERE table_name IN ('STATIONS', 'CONNECTORS')
ORDER BY table_name;

PROMPT === Partition verification ===

-- Confirm that charging_sessions is partitioned as designed.
SELECT table_name, partitioning_type
FROM user_part_tables
WHERE table_name = 'CHARGING_SESSIONS';

SELECT partition_name, partition_position
FROM user_tab_partitions
WHERE table_name = 'CHARGING_SESSIONS'
ORDER BY partition_position;

PROMPT === View 1 sample ===

-- Sample output from the denormalized completed-session view.
SELECT * FROM vw_completed_session_details WHERE ROWNUM <= 10;

PROMPT === View 2 sample ===

-- Sample output from the grouped utilization view.
SELECT * FROM vw_high_utilization_connectors WHERE ROWNUM <= 10;

PROMPT === Function sample ===

-- Recompute one completed session to verify the function is callable and returns a value.
SELECT fn_calculate_session_cost(session_id, session_start) AS sample_cost
FROM (
    SELECT session_id, session_start
    FROM charging_sessions
    WHERE session_status = 'COMPLETED'
      AND ROWNUM = 1
);

PROMPT === Procedure sample ===

-- Review pending balances and emit DBMS_OUTPUT evidence.
BEGIN
    sp_review_unpaid_sessions(25);
END;
/

PROMPT === Procedure log sample ===

-- Show the audit rows written by the payment review procedure.
SELECT *
FROM session_audit_log
WHERE action_type = 'PAYMENT_REVIEW'
  AND ROWNUM <= 10;

PROMPT === Trigger verification sample ===

-- Force a status change on one active session so the trigger can be observed end-to-end.
DECLARE
    v_test_session_id NUMBER;
    v_test_session_start DATE;
BEGIN
    SELECT session_id, session_start
    INTO v_test_session_id, v_test_session_start
    FROM (
        SELECT session_id, session_start
        FROM charging_sessions
        WHERE session_status = 'STARTED'
          AND ROWNUM = 1
    );

    UPDATE charging_sessions
    SET session_status = 'FAILED'
    WHERE session_id = v_test_session_id
      AND session_start = v_test_session_start;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE(
        'Updated session ' || v_test_session_id || ' to FAILED for trigger verification.'
    );
END;
/

SELECT *
FROM session_audit_log
WHERE action_type = 'SESSION_STATUS_CHANGE'
  AND ROWNUM <= 10;

PROMPT === Index list ===

-- List indexes after the build so the custom analytical indexes can be verified.
SELECT index_name, table_name, status
FROM user_indexes
WHERE table_name IN (
    'CUSTOMERS',
    'VEHICLES',
    'STATIONS',
    'CONNECTORS',
    'TARIFFS',
    'CHARGING_SESSIONS',
    'METER_READINGS',
    'MAINTENANCE_TICKETS',
    'SESSION_AUDIT_LOG'
)
ORDER BY table_name, index_name;

PROMPT === Tests completed ===
