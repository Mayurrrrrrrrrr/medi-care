<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: POST");
$user_id = authenticate();

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->medicine_id) || !isset($data->time_slot) || !isset($data->days_of_week)) {
    sendResponse(400, 'error', 'Missing required schedule fields');
}

// Verify auth
$checkQuery = "SELECT m.id FROM medicines m
               JOIN patient_profiles p ON m.patient_id = p.id
               LEFT JOIN family_members f ON p.id = f.patient_id 
               WHERE m.id = :mid AND (p.created_by_user_id = :uid OR f.user_id = :uid)";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':mid' => $data->medicine_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized to add schedule for this medicine');
}

$query = "INSERT INTO medicine_schedules (medicine_id, time_slot, label, days_of_week, is_active) 
          VALUES (:medicine_id, :time_slot, :label, :days_of_week, 1)";

$stmt = $conn->prepare($query);
$stmt->execute([
    ':medicine_id' => $data->medicine_id,
    ':time_slot' => $data->time_slot,
    ':label' => isset($data->label) ? $data->label : null,
    ':days_of_week' => $data->days_of_week
]);

$schedule_id = $conn->lastInsertId();
sendResponse(201, 'success', 'Schedule added successfully', ['id' => $schedule_id]);
?>
