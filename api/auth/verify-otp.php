<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: POST");

// We receive the FCM token and the verified phone number from Firebase Auth.
$data = json_decode(file_get_contents("php://input"));

if (!isset($data->phone)) {
    sendResponse(400, 'error', 'Phone number is required');
}

$phone = $data->phone;
$fcm_token = isset($data->fcm_token) ? $data->fcm_token : null;

// Check if user exists
$query = "SELECT id, name, phone FROM users WHERE phone = :phone LIMIT 1";
$stmt = $conn->prepare($query);
$stmt->bindParam(':phone', $phone);
$stmt->execute();

if ($stmt->rowCount() > 0) {
    // User exists, generate token and login
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Update FCM token if provided
    if ($fcm_token) {
        $updateQuery = "UPDATE users SET fcm_token = :fcm_token WHERE id = :id";
        $updateStmt = $conn->prepare($updateQuery);
        $updateStmt->bindParam(':fcm_token', $fcm_token);
        $updateStmt->bindParam(':id', $user['id']);
        $updateStmt->execute();
    }
    
    $token = generateJWT($user['id']);
    sendResponse(200, 'success', 'Login successful', ['user' => $user, 'token' => $token]);
} else {
    // User does not exist, tell app to route to Register screen
    sendResponse(404, 'error', 'User not found. Please register.', ['phone' => $phone]);
}
?>
