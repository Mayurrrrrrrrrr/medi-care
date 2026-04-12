<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: POST");
$user_id = authenticate();

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->patient_id) || !isset($data->name) || !isset($data->form) || !isset($data->dose) || !isset($data->food_timing) || !isset($data->start_date)) {
    sendResponse(400, 'error', 'Missing required medicine fields');
}

// Verify authorization to add for patient
$checkQuery = "SELECT p.id FROM patient_profiles p 
               LEFT JOIN family_members f ON p.id = f.patient_id 
               WHERE p.id = :pid AND (p.created_by_user_id = :uid OR f.user_id = :uid)";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':pid' => $data->patient_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized to add medicines for this patient');
}

$query = "INSERT INTO medicines (patient_id, name, form, dose, color_shape, food_timing, is_critical, start_date, end_date, stock_count, stock_alert_at, added_by_user_id) 
          VALUES (:patient_id, :name, :form, :dose, :color_shape, :food_timing, :is_critical, :start_date, :end_date, :stock_count, :stock_alert_at, :added_by_user_id)";

$stmt = $conn->prepare($query);
$stmt->execute([
    ':patient_id' => $data->patient_id,
    ':name' => $data->name,
    ':form' => $data->form,
    ':dose' => $data->dose,
    ':color_shape' => isset($data->color_shape) ? $data->color_shape : null,
    ':food_timing' => $data->food_timing,
    ':is_critical' => isset($data->is_critical) ? $data->is_critical : 0,
    ':start_date' => $data->start_date,
    ':end_date' => isset($data->end_date) ? $data->end_date : null,
    ':stock_count' => isset($data->stock_count) ? $data->stock_count : 0,
    ':stock_alert_at' => isset($data->stock_alert_at) ? $data->stock_alert_at : 10,
    ':added_by_user_id' => $user_id
]);

$medicine_id = $conn->lastInsertId();

sendResponse(201, 'success', 'Medicine added successfully', ['id' => $medicine_id]);
?>
