<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: GET");
$user_id = authenticate();

if (!isset($_GET['medicine_id'])) {
    sendResponse(400, 'error', 'Medicine ID is required');
}

$medicine_id = $_GET['medicine_id'];

// Get schedules along with any voice reminder
$query = "
    SELECT s.*, v.file_url 
    FROM medicine_schedules s
    LEFT JOIN voice_reminders v ON s.id = v.schedule_id
    WHERE s.medicine_id = :mid
    ORDER BY s.time_slot ASC
";
$stmt = $conn->prepare($query);
$stmt->execute([':mid' => $medicine_id]);
$schedules = $stmt->fetchAll(PDO::FETCH_ASSOC);

sendResponse(200, 'success', 'Schedules retrieved', $schedules);
?>
