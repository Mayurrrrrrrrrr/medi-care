<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: GET");
$user_id = authenticate();

if (!isset($_GET['patient_id'])) {
    sendResponse(400, 'error', 'Patient ID is required');
}

$patient_id = $_GET['patient_id'];

// Permissions
$checkQuery = "SELECT p.id FROM patient_profiles p 
               LEFT JOIN family_members f ON p.id = f.patient_id 
               WHERE p.id = :pid AND (p.created_by_user_id = :uid OR f.user_id = :uid)";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':pid' => $patient_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized to view medicines for this patient');
}

$query = "SELECT * FROM medicines WHERE patient_id = :pid AND deleted_at IS NULL ORDER BY created_at DESC";
$stmt = $conn->prepare($query);
$stmt->execute([':pid' => $patient_id]);
$medicines = $stmt->fetchAll(PDO::FETCH_ASSOC);

sendResponse(200, 'success', 'Medicines retrieved', $medicines);
?>
