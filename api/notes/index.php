<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: GET");
$user_id = authenticate();

if (!isset($_GET['medicine_id'])) {
    sendResponse(400, 'error', 'medicine_id is required');
}
$medicine_id = $_GET['medicine_id'];

// Validate access
$checkQuery = "SELECT m.id FROM medicines m
               JOIN patient_profiles p ON m.patient_id = p.id
               LEFT JOIN family_members f ON p.id = f.patient_id
               WHERE m.id = :mid AND (p.created_by_user_id = :uid OR f.user_id = :uid)";
$stmt = $conn->prepare($checkQuery);
$stmt->execute([':mid' => $medicine_id, ':uid' => $user_id]);

if ($stmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized');
}

$query = "SELECT n.id, n.medicine_id, n.note_text, n.created_at, u.name as added_by_name 
          FROM care_notes n 
          JOIN users u ON n.added_by_user_id = u.id 
          WHERE n.medicine_id = :mid 
          ORDER BY n.created_at DESC";
$stmt = $conn->prepare($query);
$stmt->execute([':mid' => $medicine_id]);
$notes = $stmt->fetchAll(PDO::FETCH_ASSOC);

sendResponse(200, 'success', 'Notes retrieved', $notes);
?>
