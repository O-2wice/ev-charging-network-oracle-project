-- View 1 exposes a denormalized session-detail report for completed 2025 sessions.
CREATE OR REPLACE VIEW vw_completed_session_details AS
SELECT
    cs.session_id,
    cs.session_start,
    cs.session_end,
    cs.session_status,
    cs.payment_status,
    cs.energy_kwh,
    cs.total_cost,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    v.vehicle_id,
    v.plate_number,
    v.brand,
    v.model_name,
    con.connector_id,
    con.connector_label,
    s.station_id,
    s.station_name,
    s.city AS station_city,
    t.tariff_name,
    t.price_per_kwh
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
  AND cs.session_start >= DATE '2025-01-01'
  AND cs.session_start < DATE '2026-01-01';

PROMPT === View 1 created ===

-- View 2 highlights connectors with unusually strong completed-session activity.
CREATE OR REPLACE VIEW vw_high_utilization_connectors AS
SELECT
    s.station_id,
    s.station_name,
    con.connector_id,
    con.connector_label,
    COUNT(*) AS completed_sessions,
    SUM(sess.energy_kwh) AS total_energy_kwh,
    ROUND(AVG(reading_stats.avg_power_kw), 2) AS avg_power_kw,
    MAX(reading_stats.last_reading_time) AS last_reading_time
FROM stations s
INNER JOIN connectors con
    ON s.station_id = con.station_id
INNER JOIN (
    -- Prefilter sessions above the completed-session average before grouping.
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
    -- Aggregate telemetry per session so the outer query can report connector-level averages.
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
GROUP BY
    s.station_id,
    s.station_name,
    con.connector_id,
    con.connector_label
HAVING COUNT(*) >= 25;

PROMPT === View 2 created ===
