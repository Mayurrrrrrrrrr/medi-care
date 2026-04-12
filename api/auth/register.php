<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: POST");

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->phone) || !isset($data->name)) {
    sendResponse(400, 'error', 'Name and Phone number are required');
}

$phone = $data->phone;
$name = $data->name;
$fcm_token = isset($data->fcm_token) ? $data->fcm_token : null;

// Check if phone already exists
$checkQuery = "SELECT id FROM users WHERE phone = :phone";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->bindParam(':phone', $phone);
$checkStmt->execute();

if ($checkStmt->rowCount() > 0) {
    sendResponse(409, 'error', 'User already exists with this phone number');
}

// Register user
$insertQuery = "INSERT INTO users (name, phone, fcm_token) VALUES (:name, :phone, :fcm_token)";
$insertStmt = $conn->prepare($insertQuery);
$insertStmt->bindParam(':name', $name);
$insertStmt->bindParam(':phone', $phone);
$insertStmt->bindParam(':fcm_token', $fcm_token);

if ($insertStmt->execute()) {
    $user_id = $conn->lastInsertId();
    $token = generateJWT($user_id);
    
    $user = [
        'id' => $user_id,
        'name' => $name,
        'phone' => $phone
    ];
    
    sendResponse(201, 'success', 'User registered successfully', ['user' => $user, 'token' => $token]);
} else {
    sendResponse(500, 'error', 'Failed to register user');
}
?>
