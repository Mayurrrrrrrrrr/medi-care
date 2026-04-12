<?php
require_once '../config/db.php';
require_once '../config/auth.php';
require_once '../helpers/response.php';
require_once '../helpers/upload.php';

header("Access-Control-Allow-Methods: POST");
$user_id = authenticate();

if (!isset($_POST['schedule_id'])) {
    sendResponse(400, 'error', 'Schedule ID is required');
}

$schedule_id = $_POST['schedule_id'];
$message_text = isset($_POST['message_text']) ? $_POST['message_text'] : null;

// Allow audio uploads: m4a, mp3, mp4, aac, wav
$upload_result = handleUpload($_FILES['voice_file'], '../../uploads/voice/', ['m4a', 'mp3', 'mp4', 'aac', 'wav']);

if (!$upload_result['success']) {
    sendResponse(400, 'error', $upload_result['message']);
}

$file_path = $upload_result['path'];
// Construct public URL
$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
$host = $_SERVER['HTTP_HOST'];
// Approximate base URL path for the upload. Assumes api/voice/upload.php location
$base_url = $protocol . "://" . $host . dirname(dirname(dirname($_SERVER['SCRIPT_NAME']))) . "/uploads/voice/";
$file_url = $base_url . $upload_result['filename'];

// Upsert logic: unique key on schedule_id
$query = "
    INSERT INTO voice_reminders (schedule_id, recorded_by_user_id, file_path, file_url, message_text) 
    VALUES (:sid, :uid, :fpath, :furl, :msg)
    ON DUPLICATE KEY UPDATE 
    recorded_by_user_id = :uid, file_path = :fpath, file_url = :furl, message_text = :msg
";

$stmt = $conn->prepare($query);
$stmt->execute([
    ':sid' => $schedule_id,
    ':uid' => $user_id,
    ':fpath' => $file_path,
    ':furl' => $file_url,
    ':msg' => $message_text
]);

sendResponse(200, 'success', 'Voice reminder saved successfully', ['url' => $file_url]);
?>
