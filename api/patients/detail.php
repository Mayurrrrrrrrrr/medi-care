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

// Validate user has access via family_members table or created_by_user_id
$checkQuery = "
    SELECT p.* FROM patient_profiles p
    LEFT JOIN family_members f ON p.id = f.patient_id
    WHERE p.id = :pid AND (p.created_by_user_id = :uid OR f.user_id = :uid)
";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':pid' => $patient_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized or patient not found');
}
$patient = $checkStmt->fetch(PDO::FETCH_ASSOC);

// Fetch medicines with schedules
$medQuery = "SELECT * FROM medicines WHERE patient_id = :pid AND deleted_at IS NULL";
$medStmt = $conn->prepare($medQuery);
$medStmt->execute([':pid' => $patient_id]);
$medicines = $medStmt->fetchAll(PDO::FETCH_ASSOC);

foreach ($medicines as &$med) {
    $schedQuery = "
        SELECT s.*, v.file_url as voice_url 
        FROM medicine_schedules s 
        LEFT JOIN voice_reminders v ON s.id = v.schedule_id 
        WHERE s.medicine_id = :mid
    ";
    $schedStmt = $conn->prepare($schedQuery);
    $schedStmt->execute([':mid' => $med['id']]);
    $med['schedules'] = $schedStmt->fetchAll(PDO::FETCH_ASSOC);
}
$patient['medicines'] = $medicines;

sendResponse(200, 'success', 'Patient details retrieved', $patient);
?>
