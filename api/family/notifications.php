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

// Check if user has access to this patient
$checkQuery = "SELECT id FROM family_members WHERE patient_id = :pid AND user_id = :uid";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':pid' => $patient_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Access denied to this patient profile');
}

// Fetch family notifications for this patient
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;

$query = "SELECT fn.*, u.name as triggered_by_name 
          FROM family_notifications fn
          JOIN users u ON fn.triggered_by_user_id = u.id
          WHERE fn.patient_id = :pid
          ORDER BY fn.created_at DESC
          LIMIT :lim";

try {
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':pid', $patient_id, PDO::PARAM_INT);
    $stmt->bindParam(':lim', $limit, PDO::PARAM_INT);
    $stmt->execute();
    $notifications = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    sendResponse(200, 'success', 'Notifications retrieved', $notifications);
} catch (Exception $e) {
    sendResponse(500, 'error', 'Database error: ' . $e->getMessage());
}
?>
