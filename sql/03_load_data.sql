SET SERVEROUTPUT ON;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
-- Synthetic data is generated inside Oracle in foreign-key order.
-- Batch commits are used only on the larger inserts to keep the load stable.

-- ============================================================
-- 1. CUSTOMERS (~10,000 rows)
-- ============================================================
DECLARE
    TYPE t_names IS VARRAY(20) OF VARCHAR2(50);
    TYPE t_locations IS VARRAY(10) OF VARCHAR2(100);

    v_first_names t_names := t_names(
        'Adam','Amelia','Benjamin','Chloe','Daniel',
        'Emma','Ethan','Grace','Henry','Isla',
        'Jack','Lily','Lucas','Mia','Noah',
        'Olivia','Oscar','Sofia','Thomas','Zoe'
    );
    v_last_names t_names := t_names(
        'Anderson','Brown','Clark','Davis','Evans',
        'Fisher','Garcia','Hill','Ivanov','Johnson',
        'Kovacs','Lopez','Martin','Nagy','Olsen',
        'Patel','Quinn','Roberts','Szabo','Taylor'
    );
    v_countries t_locations := t_locations(
        'Hungary','Austria','Germany','Slovakia','Romania',
        'Croatia','Slovenia','Czechia','Poland','Italy'
    );
    v_cities t_locations := t_locations(
        'Budapest','Vienna','Berlin','Bratislava','Bucharest',
        'Zagreb','Ljubljana','Prague','Warsaw','Milan'
    );

    v_batch_size NUMBER := 5000;
    v_first_idx NUMBER;
    v_last_idx NUMBER;
    v_loc_idx NUMBER;
BEGIN
    FOR i IN 1..10000 LOOP
        v_first_idx := MOD(i - 1, v_first_names.COUNT) + 1;
        v_last_idx := MOD(TRUNC((i - 1) / v_first_names.COUNT), v_last_names.COUNT) + 1;
        v_loc_idx := MOD(i - 1, v_countries.COUNT) + 1;

        INSERT INTO customers (
            customer_id,
            first_name,
            last_name,
            email,
            phone,
            country,
            city,
            registration_at
        ) VALUES (
            seq_customer.NEXTVAL,
            v_first_names(v_first_idx),
            v_last_names(v_last_idx),
            'customer_' || i || '@evgrid.example',
            '+' || TO_CHAR(300000000 + i),
            v_countries(v_loc_idx),
            v_cities(v_loc_idx),
            DATE '2023-01-01' + TRUNC(DBMS_RANDOM.VALUE(0, 1200))
        );

        IF MOD(i, v_batch_size) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Loaded 10,000 customers.');
END;
/

-- ============================================================
-- 2. VEHICLES (~12,000 rows)
-- ============================================================
DECLARE
    TYPE t_brands IS VARRAY(12) OF VARCHAR2(60);
    TYPE t_models IS VARRAY(12) OF VARCHAR2(60);
    TYPE t_caps IS VARRAY(12) OF NUMBER;

    v_brands t_brands := t_brands(
        'Tesla','Hyundai','Kia','BMW','Volkswagen','Renault',
        'Nissan','Mercedes','Volvo','Skoda','BYD','Peugeot'
    );
    v_models t_models := t_models(
        'Model 3','Ioniq 5','EV6','i4','ID.4','Megane E-Tech',
        'Leaf','EQA','EX30','Enyaq','Seal','e-208'
    );
    v_caps t_caps := t_caps(
        57, 77, 74, 81, 77, 60,
        39, 66, 69, 82, 61, 50
    );

    v_batch_size NUMBER := 5000;
    v_owner_id NUMBER;
    v_model_idx NUMBER;
BEGIN
    FOR i IN 1..12000 LOOP
        v_owner_id := MOD(i - 1, 10000) + 1;
        v_model_idx := MOD(i - 1, v_brands.COUNT) + 1;

        INSERT INTO vehicles (
            vehicle_id,
            customer_id,
            plate_number,
            brand,
            model_name,
            battery_capacity_kwh,
            model_year,
            created_at
        ) VALUES (
            seq_vehicle.NEXTVAL,
            v_owner_id,
            'EV' || LPAD(i, 6, '0'),
            v_brands(v_model_idx),
            v_models(v_model_idx),
            v_caps(v_model_idx),
            2018 + MOD(i, 8),
            DATE '2023-01-01' + TRUNC(DBMS_RANDOM.VALUE(0, 1200))
        );

        IF MOD(i, v_batch_size) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Loaded 12,000 vehicles.');
END;
/

-- ============================================================
-- 3. STATIONS (~120 rows)
-- ============================================================
DECLARE
    TYPE t_regions IS VARRAY(12) OF VARCHAR2(100);
    TYPE t_cities IS VARRAY(12) OF VARCHAR2(100);
    TYPE t_operators IS VARRAY(5) OF VARCHAR2(100);

    v_regions t_regions := t_regions(
        'Central Hungary','Western Transdanubia','Northern Hungary','Southern Great Plain',
        'Eastern Austria','Southern Germany','Western Slovakia','Northern Italy',
        'Southern Poland','Central Czechia','Western Romania','Northern Croatia'
    );
    v_cities t_cities := t_cities(
        'Budapest','Gyor','Miskolc','Szeged',
        'Vienna','Munich','Bratislava','Milan',
        'Krakow','Prague','Cluj-Napoca','Zagreb'
    );
    v_operators t_operators := t_operators(
        'VoltWay','ChargeFlow','GridSpark','E-Motion Charge','BlueCurrent'
    );

    v_region_idx NUMBER;
    v_operator_idx NUMBER;
BEGIN
    FOR i IN 1..120 LOOP
        v_region_idx := MOD(i - 1, v_regions.COUNT) + 1;
        v_operator_idx := MOD(i - 1, v_operators.COUNT) + 1;

        INSERT INTO stations (
            station_id,
            station_code,
            station_name,
            operator_name,
            region_name,
            city,
            latitude,
            longitude,
            opened_at,
            created_at
        ) VALUES (
            seq_station.NEXTVAL,
            'STN-' || LPAD(i, 4, '0'),
            'EV Hub ' || i,
            v_operators(v_operator_idx),
            v_regions(v_region_idx),
            v_cities(v_region_idx),
            ROUND(45 + DBMS_RANDOM.VALUE(0, 6), 6),
            ROUND(14 + DBMS_RANDOM.VALUE(0, 8), 6),
            DATE '2022-01-01' + TRUNC(DBMS_RANDOM.VALUE(0, 1000)),
            DATE '2022-01-01' + TRUNC(DBMS_RANDOM.VALUE(0, 1000))
        );
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Loaded 120 stations.');
END;
/

-- ============================================================
-- 4. CONNECTORS (~360 rows)
-- ============================================================
DECLARE
    v_status_key NUMBER;
    v_type VARCHAR2(30);
    v_power NUMBER;
BEGIN
    FOR station_id_val IN 1..120 LOOP
        FOR j IN 1..3 LOOP
            IF j = 1 THEN
                v_type := 'TYPE2_AC';
                v_power := 22;
            ELSIF j = 2 THEN
                v_type := 'CCS2_DC';
                v_power := 150;
            ELSE
                v_type := 'CCS2_ULTRA';
                v_power := 350;
            END IF;

            v_status_key := MOD(station_id_val + j, 24);

            INSERT INTO connectors (
                connector_id,
                station_id,
                connector_label,
                connector_type,
                max_power_kw,
                connector_status,
                installed_at
            ) VALUES (
                seq_connector.NEXTVAL,
                station_id_val,
                'C' || LPAD(j, 2, '0'),
                v_type,
                v_power,
                CASE
                    WHEN v_status_key = 0 THEN 'FAULT'
                    WHEN v_status_key IN (1, 2) THEN 'MAINTENANCE'
                    WHEN v_status_key = 3 THEN 'IN_USE'
                    ELSE 'AVAILABLE'
                END,
                DATE '2022-01-01' + TRUNC(DBMS_RANDOM.VALUE(0, 900))
            );
        END LOOP;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Loaded 360 connectors.');
END;
/

-- ============================================================
-- 5. TARIFFS (12 rows)
-- ============================================================
DECLARE
    v_tariff_name VARCHAR2(100);
    v_price NUMBER(8,2);
    v_session_fee NUMBER(8,2);
    v_idle_fee NUMBER(8,2);
    v_from DATE;
    v_to DATE;
BEGIN
    FOR v_year IN 2024..2026 LOOP
        FOR v_tier IN 1..4 LOOP
            v_from := TO_DATE(v_year || '-01-01', 'YYYY-MM-DD');
            v_to := TO_DATE(v_year || '-12-31', 'YYYY-MM-DD');

            IF v_tier = 1 THEN
                v_tariff_name := 'AC_STANDARD_' || v_year;
                v_price := 0.28 + ((v_year - 2024) * 0.01);
                v_session_fee := 1.00;
                v_idle_fee := 0.10;
            ELSIF v_tier = 2 THEN
                v_tariff_name := 'DC_FAST_' || v_year;
                v_price := 0.39 + ((v_year - 2024) * 0.01);
                v_session_fee := 1.50;
                v_idle_fee := 0.15;
            ELSIF v_tier = 3 THEN
                v_tariff_name := 'DC_ULTRA_' || v_year;
                v_price := 0.51 + ((v_year - 2024) * 0.01);
                v_session_fee := 2.50;
                v_idle_fee := 0.20;
            ELSE
                v_tariff_name := 'OFFPEAK_FLEET_' || v_year;
                v_price := 0.24 + ((v_year - 2024) * 0.01);
                v_session_fee := 0.75;
                v_idle_fee := 0.08;
            END IF;

            INSERT INTO tariffs (
                tariff_id,
                tariff_name,
                price_per_kwh,
                session_fee,
                idle_fee_per_min,
                active_from,
                active_to,
                created_at
            ) VALUES (
                seq_tariff.NEXTVAL,
                v_tariff_name,
                v_price,
                v_session_fee,
                v_idle_fee,
                v_from,
                v_to,
                v_from
            );
        END LOOP;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Loaded 12 tariffs.');
END;
/

-- ============================================================
-- 6. CHARGING_SESSIONS (~100,000 rows)
-- ============================================================
DECLARE
    v_batch_size NUMBER := 5000;
    v_vehicle_id NUMBER;
    v_customer_id NUMBER;
    v_connector_id NUMBER;
    v_connector_power NUMBER;
    v_capacity NUMBER(8,2);
    v_session_start DATE;
    v_session_end DATE;
    v_duration_min NUMBER;
    v_session_status VARCHAR2(20);
    v_payment_status VARCHAR2(20);
    v_energy_kwh NUMBER(10,3);
    v_total_cost NUMBER(10,2);
    v_tariff_id NUMBER;
    v_tariff_tier NUMBER;
    v_tariff_year_offset NUMBER;
    v_price NUMBER(8,2);
    v_session_fee NUMBER(8,2);
    v_status_key NUMBER;
    v_hour_of_day NUMBER;

    -- Map a generated vehicle id to a realistic battery capacity.
    FUNCTION get_vehicle_capacity(p_vehicle_id IN NUMBER) RETURN NUMBER IS
        v_model_idx NUMBER;
    BEGIN
        v_model_idx := MOD(p_vehicle_id - 1, 12) + 1;

        RETURN CASE v_model_idx
            WHEN 1 THEN 57
            WHEN 2 THEN 77
            WHEN 3 THEN 74
            WHEN 4 THEN 81
            WHEN 5 THEN 77
            WHEN 6 THEN 60
            WHEN 7 THEN 39
            WHEN 8 THEN 66
            WHEN 9 THEN 69
            WHEN 10 THEN 82
            WHEN 11 THEN 61
            ELSE 50
        END;
    END get_vehicle_capacity;

    -- Map the connector slot pattern to the configured power tiers.
    FUNCTION get_connector_power(p_connector_id IN NUMBER) RETURN NUMBER IS
        v_slot NUMBER;
    BEGIN
        v_slot := MOD(p_connector_id - 1, 3) + 1;

        RETURN CASE v_slot
            WHEN 1 THEN 22
            WHEN 2 THEN 150
            ELSE 350
        END;
    END get_connector_power;

    -- Select the tariff row that matches both year and charging profile.
    FUNCTION get_tariff_for_session(
        p_session_start IN DATE,
        p_connector_power IN NUMBER
    ) RETURN NUMBER IS
        v_year_offset NUMBER;
        v_tier NUMBER;
        v_hour NUMBER;
    BEGIN
        v_year_offset := TO_NUMBER(TO_CHAR(p_session_start, 'YYYY')) - 2024;
        v_hour := TO_NUMBER(TO_CHAR(p_session_start, 'HH24'));

        IF v_hour BETWEEN 0 AND 5 THEN
            v_tier := 4;
        ELSIF p_connector_power <= 22 THEN
            v_tier := 1;
        ELSIF p_connector_power <= 150 THEN
            v_tier := 2;
        ELSE
            v_tier := 3;
        END IF;

        RETURN (v_year_offset * 4) + v_tier;
    END get_tariff_for_session;
BEGIN
    FOR i IN 1..100000 LOOP
        -- Keep ownership and connector references deterministic across the synthetic set.
        v_vehicle_id := MOD(i - 1, 12000) + 1;
        v_customer_id := MOD(v_vehicle_id - 1, 10000) + 1;
        v_connector_id := MOD(i - 1, 360) + 1;
        v_connector_power := get_connector_power(v_connector_id);
        v_capacity := get_vehicle_capacity(v_vehicle_id);
        v_session_start := DATE '2024-01-01' + DBMS_RANDOM.VALUE(0, 1095);
        v_status_key := MOD(i, 20);

        IF v_connector_power = 22 THEN
            v_duration_min := TRUNC(DBMS_RANDOM.VALUE(45, 241));
        ELSIF v_connector_power = 150 THEN
            v_duration_min := TRUNC(DBMS_RANDOM.VALUE(20, 96));
        ELSE
            v_duration_min := TRUNC(DBMS_RANDOM.VALUE(10, 56));
        END IF;

        -- Completed sessions dominate the dataset, while failed/cancelled/started
        -- rows provide realistic edge cases for testing PL/SQL and views.
        IF v_status_key = 0 THEN
            v_session_status := 'FAILED';
        ELSIF v_status_key = 1 THEN
            v_session_status := 'CANCELLED';
        ELSIF v_status_key IN (2, 3) THEN
            v_session_status := 'STARTED';
        ELSE
            v_session_status := 'COMPLETED';
        END IF;

        IF v_session_status = 'STARTED' THEN
            v_session_end := NULL;
        ELSE
            v_session_end := v_session_start + (v_duration_min / 1440);
        END IF;

        -- Energy generation follows different bounds for completed, active,
        -- interrupted, and cancelled sessions.
        IF v_session_status = 'COMPLETED' THEN
            v_energy_kwh := ROUND(
                LEAST(
                    v_capacity * DBMS_RANDOM.VALUE(0.20, 0.90),
                    v_connector_power * (v_duration_min / 60) * DBMS_RANDOM.VALUE(0.55, 0.92)
                ),
                3
            );
        ELSIF v_session_status = 'STARTED' THEN
            v_energy_kwh := ROUND(
                LEAST(
                    v_capacity * DBMS_RANDOM.VALUE(0.05, 0.35),
                    v_connector_power * (v_duration_min / 60) * DBMS_RANDOM.VALUE(0.30, 0.70)
                ),
                3
            );
        ELSIF v_session_status = 'FAILED' THEN
            v_energy_kwh := ROUND(DBMS_RANDOM.VALUE(0.20, 6.00), 3);
        ELSE
            v_energy_kwh := ROUND(DBMS_RANDOM.VALUE(0.00, 1.50), 3);
        END IF;

        v_tariff_id := get_tariff_for_session(v_session_start, v_connector_power);
        v_tariff_tier := MOD(v_tariff_id - 1, 4) + 1;
        v_tariff_year_offset := TRUNC((v_tariff_id - 1) / 4);
        v_hour_of_day := TO_NUMBER(TO_CHAR(v_session_start, 'HH24'));

        -- Recompute tariff pricing locally so generated totals stay self-consistent.
        IF v_tariff_tier = 1 THEN
            v_price := 0.28 + (v_tariff_year_offset * 0.01);
            v_session_fee := 1.00;
        ELSIF v_tariff_tier = 2 THEN
            v_price := 0.39 + (v_tariff_year_offset * 0.01);
            v_session_fee := 1.50;
        ELSIF v_tariff_tier = 3 THEN
            v_price := 0.51 + (v_tariff_year_offset * 0.01);
            v_session_fee := 2.50;
        ELSE
            v_price := 0.24 + (v_tariff_year_offset * 0.01);
            v_session_fee := 0.75;
        END IF;

        -- Payment rules intentionally treat cancelled and failed sessions differently
        -- from settled completed sessions.
        IF v_session_status = 'CANCELLED' THEN
            v_total_cost := 0;
            v_payment_status := 'WAIVED';
        ELSIF v_session_status = 'FAILED' THEN
            v_total_cost := ROUND(v_energy_kwh * v_price, 2);
            v_payment_status := 'WAIVED';
        ELSIF v_session_status = 'STARTED' THEN
            v_total_cost := 0;
            v_payment_status := 'PENDING';
        ELSE
            v_total_cost := ROUND((v_energy_kwh * v_price) + v_session_fee, 2);

            CASE MOD(i, 10)
                WHEN 0 THEN v_payment_status := 'OVERDUE';
                WHEN 1 THEN v_payment_status := 'PENDING';
                WHEN 2 THEN v_payment_status := 'PENDING';
                WHEN 3 THEN v_payment_status := 'WAIVED';
                ELSE v_payment_status := 'PAID';
            END CASE;
        END IF;

        INSERT INTO charging_sessions (
            session_id,
            session_start,
            customer_id,
            vehicle_id,
            connector_id,
            tariff_id,
            session_end,
            session_status,
            payment_status,
            energy_kwh,
            total_cost
        ) VALUES (
            seq_session.NEXTVAL,
            v_session_start,
            v_customer_id,
            v_vehicle_id,
            v_connector_id,
            v_tariff_id,
            v_session_end,
            v_session_status,
            v_payment_status,
            v_energy_kwh,
            v_total_cost
        );

        IF MOD(i, v_batch_size) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;

    COMMIT;

    -- Mark connectors with active sessions as still in use after the load finishes.
    UPDATE connectors c
    SET connector_status = 'IN_USE'
    WHERE connector_status = 'AVAILABLE'
      AND EXISTS (
          SELECT 1
          FROM charging_sessions cs
          WHERE cs.connector_id = c.connector_id
            AND cs.session_status = 'STARTED'
      );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Loaded 100,000 charging sessions.');
END;
/

-- ============================================================
-- 7. METER_READINGS (~110,000 rows)
-- ============================================================
DECLARE
    v_batch_size NUMBER := 5000;
    v_inserted NUMBER := 0;
    v_power NUMBER(8,2);
    v_read_time DATE;
    v_cumulative NUMBER(10,3);

    -- First pass: create one baseline telemetry row for every session.
    CURSOR c_first_pass IS
        SELECT
            cs.session_id,
            cs.session_start,
            NVL(cs.session_end, cs.session_start + (10 / 1440)) AS effective_end,
            cs.session_status,
            cs.energy_kwh,
            con.max_power_kw
        FROM charging_sessions cs
        INNER JOIN connectors con
            ON cs.connector_id = con.connector_id
        ORDER BY cs.session_id;

    -- Second pass: add a later reading to a completed-session sample so the
    -- telemetry table is larger than the session table and supports aggregation.
    CURSOR c_second_pass IS
        SELECT *
        FROM (
            SELECT
                cs.session_id,
                cs.session_start,
                cs.session_end,
                cs.energy_kwh,
                con.max_power_kw
            FROM charging_sessions cs
            INNER JOIN connectors con
                ON cs.connector_id = con.connector_id
            WHERE cs.session_status = 'COMPLETED'
            ORDER BY cs.session_id
        )
        WHERE ROWNUM <= 10000;
BEGIN
    FOR rec IN c_first_pass LOOP
        v_power := ROUND(rec.max_power_kw * DBMS_RANDOM.VALUE(0.45, 0.95), 2);

        IF rec.session_status = 'COMPLETED' THEN
            v_read_time := rec.session_start + ((rec.effective_end - rec.session_start) * 0.55);
            v_cumulative := ROUND(GREATEST(rec.energy_kwh * 0.55, 0.15), 3);
        ELSIF rec.session_status = 'STARTED' THEN
            v_read_time := rec.session_start + (15 / 1440);
            v_cumulative := ROUND(GREATEST(rec.energy_kwh * 0.40, 0.10), 3);
        ELSE
            v_read_time := rec.session_start + (5 / 1440);
            v_cumulative := ROUND(GREATEST(rec.energy_kwh * 0.20, 0.05), 3);
        END IF;

        INSERT INTO meter_readings (
            reading_id,
            session_id,
            session_start,
            reading_time,
            connector_power_kw,
            cumulative_kwh
        ) VALUES (
            seq_reading.NEXTVAL,
            rec.session_id,
            rec.session_start,
            v_read_time,
            v_power,
            v_cumulative
        );

        v_inserted := v_inserted + 1;

        IF MOD(v_inserted, v_batch_size) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;

    FOR rec IN c_second_pass LOOP
        v_power := ROUND(rec.max_power_kw * DBMS_RANDOM.VALUE(0.35, 0.90), 2);
        v_read_time := GREATEST(rec.session_start + (5 / 1440), rec.session_end - (2 / 1440));
        v_cumulative := ROUND(rec.energy_kwh, 3);

        INSERT INTO meter_readings (
            reading_id,
            session_id,
            session_start,
            reading_time,
            connector_power_kw,
            cumulative_kwh
        ) VALUES (
            seq_reading.NEXTVAL,
            rec.session_id,
            rec.session_start,
            v_read_time,
            v_power,
            v_cumulative
        );

        v_inserted := v_inserted + 1;

        IF MOD(v_inserted, v_batch_size) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Loaded ' || v_inserted || ' meter readings.');
END;
/

-- ============================================================
-- 8. MAINTENANCE_TICKETS (~3,000 rows)
-- ============================================================
DECLARE
    TYPE t_issue_codes IS VARRAY(8) OF VARCHAR2(50);
    TYPE t_notes IS VARRAY(8) OF VARCHAR2(200);

    v_issue_codes t_issue_codes := t_issue_codes(
        'TEMP_SPIKE','PAYMENT_TERMINAL','CABLE_LOCK','DISPLAY_FAILURE',
        'COMMUNICATION_LOSS','COOLING_ALERT','VOLTAGE_DROP','RFID_READER'
    );
    v_notes t_notes := t_notes(
        'Technician inspection scheduled.',
        'Remote diagnostics initiated.',
        'User complaint reproduced on site.',
        'Connector temporarily isolated.',
        'Firmware patch required.',
        'Cooling subsystem needs service.',
        'Intermittent issue observed during peak hours.',
        'Restart resolved issue temporarily.'
    );

    v_batch_size NUMBER := 5000;
    v_connector_id NUMBER;
    v_reported_at DATE;
    v_ticket_status VARCHAR2(20);
    v_severity VARCHAR2(20);
    v_resolved_at DATE;
    v_issue_idx NUMBER;
BEGIN
    FOR i IN 1..3000 LOOP
        v_connector_id := MOD(i - 1, 360) + 1;
        v_reported_at := DATE '2024-01-01' + DBMS_RANDOM.VALUE(0, 1095);
        v_issue_idx := MOD(i - 1, v_issue_codes.COUNT) + 1;

        -- Severity and resolution state are distributed to leave a useful mix
        -- of open faults and historical tickets.
        CASE MOD(i, 8)
            WHEN 0 THEN v_severity := 'CRITICAL';
            WHEN 1 THEN v_severity := 'HIGH';
            WHEN 2 THEN v_severity := 'HIGH';
            WHEN 3 THEN v_severity := 'MEDIUM';
            WHEN 4 THEN v_severity := 'MEDIUM';
            ELSE v_severity := 'LOW';
        END CASE;

        CASE MOD(i, 10)
            WHEN 0 THEN v_ticket_status := 'OPEN';
            WHEN 1 THEN v_ticket_status := 'IN_PROGRESS';
            WHEN 2 THEN v_ticket_status := 'IN_PROGRESS';
            WHEN 3 THEN v_ticket_status := 'RESOLVED';
            ELSE v_ticket_status := 'CLOSED';
        END CASE;

        IF v_ticket_status IN ('RESOLVED', 'CLOSED') THEN
            v_resolved_at := v_reported_at + DBMS_RANDOM.VALUE(0.10, 12.00);
        ELSE
            v_resolved_at := NULL;
        END IF;

        INSERT INTO maintenance_tickets (
            ticket_id,
            connector_id,
            reported_at,
            severity_level,
            issue_code,
            ticket_status,
            resolved_at,
            technician_name,
            notes
        ) VALUES (
            seq_ticket.NEXTVAL,
            v_connector_id,
            v_reported_at,
            v_severity,
            v_issue_codes(v_issue_idx),
            v_ticket_status,
            v_resolved_at,
            'Tech_' || LPAD(MOD(i, 120) + 1, 3, '0'),
            v_notes(v_issue_idx)
        );

        IF MOD(i, v_batch_size) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;

    COMMIT;

    -- Open high-severity tickets force FAULT status on the connector.
    UPDATE connectors c
    SET connector_status = 'FAULT'
    WHERE EXISTS (
        SELECT 1
        FROM maintenance_tickets mt
        WHERE mt.connector_id = c.connector_id
          AND mt.ticket_status IN ('OPEN', 'IN_PROGRESS')
          AND mt.severity_level IN ('HIGH', 'CRITICAL')
    );

    -- Lower-severity unresolved tickets move the connector into MAINTENANCE
    -- only when it has not already been escalated to FAULT.
    UPDATE connectors c
    SET connector_status = 'MAINTENANCE'
    WHERE connector_status <> 'FAULT'
      AND EXISTS (
          SELECT 1
          FROM maintenance_tickets mt
          WHERE mt.connector_id = c.connector_id
            AND mt.ticket_status IN ('OPEN', 'IN_PROGRESS')
            AND mt.severity_level IN ('LOW', 'MEDIUM')
      );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Loaded 3,000 maintenance tickets.');
END;
/

PROMPT === All EV charging data loaded successfully ===
