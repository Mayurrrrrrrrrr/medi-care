<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: POST");
$user_id = authenticate();

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->schedule_id) || !isset($data->patient_id) || !isset($data->status)) {
    sendResponse(400, 'error', 'Missing required logging fields');
}

$scheduled_datetime = isset($data->scheduled_datetime) ? $data->scheduled_datetime : date('Y-m-d H:i:00');
$status = $data->status;

// Permission Check: User must be creator or in family_members
$checkQuery = "SELECT p.id FROM patient_profiles p 
               LEFT JOIN family_members f ON p.id = f.patient_id 
               WHERE p.id = :pid AND (p.created_by_user_id = :uid OR f.user_id = :uid)";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':pid' => $data->patient_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized to update logs for this patient');
}

try {
    // We insert or update a record for adherence tracking.
    $query = "INSERT INTO reminder_logs (schedule_id, patient_id, scheduled_datetime, status, updated_by_user_id, skip_reason)
              VALUES (:schedule_id, :patient_id, :scheduled_datetime, :status, :uid, :reason)
              ON DUPLICATE KEY UPDATE 
              status = VALUES(status), 
              updated_by_user_id = VALUES(updated_by_user_id), 
              skip_reason = VALUES(skip_reason)";
    
    $stmt = $conn->prepare($query);
    $stmt->execute([
        ':schedule_id' => $data->schedule_id,
        ':patient_id' => $data->patient_id,
        ':scheduled_datetime' => $scheduled_datetime,
        ':status' => $status,
        ':uid' => $user_id,
        ':reason' => isset($data->skip_reason) ? $data->skip_reason : null
    ]);

    sendResponse(201, 'success', 'Alarm log tracked successfully', ['id' => $conn->lastInsertId()]);
} catch (Exception $e) {
    sendResponse(500, 'error', 'Database error: ' . $e->getMessage());
}
?>
