<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: GET");
$user_id = authenticate();

if (!isset($_GET['patient_id'])) {
    sendResponse(400, 'error', 'Patient ID is required');
}
$patient_id = (int)$_GET['patient_id'];

// Optional date filter: ?date=2026-04-06 or default to last 7 days
$date_filter = isset($_GET['date']) ? $_GET['date'] : null;
$days = isset($_GET['days']) ? (int)$_GET['days'] : 7;

try {
    if ($date_filter) {
        // Get logs for a specific date
        $query = "
            SELECT 
                l.id as log_id,
                l.status,
                l.skip_reason,
                l.logged_at,
                DATE(l.scheduled_datetime) as scheduled_date,
                TIME(l.scheduled_datetime) as time_slot,
                m.id as medicine_id,
                m.name as medicine_name,
                m.dose,
                m.form,
                m.food_timing,
                m.is_critical
            FROM reminder_logs l
            JOIN medicine_schedules s ON l.schedule_id = s.id
            JOIN medicines m ON s.medicine_id = m.id
            WHERE m.patient_id = :pid 
            AND DATE(l.scheduled_datetime) = :target_date
            ORDER BY l.scheduled_datetime DESC
        ";
        $stmt = $conn->prepare($query);
        $stmt->execute([
            ':pid' => $patient_id,
            ':target_date' => $date_filter
        ]);
    } else {
        // Get logs for the last N days
        $query = "
            SELECT 
                l.id as log_id,
                l.status,
                l.skip_reason,
                l.logged_at,
                DATE(l.scheduled_datetime) as scheduled_date,
                TIME(l.scheduled_datetime) as time_slot,
                m.id as medicine_id,
                m.name as medicine_name,
                m.dose,
                m.form,
                m.food_timing,
                m.is_critical
            FROM reminder_logs l
            JOIN medicine_schedules s ON l.schedule_id = s.id
            JOIN medicines m ON s.medicine_id = m.id
            WHERE m.patient_id = :pid 
            AND l.scheduled_datetime >= DATE_SUB(CURDATE(), INTERVAL :days DAY)
            ORDER BY l.scheduled_datetime DESC
        ";
        $stmt = $conn->prepare($query);
        $stmt->execute([
            ':pid' => $patient_id,
            ':days' => $days
        ]);
    }

    $logs = $stmt->fetchAll(PDO::FETCH_ASSOC);
    sendResponse(200, 'success', 'History logs retrieved', $logs);
} catch (Exception $e) {
    sendResponse(500, 'error', 'Database error: ' . $e->getMessage());
}
?>
