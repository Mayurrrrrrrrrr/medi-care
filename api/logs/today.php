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

// Get current Day of Week for matching: 1 (Sun) to 7 (Sat) for MySQL DAYOFWEEK
// Or we can use date('N') for 1 (Mon) to 7 (Sun) and match the schema's 1-7 (which usually follows ISO 1-7 Mon-Sun)
$dow = date('N'); 
$today_date = date('Y-m-d');

$query = "
    SELECT 
        s.id as schedule_id,
        s.time_slot,
        s.label,
        m.id as medicine_id,
        m.name as medicine_name,
        m.dose,
        m.form,
        m.food_timing,
        m.is_critical,
        COALESCE(l.status, 'pending') as status,
        l.id as log_id,
        l.skip_reason,
        l.logged_at,
        :today_date as scheduled_date
    FROM medicine_schedules s
    JOIN medicines m ON s.medicine_id = m.id
    LEFT JOIN reminder_logs l ON l.schedule_id = s.id 
        AND DATE(l.scheduled_datetime) = :today_date
    WHERE m.patient_id = :pid 
    AND FIND_IN_SET(:dow, s.days_of_week)
    AND s.is_active = 1
    ORDER BY s.time_slot ASC
";

try {
    $stmt = $conn->prepare($query);
    $stmt->execute([
        ':pid' => $patient_id,
        ':dow' => $dow,
        ':today_date' => $today_date
    ]);

    $logs = $stmt->fetchAll(PDO::FETCH_ASSOC);
    sendResponse(200, 'success', 'Today adherence logs retrieved', $logs);
} catch (Exception $e) {
    sendResponse(500, 'error', 'Database error: ' . $e->getMessage());
}
?>
