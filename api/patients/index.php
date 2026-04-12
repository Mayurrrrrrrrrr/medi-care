<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';

header("Access-Control-Allow-Methods: GET");
$user_id = authenticate(); // Validate token

// Get patients where user is the creator OR user is a family member
$query = "
    SELECT p.*, 
        CASE WHEN p.created_by_user_id = :user_id THEN 'primary' ELSE f.role END as user_role
    FROM patient_profiles p
    LEFT JOIN family_members f ON p.id = f.patient_id AND f.user_id = :user_id
    WHERE p.created_by_user_id = :user_id OR f.user_id = :user_id
    GROUP BY p.id
    ORDER BY p.created_at DESC
";

$stmt = $conn->prepare($query);
$stmt->bindParam(':user_id', $user_id);
$stmt->execute();

$patients = $stmt->fetchAll(PDO::FETCH_ASSOC);

sendResponse(200, 'success', 'Patients retrieved successfully', $patients);
?>
