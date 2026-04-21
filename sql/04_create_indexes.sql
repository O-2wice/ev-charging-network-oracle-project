-- Recreate only the custom analytical indexes added for the assignment.
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_session_status_start'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_reading_session_time'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Local index keeps the partitioned session filter aligned with session_start.
CREATE INDEX idx_session_status_start
    ON charging_sessions(session_status, session_start)
    LOCAL;

-- Support session-to-reading joins plus time filtering in plan comparisons.
CREATE INDEX idx_reading_session_time
    ON meter_readings(session_start, session_id, reading_time);

BEGIN
    -- Gather fresh optimizer statistics after the bulk load and new indexes.
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'CUSTOMERS', cascade => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'VEHICLES', cascade => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'STATIONS', cascade => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'CONNECTORS', cascade => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'TARIFFS', cascade => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'CHARGING_SESSIONS', cascade => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'METER_READINGS', cascade => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'MAINTENANCE_TICKETS', cascade => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'SESSION_AUDIT_LOG', cascade => TRUE);
END;
/

PROMPT === Table and index statistics gathered ===
PROMPT === All indexes created successfully ===
