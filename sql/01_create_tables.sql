-- EV Charging Network Management System
-- Core schema definition

BEGIN EXECUTE IMMEDIATE 'DROP TABLE meter_readings CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE maintenance_tickets CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE charging_sessions CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP CLUSTER station_connector_cluster INCLUDING TABLES CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE connectors CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE stations CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE vehicles CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE customers CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE tariffs CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE session_audit_log CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE customers (
    customer_id     NUMBER         PRIMARY KEY,
    first_name      VARCHAR2(100)  NOT NULL,
    last_name       VARCHAR2(100)  NOT NULL,
    email           VARCHAR2(200)  UNIQUE NOT NULL,
    phone           VARCHAR2(50),
    country         VARCHAR2(100),
    city            VARCHAR2(100),
    registration_at DATE           DEFAULT SYSDATE
);

CREATE TABLE vehicles (
    vehicle_id            NUMBER         PRIMARY KEY,
    customer_id           NUMBER         NOT NULL,
    plate_number          VARCHAR2(30)   UNIQUE NOT NULL,
    brand                 VARCHAR2(100)  NOT NULL,
    model_name            VARCHAR2(100)  NOT NULL,
    battery_capacity_kwh  NUMBER(8,2)    NOT NULL,
    model_year            NUMBER(4),
    created_at            DATE           DEFAULT SYSDATE,
    CONSTRAINT fk_vehicle_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE CLUSTER station_connector_cluster (
    station_id NUMBER
)
SIZE 512;

CREATE INDEX idx_station_connector_cluster
    ON CLUSTER station_connector_cluster;

CREATE TABLE stations (
    station_id      NUMBER         PRIMARY KEY,
    station_code    VARCHAR2(40)   UNIQUE NOT NULL,
    station_name    VARCHAR2(200)  NOT NULL,
    operator_name   VARCHAR2(150)  NOT NULL,
    region_name     VARCHAR2(100)  NOT NULL,
    city            VARCHAR2(100)  NOT NULL,
    latitude        NUMBER(10,6),
    longitude       NUMBER(10,6),
    opened_at       DATE,
    created_at      DATE           DEFAULT SYSDATE
) CLUSTER station_connector_cluster (station_id);

CREATE TABLE connectors (
    connector_id       NUMBER         PRIMARY KEY,
    station_id         NUMBER         NOT NULL,
    connector_label    VARCHAR2(30)   NOT NULL,
    connector_type     VARCHAR2(30)   NOT NULL,
    max_power_kw       NUMBER(8,2)    NOT NULL,
    connector_status   VARCHAR2(20)   DEFAULT 'AVAILABLE' NOT NULL,
    installed_at       DATE,
    CONSTRAINT uq_connector_station_label UNIQUE (station_id, connector_label),
    CONSTRAINT chk_connector_status CHECK (connector_status IN ('AVAILABLE', 'IN_USE', 'FAULT', 'MAINTENANCE')),
    CONSTRAINT fk_connector_station
        FOREIGN KEY (station_id) REFERENCES stations(station_id)
)
CLUSTER station_connector_cluster (station_id);

CREATE TABLE tariffs (
    tariff_id            NUMBER         PRIMARY KEY,
    tariff_name          VARCHAR2(100)  NOT NULL,
    price_per_kwh        NUMBER(8,2)    NOT NULL,
    session_fee          NUMBER(8,2)    DEFAULT 0 NOT NULL,
    idle_fee_per_min     NUMBER(8,2)    DEFAULT 0 NOT NULL,
    active_from          DATE           NOT NULL,
    active_to            DATE,
    created_at           DATE           DEFAULT SYSDATE
);

CREATE TABLE charging_sessions (
    session_id        NUMBER         NOT NULL,
    session_start     DATE           NOT NULL,
    customer_id       NUMBER         NOT NULL,
    vehicle_id        NUMBER         NOT NULL,
    connector_id      NUMBER         NOT NULL,
    tariff_id         NUMBER         NOT NULL,
    session_end       DATE,
    session_status    VARCHAR2(20)   DEFAULT 'STARTED' NOT NULL,
    payment_status    VARCHAR2(20)   DEFAULT 'PENDING' NOT NULL,
    energy_kwh        NUMBER(10,3)   DEFAULT 0 NOT NULL,
    total_cost        NUMBER(10,2)   DEFAULT 0 NOT NULL,
    CONSTRAINT pk_charging_sessions PRIMARY KEY (session_id, session_start),
    CONSTRAINT chk_session_status CHECK (session_status IN ('STARTED', 'COMPLETED', 'FAILED', 'CANCELLED')),
    CONSTRAINT chk_payment_status CHECK (payment_status IN ('PENDING', 'PAID', 'OVERDUE', 'WAIVED')),
    CONSTRAINT fk_session_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_session_vehicle
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
    CONSTRAINT fk_session_connector
        FOREIGN KEY (connector_id) REFERENCES connectors(connector_id),
    CONSTRAINT fk_session_tariff
        FOREIGN KEY (tariff_id) REFERENCES tariffs(tariff_id)
)
PARTITION BY RANGE (session_start) (
    PARTITION p_sessions_2024 VALUES LESS THAN (DATE '2025-01-01'),
    PARTITION p_sessions_2025 VALUES LESS THAN (DATE '2026-01-01'),
    PARTITION p_sessions_2026 VALUES LESS THAN (DATE '2027-01-01'),
    PARTITION p_sessions_future VALUES LESS THAN (MAXVALUE)
);

CREATE TABLE meter_readings (
    reading_id           NUMBER         PRIMARY KEY,
    session_id           NUMBER         NOT NULL,
    session_start        DATE           NOT NULL,
    reading_time         DATE           NOT NULL,
    connector_power_kw   NUMBER(8,2),
    cumulative_kwh       NUMBER(10,3),
    CONSTRAINT fk_reading_session
        FOREIGN KEY (session_id, session_start)
        REFERENCES charging_sessions(session_id, session_start)
);

CREATE TABLE maintenance_tickets (
    ticket_id          NUMBER         PRIMARY KEY,
    connector_id       NUMBER         NOT NULL,
    reported_at        DATE           NOT NULL,
    severity_level     VARCHAR2(20)   NOT NULL,
    issue_code         VARCHAR2(50)   NOT NULL,
    ticket_status      VARCHAR2(20)   DEFAULT 'OPEN' NOT NULL,
    resolved_at        DATE,
    technician_name    VARCHAR2(100),
    notes              VARCHAR2(1000),
    CONSTRAINT chk_ticket_severity CHECK (severity_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    CONSTRAINT chk_ticket_status CHECK (ticket_status IN ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED')),
    CONSTRAINT fk_ticket_connector
        FOREIGN KEY (connector_id) REFERENCES connectors(connector_id)
);

CREATE TABLE session_audit_log (
    log_id               NUMBER         PRIMARY KEY,
    session_id           NUMBER,
    session_start        DATE,
    action_type          VARCHAR2(50)   NOT NULL,
    old_status           VARCHAR2(20),
    new_status           VARCHAR2(20),
    changed_at           DATE           DEFAULT SYSDATE,
    changed_by           VARCHAR2(100)  DEFAULT USER,
    details              VARCHAR2(1000)
);

PROMPT === All EV charging tables created successfully ===
-- Purpose: Create core tables, constraints, and clustered storage for the EV charging schema.
-- Notes: Run before sequences and data load.
