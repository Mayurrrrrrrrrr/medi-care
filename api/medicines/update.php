<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: PUT");
$user_id = authenticate();

$data = json_decode(file_get_contents("php://input"));

if (!isset($_GET['id'])) {
    sendResponse(400, 'error', 'Medicine ID is required in URL parameter ?id=');
}

$medicine_id = $_GET['id'];

// Check auth via patient
$checkQuery = "SELECT p.id FROM medicines m
               JOIN patient_profiles p ON m.patient_id = p.id
               LEFT JOIN family_members f ON p.id = f.patient_id 
               WHERE m.id = :mid AND (p.created_by_user_id = :uid OR f.user_id = :uid)";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':mid' => $medicine_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized to update this medicine');
}

$fields = [];
$params = [':id' => $medicine_id];

$updatable_fields = ['name', 'form', 'dose', 'color_shape', 'food_timing', 'is_critical', 'end_date', 'stock_count', 'stock_alert_at', 'pill_photo_url'];

foreach ($updatable_fields as $field) {
    if (isset($data->$field)) {
        $fields[] = "$field = :$field";
        $params[":$field"] = $data->$field;
    }
}

if (count($fields) > 0) {
    $query = "UPDATE medicines SET " . implode(", ", $fields) . " WHERE id = :id";
    $stmt = $conn->prepare($query);
    if ($stmt->execute($params)) {
        sendResponse(200, 'success', 'Medicine updated successfully');
    } else {
        sendResponse(500, 'error', 'Failed to update medicine');
    }
} else {
    sendResponse(400, 'error', 'No fields provided to update');
}
?>
