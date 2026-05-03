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

// Find doses that are overdue by 10+ minutes and not taken/skipped
$query = "
    SELECT 
        s.id as schedule_id,
        s.time_slot,
        m.id as medicine_id,
        m.name as medicine_name,
        m.dose,
        m.is_critical,
        p.name as patient_name,
        TIMESTAMPDIFF(MINUTE, 
            CONCAT(CURDATE(), ' ', s.time_slot), 
            NOW()
        ) as minutes_overdue
    FROM medicine_schedules s
    JOIN medicines m ON s.medicine_id = m.id
    JOIN patient_profiles p ON m.patient_id = p.id
    LEFT JOIN reminder_logs l ON l.schedule_id = s.id 
        AND DATE(l.scheduled_datetime) = CURDATE()
        AND l.status IN ('taken', 'skipped')
    WHERE m.patient_id = :pid
    AND s.is_active = 1
    AND FIND_IN_SET(WEEKDAY(CURDATE()) + 1, REPLACE(s.days_of_week, 'Everyday', '1,2,3,4,5,6,7'))
    AND CONCAT(CURDATE(), ' ', s.time_slot) <= NOW()
    AND TIMESTAMPDIFF(MINUTE, CONCAT(CURDATE(), ' ', s.time_slot), NOW()) >= 10
    AND l.id IS NULL
    ORDER BY s.time_slot ASC
";

try {
    $stmt = $conn->prepare($query);
    $stmt->execute([':pid' => $patient_id]);
    $missed = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    sendResponse(200, 'success', 'Missed doses check', [
        'missed_count' => count($missed),
        'missed_doses' => $missed
    ]);
} catch (Exception $e) {
    sendResponse(500, 'error', 'Database error: ' . $e->getMessage());
}
?>
