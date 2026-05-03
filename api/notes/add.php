<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: POST");
$user_id = authenticate();

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->medicine_id) || !isset($data->note_text)) {
    sendResponse(400, 'error', 'medicine_id and note_text are required');
}

// Validate access to medicine
$checkQuery = "SELECT m.id FROM medicines m
               JOIN patient_profiles p ON m.patient_id = p.id
               LEFT JOIN family_members f ON p.id = f.patient_id
               WHERE m.id = :mid AND (p.created_by_user_id = :uid OR f.user_id = :uid)";
$stmt = $conn->prepare($checkQuery);
$stmt->execute([':mid' => $data->medicine_id, ':uid' => $user_id]);

if ($stmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized');
}

$insertQuery = "INSERT INTO care_notes (medicine_id, note_text, added_by_user_id) VALUES (:mid, :text, :uid)";
$stmt = $conn->prepare($insertQuery);
$stmt->execute([
    ':mid' => $data->medicine_id,
    ':text' => $data->note_text,
    ':uid' => $user_id
]);

$noteId = $conn->lastInsertId();

// Fetch created note with user name
$fetchQuery = "SELECT n.id, n.medicine_id, n.note_text, n.created_at, u.name as added_by_name 
               FROM care_notes n 
               JOIN users u ON n.added_by_user_id = u.id 
               WHERE n.id = :id";
$stmt = $conn->prepare($fetchQuery);
$stmt->execute([':id' => $noteId]);
$note = $stmt->fetch(PDO::FETCH_ASSOC);

sendResponse(200, 'success', 'Note added', $note);
?>
