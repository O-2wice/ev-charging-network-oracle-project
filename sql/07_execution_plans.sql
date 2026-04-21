-- Purpose: Generate execution plans for the two required complex queries and index comparison.
-- Notes: Uses EXPLAIN PLAN and DBMS_XPLAN.DISPLAY for evidence.

SET LINESIZE 200;
SET PAGESIZE 100;

PROMPT *** Execution plan for View 1 query ***

-- Reproduce the main access pattern behind vw_completed_session_details.
EXPLAIN PLAN FOR
SELECT /*+ INDEX(cs idx_session_status_start) */
    cs.session_id,
    cs.session_start,
    c.customer_id,
    v.vehicle_id,
    con.connector_id,
    s.station_id,
    t.tariff_id
FROM charging_sessions cs
INNER JOIN customers c
    ON cs.customer_id = c.customer_id
INNER JOIN vehicles v
    ON cs.vehicle_id = v.vehicle_id
INNER JOIN connectors con
    ON cs.connector_id = con.connector_id
INNER JOIN stations s
    ON con.station_id = s.station_id
INNER JOIN tariffs t
    ON cs.tariff_id = t.tariff_id
WHERE cs.session_status = 'COMPLETED'
  AND cs.session_start >= DATE '2025-06-01'
  AND cs.session_start < DATE '2025-07-01';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

PROMPT *** Execution plan for View 2 query ***

-- Reproduce the grouped analytical pattern behind vw_high_utilization_connectors.
EXPLAIN PLAN FOR
SELECT
    s.station_id,
    con.connector_id,
    COUNT(*) AS completed_sessions,
    SUM(sess.energy_kwh) AS total_energy_kwh
FROM stations s
INNER JOIN connectors con
    ON s.station_id = con.station_id
INNER JOIN (
    SELECT
        cs.session_id,
        cs.session_start,
        cs.connector_id,
        cs.energy_kwh
    FROM charging_sessions cs
    WHERE cs.session_status = 'COMPLETED'
      AND cs.energy_kwh > (
          SELECT AVG(cs2.energy_kwh)
          FROM charging_sessions cs2
          WHERE cs2.session_status = 'COMPLETED'
      )
) sess
    ON con.connector_id = sess.connector_id
INNER JOIN (
    SELECT
        mr.session_id,
        mr.session_start,
        AVG(mr.connector_power_kw) AS avg_power_kw,
        MAX(mr.reading_time) AS last_reading_time
    FROM meter_readings mr
    GROUP BY mr.session_id, mr.session_start
) reading_stats
    ON sess.session_id = reading_stats.session_id
   AND sess.session_start = reading_stats.session_start
GROUP BY s.station_id, con.connector_id
HAVING COUNT(*) >= 25;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

PROMPT *** Without indexes comparison ***

-- Force a baseline plan that avoids the custom indexes.
EXPLAIN PLAN FOR
SELECT /*+ NO_INDEX(cs) NO_INDEX(mr) */
    cs.session_id,
    cs.session_start,
    mr.reading_time,
    mr.connector_power_kw
FROM charging_sessions cs
INNER JOIN meter_readings mr
    ON cs.session_id = mr.session_id
   AND cs.session_start = mr.session_start
WHERE cs.session_status = 'FAILED'
  AND cs.session_start >= DATE '2025-04-01'
  AND cs.session_start < DATE '2025-04-03'
  AND mr.session_start >= DATE '2025-04-01'
  AND mr.session_start < DATE '2025-04-03';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

PROMPT *** With indexes comparison ***

-- Encourage the optimizer to use the designed indexes for the same predicate pattern.
EXPLAIN PLAN FOR
SELECT /*+ ORDERED USE_NL(mr) INDEX(cs idx_session_status_start) INDEX(mr idx_reading_session_time) */
    cs.session_id,
    cs.session_start,
    mr.reading_time,
    mr.connector_power_kw
FROM charging_sessions cs
INNER JOIN meter_readings mr
    ON cs.session_id = mr.session_id
   AND cs.session_start = mr.session_start
WHERE cs.session_status = 'FAILED'
  AND cs.session_start >= DATE '2025-04-01'
  AND cs.session_start < DATE '2025-04-03'
  AND mr.session_start >= DATE '2025-04-01'
  AND mr.session_start < DATE '2025-04-03';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

PROMPT === Execution plans generated ===
