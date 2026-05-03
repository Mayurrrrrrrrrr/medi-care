<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: PUT");
$user_id = authenticate();

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->schedule_id)) {
    sendResponse(400, 'error', 'Schedule ID is required');
}
$schedule_id = $data->schedule_id;

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

$query = "UPDATE medicine_schedules SET time_slot = :time_slot, label = :label, days_of_week = :days_of_week, is_active = :is_active WHERE id = :id";
$stmt = $conn->prepare($query);
$stmt->execute([
    ':time_slot' => $data->time_slot ?? null,
    ':label' => $data->label ?? null,
    ':days_of_week' => $data->days_of_week ?? null,
    ':is_active' => $data->is_active ?? 1,
    ':id' => $schedule_id
]);

sendResponse(200, 'success', 'Schedule updated successfully', $data);
?>
