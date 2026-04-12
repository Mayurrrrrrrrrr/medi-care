<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: DELETE");
$user_id = authenticate();

if (!isset($_GET['id'])) {
    sendResponse(400, 'error', 'Schedule ID is required');
}

$schedule_id = $_GET['id'];

// Verify auth via medicine -> patient chain
$checkQuery = "SELECT s.id FROM medicine_schedules s
               JOIN medicines m ON s.medicine_id = m.id
               JOIN patient_profiles p ON m.patient_id = p.id
               LEFT JOIN family_members f ON p.id = f.patient_id 
               WHERE s.id = :sid AND (p.created_by_user_id = :uid OR f.user_id = :uid)";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':sid' => $schedule_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized to delete this schedule');
}

$query = "DELETE FROM medicine_schedules WHERE id = :id";
$stmt = $conn->prepare($query);
if ($stmt->execute([':id' => $schedule_id])) {
    sendResponse(200, 'success', 'Schedule deleted successfully');
} else {
    sendResponse(500, 'error', 'Failed to delete schedule');
}
?>
