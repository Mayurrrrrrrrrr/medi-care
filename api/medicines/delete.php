<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: DELETE");
$user_id = authenticate();

if (!isset($_GET['id'])) {
    sendResponse(400, 'error', 'Medicine ID is required');
}

$medicine_id = $_GET['id'];

$checkQuery = "SELECT p.id FROM medicines m
               JOIN patient_profiles p ON m.patient_id = p.id
               LEFT JOIN family_members f ON p.id = f.patient_id 
               WHERE m.id = :mid AND (p.created_by_user_id = :uid OR f.user_id = :uid)";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':mid' => $medicine_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized to delete this medicine');
}

// Hard delete (cascade will delete schedules & logs)
$query = "DELETE FROM medicines WHERE id = :id";
$stmt = $conn->prepare($query);
if ($stmt->execute([':id' => $medicine_id])) {
    sendResponse(200, 'success', 'Medicine deleted successfully');
} else {
    sendResponse(500, 'error', 'Failed to delete medicine');
}
?>
