<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: PUT");
$user_id = authenticate();

$data = json_decode(file_get_contents("php://input"));

if (!isset($_GET['id'])) {
    sendResponse(400, 'error', 'Schedule ID is required');
}

$schedule_id = $_GET['id'];

// Verify auth
$checkQuery = "SELECT s.id FROM medicine_schedules s
               JOIN medicines m ON s.medicine_id = m.id
               JOIN patient_profiles p ON m.patient_id = p.id
               LEFT JOIN family_members f ON p.id = f.patient_id 
               WHERE s.id = :sid AND (p.created_by_user_id = :uid OR f.user_id = :uid)";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':sid' => $schedule_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized to update this schedule');
}

$fields = [];
$params = [':id' => $schedule_id];

$updatable = ['time_slot', 'label', 'days_of_week', 'is_active'];

foreach ($updatable as $field) {
    if (isset($data->$field)) {
        $fields[] = "$field = :$field";
        $params[":$field"] = $data->$field;
    }
}

if (count($fields) > 0) {
    $query = "UPDATE medicine_schedules SET " . implode(", ", $fields) . " WHERE id = :id";
    $stmt = $conn->prepare($query);
    if ($stmt->execute($params)) {
        sendResponse(200, 'success', 'Schedule updated successfully');
    } else {
        sendResponse(500, 'error', 'Failed to update schedule');
    }
} else {
    sendResponse(400, 'error', 'No fields provided to update');
}
?>
