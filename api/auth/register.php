<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: POST");

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->phone) || !isset($data->name) || !isset($data->firebase_token)) {
    sendResponse(400, 'error', 'Name, Phone, and firebase_token are required');
}

$phone = $data->phone;
$name = $data->name;
$firebase_token = $data->firebase_token;
$fcm_token = isset($data->fcm_token) ? $data->fcm_token : null;

// --- FIREBASE ID TOKEN VERIFICATION ---
$verifyUrl = "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=" . FIREBASE_WEB_API_KEY;
$payload = json_encode(["idToken" => $firebase_token]);

$ch = curl_init($verifyUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($httpCode !== 200) {
    sendResponse(401, 'error', 'Firebase token verification failed');
}

$verificationData = json_decode($response);
if (!isset($verificationData->users[0]->phoneNumber)) {
    sendResponse(401, 'error', 'Invalid Firebase token');
}

// Ensure the phone number in the token matches the requested phone
$tokenPhone = str_replace('+', '', $verificationData->users[0]->phoneNumber);
if ($tokenPhone !== str_replace('+', '', $phone)) {
    sendResponse(401, 'error', 'Phone number mismatch');
}
// --- END VERIFICATION ---

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
