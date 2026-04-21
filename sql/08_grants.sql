-- Evaluation access for the course account.
GRANT SELECT ON customers TO lkpeter;
GRANT SELECT ON vehicles TO lkpeter;
GRANT SELECT ON stations TO lkpeter;
GRANT SELECT ON connectors TO lkpeter;
GRANT SELECT ON tariffs TO lkpeter;
GRANT SELECT ON charging_sessions TO lkpeter;
GRANT SELECT ON meter_readings TO lkpeter;
GRANT SELECT ON maintenance_tickets TO lkpeter;
GRANT SELECT ON session_audit_log TO lkpeter;

GRANT SELECT ON vw_completed_session_details TO lkpeter;
GRANT SELECT ON vw_high_utilization_connectors TO lkpeter;

GRANT EXECUTE ON fn_calculate_session_cost TO lkpeter;
GRANT EXECUTE ON sp_review_unpaid_sessions TO lkpeter;

PROMPT === Grants completed ===
