<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: DELETE, POST");
$user_id = authenticate();

$data = json_decode(file_get_contents("php://input"));
$medicine_id = $_GET['medicine_id'] ?? ($data->medicine_id ?? null);

if (!$medicine_id) {
    sendResponse(400, 'error', 'Medicine ID is required');
}

$checkQuery = "SELECT m.id FROM medicines m
               JOIN patient_profiles p ON m.patient_id = p.id
               LEFT JOIN family_members f ON p.id = f.patient_id 
               WHERE m.id = :mid AND (p.created_by_user_id = :uid OR f.user_id = :uid)";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':mid' => $medicine_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized');
}

$query = "UPDATE medicines SET deleted_at = CURRENT_TIMESTAMP WHERE id = :id";
$stmt = $conn->prepare($query);
$stmt->execute([':id' => $medicine_id]);

sendResponse(200, 'success', 'Medicine deleted successfully');
?>
