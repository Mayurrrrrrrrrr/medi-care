<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: DELETE, POST");
$user_id = authenticate();

$data = json_decode(file_get_contents("php://input"));
$schedule_id = $_GET['schedule_id'] ?? ($data->schedule_id ?? null);

if (!$schedule_id) {
    sendResponse(400, 'error', 'Schedule ID is required');
}

$checkQuery = "SELECT s.id FROM medicine_schedules s
               JOIN medicines m ON s.medicine_id = m.id
               JOIN patient_profiles p ON m.patient_id = p.id
               LEFT JOIN family_members f ON p.id = f.patient_id 
               WHERE s.id = :sid AND (p.created_by_user_id = :uid OR f.user_id = :uid)";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':sid' => $schedule_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized');
}

// Cancel future reminder logs
$cancelQuery = "DELETE FROM reminder_logs WHERE schedule_id = :sid AND scheduled_datetime > NOW() AND status = 'pending'";
$cancelStmt = $conn->prepare($cancelQuery);
$cancelStmt->execute([':sid' => $schedule_id]);

// Hard delete schedule
$query = "DELETE FROM medicine_schedules WHERE id = :id";
$stmt = $conn->prepare($query);
$stmt->execute([':id' => $schedule_id]);

sendResponse(200, 'success', 'Schedule deleted successfully');
?>
