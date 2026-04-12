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

// Check if user has access to patient
$checkQuery = "SELECT id FROM family_members WHERE patient_id = :pid AND user_id = :uid";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':pid' => $patient_id, ':uid' => $user_id]);

// If not family member, check if creator
if ($checkStmt->rowCount() == 0) {
    $creatorQuery = "SELECT id FROM patient_profiles WHERE id = :pid AND created_by_user_id = :uid";
    $creatorStmt = $conn->prepare($creatorQuery);
    $creatorStmt->execute([':pid' => $patient_id, ':uid' => $user_id]);
    if($creatorStmt->rowCount() == 0) {
        sendResponse(403, 'error', 'Unauthorized to view this family list');
    }
}

// Get family list
$query = "
    SELECT f.id as family_role_id, f.role, u.id as user_id, u.name, u.phone 
    FROM family_members f
    JOIN users u ON f.user_id = u.id
    WHERE f.patient_id = :pid
    ORDER BY f.role = 'primary' DESC, u.name ASC
";
$stmt = $conn->prepare($query);
$stmt->bindParam(':pid', $patient_id);
$stmt->execute();

$members = $stmt->fetchAll(PDO::FETCH_ASSOC);

sendResponse(200, 'success', 'Family members retrieved', $members);
?>
