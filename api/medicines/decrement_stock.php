<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: POST");
$user_id = authenticate();

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->medicine_id)) {
    sendResponse(400, 'error', 'Medicine ID is required');
}

$medicine_id = $data->medicine_id;

// Verify auth
$checkQuery = "SELECT m.id, m.stock_count FROM medicines m
               JOIN patient_profiles p ON m.patient_id = p.id
               LEFT JOIN family_members f ON p.id = f.patient_id 
               WHERE m.id = :mid AND (p.created_by_user_id = :uid OR f.user_id = :uid)";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':mid' => $medicine_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized');
}

$medicine = $checkStmt->fetch(PDO::FETCH_ASSOC);
$currentStock = (int)$medicine['stock_count'];

if ($currentStock <= 0) {
    sendResponse(200, 'success', 'Stock already at zero', ['stock_count' => 0]);
}

$newStock = $currentStock - 1;
$query = "UPDATE medicines SET stock_count = :stock WHERE id = :id";
$stmt = $conn->prepare($query);
$stmt->execute([':stock' => $newStock, ':id' => $medicine_id]);

// Check if low stock alert needed
$alertQuery = "SELECT stock_alert_at, name, patient_id FROM medicines WHERE id = :id";
$alertStmt = $conn->prepare($alertQuery);
$alertStmt->execute([':id' => $medicine_id]);
$alertData = $alertStmt->fetch(PDO::FETCH_ASSOC);

$isLowStock = $newStock <= (int)$alertData['stock_alert_at'];

if ($isLowStock) {
    require_once '../config/fcm.php';
    
    $medicine_name = $alertData['name'];
    $patient_id = $alertData['patient_id'];
    
    // Find primary caregiver
    $caregiverQuery = "SELECT u.fcm_token FROM family_members f 
                      JOIN users u ON f.user_id = u.id 
                      WHERE f.patient_id = :pid AND f.role = 'primary'";
    $caregiverStmt = $conn->prepare($caregiverQuery);
    $caregiverStmt->execute([':pid' => $patient_id]);
    $caregiver = $caregiverStmt->fetch(PDO::FETCH_ASSOC);
    
    if ($caregiver && !empty($caregiver['fcm_token'])) {
        sendFCMNotification(
            $caregiver['fcm_token'],
            "Medicine Running Low 💊",
            "$medicine_name has only $newStock doses left. Please refill soon.",
            [
                "type" => "stock_alert",
                "medicine_id" => (string)$medicine_id
            ]
        );
    }
}

sendResponse(200, 'success', 'Stock decremented', [
    'stock_count' => $newStock,
    'is_low_stock' => $isLowStock
]);
?>
