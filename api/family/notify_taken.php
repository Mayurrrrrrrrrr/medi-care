<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: POST");
$user_id = authenticate();

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->patient_id) || !isset($data->medicine_name) || !isset($data->schedule_id)) {
    sendResponse(400, 'error', 'patient_id, medicine_name, and schedule_id are required');
}

$patient_id = $data->patient_id;
$medicine_name = $data->medicine_name;
$schedule_id = $data->schedule_id;
$message = isset($data->message) ? $data->message : null;

// Get family members for this patient
$famQuery = "SELECT u.id as user_id, u.name, u.phone, f.role
             FROM family_members f
             JOIN users u ON f.user_id = u.id
             WHERE f.patient_id = :pid AND f.user_id != :uid";
$famStmt = $conn->prepare($famQuery);
$famStmt->execute([':pid' => $patient_id, ':uid' => $user_id]);
$members = $famStmt->fetchAll(PDO::FETCH_ASSOC);

// Get patient name
$patQuery = "SELECT name FROM patient_profiles WHERE id = :pid";
$patStmt = $conn->prepare($patQuery);
$patStmt->execute([':pid' => $patient_id]);
$patient = $patStmt->fetch(PDO::FETCH_ASSOC);

// Store notification record
$notifQuery = "INSERT INTO family_notifications (patient_id, triggered_by_user_id, schedule_id, message)
               VALUES (:pid, :uid, :sid, :msg)";
$notifStmt = $conn->prepare($notifQuery);
$notifStmt->execute([
    ':pid' => $patient_id,
    ':uid' => $user_id,
    ':sid' => $schedule_id,
    ':msg' => $message ?? ($patient['name'] . ' has taken ' . $medicine_name)
]);

$notif_id = $conn->lastInsertId();

sendResponse(201, 'success', 'Family notified', [
    'notification_id' => $notif_id,
    'notified_members' => count($members),
    'patient_name' => $patient['name']
]);
?>
