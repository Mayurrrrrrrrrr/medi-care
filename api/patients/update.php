<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: PUT");
$user_id = authenticate();

$data = json_decode(file_get_contents("php://input"));

$patient_id = $_GET['patient_id'] ?? ($data->patient_id ?? null);

if (!$patient_id) {
    sendResponse(400, 'error', 'Patient ID is required');
}

// Validate user has access
$checkQuery = "
    SELECT p.id FROM patient_profiles p
    LEFT JOIN family_members f ON p.id = f.patient_id
    WHERE p.id = :pid AND (p.created_by_user_id = :uid OR f.user_id = :uid)
";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':pid' => $patient_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized');
}

$query = "UPDATE patient_profiles SET 
    name = :name, 
    conditions = :conditions, 
    doctor_name = :doctor_name, 
    emergency_contact = :emergency_contact, 
    photo_url = :photo_url 
    WHERE id = :id";
    
$stmt = $conn->prepare($query);
$stmt->execute([
    ':name' => $data->name ?? null,
    ':conditions' => $data->conditions ?? null,
    ':doctor_name' => $data->doctor_name ?? null,
    ':emergency_contact' => $data->emergency_contact ?? null,
    ':photo_url' => $data->photo_url ?? null,
    ':id' => $patient_id
]);

sendResponse(200, 'success', 'Patient updated successfully', $data);
?>
