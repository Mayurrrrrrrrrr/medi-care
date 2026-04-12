<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: POST");
$user_id = authenticate();

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->name)) {
    sendResponse(400, 'error', 'Patient name is required');
}

try {
    // 1. Insert patient profile
    $query = "INSERT INTO patient_profiles (name, conditions, doctor_name, emergency_contact, created_by_user_id) 
              VALUES (:name, :conditions, :doctor_name, :emergency_contact, :created_by_user_id)";
    
    $stmt = $conn->prepare($query);
    $stmt->execute([
        ':name' => $data->name,
        ':conditions' => isset($data->conditions) ? $data->conditions : null,
        ':doctor_name' => isset($data->doctor_name) ? $data->doctor_name : null,
        ':emergency_contact' => isset($data->emergency_contact) ? $data->emergency_contact : null,
        ':created_by_user_id' => $user_id
    ]);
    
    $patient_id = $conn->lastInsertId();
    
    // 2. Automatically link the creator as the 'primary' family member to grant them immediate Admin rights
    $linkQuery = "INSERT INTO family_members (patient_id, user_id, role) VALUES (:pid, :uid, 'primary')";
    $linkStmt = $conn->prepare($linkQuery);
    $linkStmt->execute([
        ':pid' => $patient_id,
        ':uid' => $user_id
    ]);
    
    sendResponse(201, 'success', 'Patient profile created successfully', ['id' => $patient_id]);
} catch (Exception $e) {
    sendResponse(500, 'error', 'Database error: ' . $e->getMessage());
}
?>
