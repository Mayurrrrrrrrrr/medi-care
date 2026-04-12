<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: GET");
$user_id = authenticate();

if (!isset($_GET['id'])) {
    sendResponse(400, 'error', 'Patient ID is required');
}

$patient_id = $_GET['id'];

// Get patient details - must be creator or family member
$query = "
    SELECT p.* 
    FROM patient_profiles p
    LEFT JOIN family_members f ON p.id = f.patient_id AND f.user_id = :user_id
    WHERE p.id = :patient_id AND (p.created_by_user_id = :user_id OR f.user_id = :user_id)
    LIMIT 1
";

$stmt = $conn->prepare($query);
$stmt->bindParam(':patient_id', $patient_id);
$stmt->bindParam(':user_id', $user_id);
$stmt->execute();

if ($stmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized or patient not found');
}

$patient = $stmt->fetch(PDO::FETCH_ASSOC);

// Fetch medicines for this patient
$medQuery = "SELECT * FROM medicines WHERE patient_id = :patient_id ORDER BY created_at DESC";
$medStmt = $conn->prepare($medQuery);
$medStmt->bindParam(':patient_id', $patient_id);
$medStmt->execute();
$patient['medicines'] = $medStmt->fetchAll(PDO::FETCH_ASSOC);

sendResponse(200, 'success', 'Patient details retrieved', $patient);
?>
