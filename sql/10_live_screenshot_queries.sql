ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

-- Screenshot 1: row counts
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers UNION ALL
SELECT 'vehicles', COUNT(*) FROM vehicles UNION ALL
SELECT 'stations', COUNT(*) FROM stations UNION ALL
SELECT 'connectors', COUNT(*) FROM connectors UNION ALL
SELECT 'tariffs', COUNT(*) FROM tariffs UNION ALL
SELECT 'charging_sessions', COUNT(*) FROM charging_sessions UNION ALL
SELECT 'meter_readings', COUNT(*) FROM meter_readings UNION ALL
SELECT 'maintenance_tickets', COUNT(*) FROM maintenance_tickets UNION ALL
SELECT 'session_audit_log', COUNT(*) FROM session_audit_log;

-- Screenshot 2: clustered tables
SELECT table_name, cluster_name
FROM user_tables
WHERE table_name IN ('STATIONS', 'CONNECTORS')
ORDER BY table_name;
IDX_SESSION_STATUS_START,CHARGING_SESSIONS,N/A
IDX_READING_SESSION_TIME,METER_READINGS,VALID
IDX_STATION_CONNECTOR_CLUSTER,STATION_CONNECTOR_CLUSTER,VALID
-- Screenshot 3: partitioning
SELECT table_name, partitioning_type
FROM user_part_tables
WHERE table_name = 'CHARGING_SESSIONS';

SELECT partition_name, partition_position
FROM user_tab_partitions
WHERE table_name = 'CHARGING_SESSIONS'
ORDER BY partition_position;

-- Screenshot 4: view 1 sample
SELECT *
FROM vw_completed_session_details
WHERE ROWNUM <= 10;

-- Screenshot 5: view 2 sample
SELECT *
FROM vw_high_utilization_connectors
WHERE ROWNUM <= 10;

-- Screenshot 6: function sample
SELECT fn_calculate_session_cost(session_id, session_start) AS sample_cost
FROM (
    SELECT session_id, session_start
    FROM charging_sessions
    WHERE session_status = 'COMPLETED'
      AND ROWNUM = 1
);

-- Screenshot 7: procedure run
BEGIN
    sp_review_unpaid_sessions(25);
END;
/

-- Screenshot 8: procedure audit rows
SELECT *
FROM (
    SELECT *
    FROM session_audit_log
    WHERE action_type = 'PAYMENT_REVIEW'
    ORDER BY changed_at DESC, log_id DESC
)
WHERE ROWNUM <= 10;

-- Screenshot 9: trigger verification
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
END;
/

-- Screenshot 10: trigger audit rows
SELECT *
FROM (
    SELECT *
    FROM session_audit_log
    WHERE action_type = 'SESSION_STATUS_CHANGE'
    ORDER BY changed_at DESC, log_id DESC
)
WHERE ROWNUM <= 10;

-- Screenshot 11: custom index list
SELECT index_name, table_name, status
FROM user_indexes
WHERE index_name IN (
    'IDX_STATION_CONNECTOR_CLUSTER',
    'IDX_SESSION_STATUS_START',
    'IDX_READING_SESSION_TIME'
)
ORDER BY table_name, index_name;
-- Purpose: Run focused queries used for live screenshots in SQL Developer/SQL*Plus.
-- Notes: Each query corresponds to a figure or verification step in the report.
