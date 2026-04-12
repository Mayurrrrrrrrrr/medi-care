<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

// Using POST as standard PUT with JSON body can sometimes be tricky on shared hosts without proper routing,
// but we'll accept PUT correctly via file_get_contents.
header("Access-Control-Allow-Methods: PUT");
$user_id = authenticate();

$data = json_decode(file_get_contents("php://input"));

if (!isset($_GET['id'])) {
    sendResponse(400, 'error', 'Patient ID is required in URL parameter ?id=');
}

$patient_id = $_GET['id'];

// Check access
$checkQuery = "SELECT id FROM patient_profiles WHERE id = :id AND created_by_user_id = :uid";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':id' => $patient_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized to update this patient profile');
}

// Build dynamic update query
$fields = [];
$params = [':id' => $patient_id];

if (isset($data->name)) { $fields[] = "name = :name"; $params[':name'] = $data->name; }
if (isset($data->photo_url)) { $fields[] = "photo_url = :photo_url"; $params[':photo_url'] = $data->photo_url; }
if (isset($data->conditions)) { $fields[] = "conditions = :conditions"; $params[':conditions'] = $data->conditions; }
if (isset($data->doctor_name)) { $fields[] = "doctor_name = :doctor_name"; $params[':doctor_name'] = $data->doctor_name; }
if (isset($data->emergency_contact)) { $fields[] = "emergency_contact = :emergency_contact"; $params[':emergency_contact'] = $data->emergency_contact; }

if (count($fields) > 0) {
    $query = "UPDATE patient_profiles SET " . implode(", ", $fields) . " WHERE id = :id";
    $stmt = $conn->prepare($query);
    if ($stmt->execute($params)) {
        sendResponse(200, 'success', 'Patient updated successfully');
    } else {
        sendResponse(500, 'error', 'Failed to update patient');
    }
} else {
    sendResponse(400, 'error', 'No fields provided to update');
}
?>
