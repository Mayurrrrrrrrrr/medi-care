<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';
require_once '../helpers/upload.php';

header("Access-Control-Allow-Methods: POST");
$user_id = authenticate();

if (!isset($_POST['schedule_id']) || !isset($_FILES['audio_file'])) {
    sendResponse(400, 'error', 'Schedule ID and audio_file are required');
}

$schedule_id = $_POST['schedule_id'];
$message_text = $_POST['message_text'] ?? null;

// Validate ownership
$checkQuery = "SELECT s.id FROM medicine_schedules s
               JOIN medicines m ON s.medicine_id = m.id
               JOIN patient_profiles p ON m.patient_id = p.id
               LEFT JOIN family_members f ON p.id = f.patient_id 
               WHERE s.id = :sid AND (p.created_by_user_id = :uid OR f.user_id = :uid)";
$checkStmt = $conn->prepare($checkQuery);
$checkStmt->execute([':sid' => $schedule_id, ':uid' => $user_id]);

if ($checkStmt->rowCount() == 0) {
    sendResponse(403, 'error', 'Unauthorized');
}

$target_dir = __DIR__ . '/../../uploads/voice/';
$custom_filename = 'voice_' . $schedule_id . '_' . time() . '.m4a';

$uploadResult = handleUpload($_FILES['audio_file'], $target_dir, ['m4a', 'mp3', 'wav', 'aac', 'mp4'], $custom_filename);

if ($uploadResult['success']) {
    // Relative URL for serving
    $file_url = '/uploads/voice/' . $uploadResult['filename'];
    $filepath = $uploadResult['path'];

    $checkVoice = $conn->prepare("SELECT id FROM voice_reminders WHERE schedule_id = :sid");
    $checkVoice->execute([':sid' => $schedule_id]);
    
    if ($checkVoice->rowCount() > 0) {
        $updateQuery = "UPDATE voice_reminders SET file_path = :path, file_url = :url, message_text = :msg, recorded_by_user_id = :uid WHERE schedule_id = :sid";
        $stmt = $conn->prepare($updateQuery);
        $stmt->execute([
            ':path' => $filepath,
            ':url' => $file_url,
            ':msg' => $message_text,
            ':uid' => $user_id,
            ':sid' => $schedule_id
        ]);
        $voice_id = $checkVoice->fetchColumn();
    } else {
        $insertQuery = "INSERT INTO voice_reminders (schedule_id, recorded_by_user_id, file_path, file_url, message_text) VALUES (:sid, :uid, :path, :url, :msg)";
        $stmt = $conn->prepare($insertQuery);
        $stmt->execute([
            ':sid' => $schedule_id,
            ':uid' => $user_id,
            ':path' => $filepath,
            ':url' => $file_url,
            ':msg' => $message_text
        ]);
        $voice_id = $conn->lastInsertId();
    }
    
    sendResponse(200, 'success', 'Voice note uploaded', [
        'id' => $voice_id,
        'file_url' => $file_url,
        'message_text' => $message_text
    ]);
} else {
    sendResponse(500, 'error', $uploadResult['message']);
}
?>
