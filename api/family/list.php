<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: GET");
$user_id = authenticate();

if (!isset($_GET['patient_id'])) {
    sendResponse(400, 'error', 'Patient ID is required');
}
$patient_id = (int)$_GET['patient_id'];

// Permissions check: must be a member of the family to see the list
$checkQuery = "SELECT id FROM family_members WHERE patient_id = :pid AND user_id = :uid";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':pid' => $patient_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized to view family for this patient');
}

// Fetch family members
$query = "
    SELECT u.id, u.name, u.phone, f.role 
    FROM family_members f
    JOIN users u ON f.user_id = u.id
    WHERE f.patient_id = :pid
    ORDER BY f.role ASC, u.name ASC
";

try {
    $stmt = $conn->prepare($query);
    $stmt->execute([':pid' => $patient_id]);
    $family = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    sendResponse(200, 'success', 'Family members retrieved', $family);
} catch (Exception $e) {
    sendResponse(500, 'error', 'Database error: ' . $e->getMessage());
}
?>
