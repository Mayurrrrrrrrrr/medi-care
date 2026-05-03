<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: POST");

// We receive the FCM token and the verified phone number from Firebase Auth.
$data = json_decode(file_get_contents("php://input"));

if (!isset($data->phone) || !isset($data->firebase_token)) {
    sendResponse(400, 'error', 'Phone number and firebase_token are required');
}

$phone = $data->phone;
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
