<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: POST");
$user_id = authenticate();

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->fcm_token)) {
    sendResponse(400, 'error', 'FCM token is required');
}

$query = "UPDATE users SET fcm_token = :token WHERE id = :id";
$stmt = $conn->prepare($query);
$stmt->execute([
    ':token' => $data->fcm_token,
    ':id' => $user_id
]);

sendResponse(200, 'success', 'FCM token updated');
?>
