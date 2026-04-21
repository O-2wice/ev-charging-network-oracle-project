-- Purpose: Create required PL/SQL objects (function, procedure, trigger).
-- Notes: Includes cursor loops, conditional logic, inserts, updates, and deletes.

-- Function: Calculates session cost from tariff and energy usage.
CREATE OR REPLACE FUNCTION fn_calculate_session_cost (
    p_session_id IN NUMBER,
    p_session_start IN DATE
) RETURN NUMBER
IS
    v_total_cost NUMBER := 0;
    v_found_count NUMBER := 0;

    CURSOR c_session_cost IS
        SELECT cs.session_status,
               cs.energy_kwh,
               t.price_per_kwh,
               t.session_fee
        FROM charging_sessions cs
        INNER JOIN tariffs t
            ON cs.tariff_id = t.tariff_id
        WHERE cs.session_id = p_session_id
          AND cs.session_start = p_session_start;
BEGIN
    -- Return sentinel values for invalid lookup attempts instead of raising to the caller.
    IF p_session_id IS NULL OR p_session_start IS NULL THEN
        RETURN -1;
    END IF;

    FOR rec IN c_session_cost LOOP
        v_found_count := v_found_count + 1;

        -- Cancelled sessions are intentionally treated as zero-cost.
        IF rec.session_status = 'CANCELLED' THEN
            RETURN 0;
        ELSIF rec.energy_kwh > 0 THEN
            v_total_cost := v_total_cost + (rec.energy_kwh * rec.price_per_kwh) + rec.session_fee;
        ELSE
            v_total_cost := v_total_cost + rec.session_fee;
        END IF;
    END LOOP;

    IF v_found_count = 0 THEN
        RETURN -2;
    END IF;

    RETURN ROUND(v_total_cost, 2);
EXCEPTION
    WHEN OTHERS THEN
        RETURN -99;
END fn_calculate_session_cost;
/

PROMPT === Function created ===

-- Procedure: Reviews unpaid sessions, logs audit rows, and updates overdue statuses.
CREATE OR REPLACE PROCEDURE sp_review_unpaid_sessions (
    p_min_amount IN NUMBER DEFAULT 20
)
IS
    v_counter NUMBER := 0;

    CURSOR c_unpaid IS
        SELECT cs.session_id,
               cs.session_start,
               cs.total_cost,
               c.first_name,
               c.last_name
        FROM charging_sessions cs
        INNER JOIN customers c
            ON cs.customer_id = c.customer_id
        WHERE cs.session_status = 'COMPLETED'
          AND cs.payment_status = 'PENDING'
          AND cs.total_cost >= p_min_amount
        ORDER BY cs.total_cost DESC;

    v_rec c_unpaid%ROWTYPE;
BEGIN
    -- Clear older review rows so each procedure run leaves only fresh review evidence.
    DELETE FROM session_audit_log
    WHERE action_type = 'PAYMENT_REVIEW'
      AND session_id IN (
          SELECT session_id
          FROM charging_sessions
          WHERE payment_status = 'PENDING'
      );

    OPEN c_unpaid;
    LOOP
        FETCH c_unpaid INTO v_rec;
        EXIT WHEN c_unpaid%NOTFOUND;

        v_counter := v_counter + 1;

        -- Only larger pending balances are escalated to OVERDUE and written to the audit log.
        IF v_rec.total_cost >= 75 THEN
            INSERT INTO session_audit_log (
                log_id,
                session_id,
                session_start,
                action_type,
                old_status,
                new_status,
                changed_at,
                changed_by,
                details
            ) VALUES (
                seq_session_log.NEXTVAL,
                v_rec.session_id,
                v_rec.session_start,
                'PAYMENT_REVIEW',
                'PENDING',
                'OVERDUE',
                SYSDATE,
                USER,
                'Reviewed session for customer ' || v_rec.first_name || ' ' || v_rec.last_name
            );
            UPDATE charging_sessions
            SET payment_status = 'OVERDUE'
            WHERE session_id = v_rec.session_id
              AND session_start = v_rec.session_start;
        END IF;
    END LOOP;
    CLOSE c_unpaid;

    DBMS_OUTPUT.PUT_LINE('Reviewed unpaid sessions: ' || v_counter);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Procedure error: ' || SQLERRM);
END sp_review_unpaid_sessions;
/

PROMPT === Procedure created ===

-- Trigger: Logs session status changes and updates connector availability.
CREATE OR REPLACE TRIGGER trg_session_status_change
AFTER UPDATE OF session_status ON charging_sessions
FOR EACH ROW
BEGIN
    IF :OLD.session_status <> :NEW.session_status THEN
        -- Every status transition is captured in the audit trail before connector state changes.
        INSERT INTO session_audit_log (
            log_id,
            session_id,
            session_start,
            action_type,
            old_status,
            new_status,
            changed_at,
            changed_by,
            details
        ) VALUES (
            seq_session_log.NEXTVAL,
            :NEW.session_id,
            :NEW.session_start,
            'SESSION_STATUS_CHANGE',
            :OLD.session_status,
            :NEW.session_status,
            SYSDATE,
            USER,
            'Session changed from ' || :OLD.session_status || ' to ' || :NEW.session_status
        );

        -- Keep connector availability synchronized with the final session outcome.
        IF :NEW.session_status = 'COMPLETED' THEN
            UPDATE connectors
            SET connector_status = 'AVAILABLE'
            WHERE connector_id = :NEW.connector_id;
        ELSIF :NEW.session_status = 'FAILED' THEN
            UPDATE connectors
            SET connector_status = 'FAULT'
            WHERE connector_id = :NEW.connector_id;
        ELSIF :NEW.session_status = 'CANCELLED' THEN
            UPDATE connectors
            SET connector_status = 'AVAILABLE'
            WHERE connector_id = :NEW.connector_id;
        END IF;
    END IF;
END trg_session_status_change;
/

PROMPT === Trigger created ===
