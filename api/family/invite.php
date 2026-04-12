<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: POST");
$user_id = authenticate();

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->patient_id) || !isset($data->phone)) {
    sendResponse(400, 'error', 'Patient ID and new member Phone are required');
}

$patient_id = $data->patient_id;
$phone = $data->phone;
$role = isset($data->role) ? $data->role : 'member';

// Check if requester is primary
$checkQuery = "SELECT id FROM family_members WHERE patient_id = :pid AND user_id = :uid AND role = 'primary'";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':pid' => $patient_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Only primary family members can invite');
}

// Find user to invite by phone
$userQuery = "SELECT id FROM users WHERE phone = :phone LIMIT 1";
$userStmt = $conn->prepare($userQuery);
$userStmt->bindParam(':phone', $phone);
$userStmt->execute();

if ($userStmt->rowCount() == 0) {
    sendResponse(404, 'error', 'User with this phone number not found. They must register first.');
}

$invitee_id = $userStmt->fetch(PDO::FETCH_ASSOC)['id'];

// Check if already in family
$famCheckQuery = "SELECT id FROM family_members WHERE patient_id = :pid AND user_id = :uid";
$famCheckStmt = $conn->prepare($famCheckQuery);
$famCheckStmt->execute([':pid' => $patient_id, ':uid' => $invitee_id]);

if ($famCheckStmt->rowCount() > 0) {
    sendResponse(409, 'error', 'User is already a family member');
}

// Add to family
$insertQuery = "INSERT INTO family_members (patient_id, user_id, role) VALUES (:pid, :uid, :role)";
$insertStmt = $conn->prepare($insertQuery);
if ($insertStmt->execute([':pid' => $patient_id, ':uid' => $invitee_id, ':role' => $role])) {
    sendResponse(201, 'success', 'Family member invited successfully');
} else {
    sendResponse(500, 'error', 'Failed to invite family member');
}
?>
