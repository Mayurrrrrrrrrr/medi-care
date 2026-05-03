<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: PUT");
$user_id = authenticate();

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->medicine_id)) {
    sendResponse(400, 'error', 'Medicine ID is required');
}
$medicine_id = $data->medicine_id;

$checkQuery = "SELECT m.id FROM medicines m
               JOIN patient_profiles p ON m.patient_id = p.id
               LEFT JOIN family_members f ON p.id = f.patient_id 
               WHERE m.id = :mid AND (p.created_by_user_id = :uid OR f.user_id = :uid)";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':mid' => $medicine_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized');
}

$query = "UPDATE medicines SET 
    name = :name, form = :form, dose = :dose, food_timing = :food_timing, 
    is_critical = :is_critical, stock_count = :stock_count, stock_alert_at = :stock_alert_at 
    WHERE id = :id";
$stmt = $conn->prepare($query);
$stmt->execute([
    ':name' => $data->name ?? null,
    ':form' => $data->form ?? null,
    ':dose' => $data->dose ?? null,
    ':food_timing' => $data->food_timing ?? null,
    ':is_critical' => $data->is_critical ?? 0,
    ':stock_count' => $data->stock_count ?? 0,
    ':stock_alert_at' => $data->stock_alert_at ?? 10,
    ':id' => $medicine_id
]);

sendResponse(200, 'success', 'Medicine updated successfully', $data);
?>
