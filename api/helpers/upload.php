<?php
// Handle local file uploads (voice notes, pill photos)
function handleUpload($file, $target_dir, $allowed_types, $custom_filename = null) {
    if (!isset($file) || !is_array($file) || $file['error'] != UPLOAD_ERR_OK) {
        $errCode = is_array($file) ? ($file['error'] ?? 'Unknown') : 'Missing File Stream';
        return ['success' => false, 'message' => 'Upload error or no file provided. Code: ' . $errCode];
    }

    $file_ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    
    if (!in_array($file_ext, $allowed_types)) {
        return ['success' => false, 'message' => 'Invalid file extension. Allowed: ' . implode(', ', $allowed_types)];
    }

    // Auto-create directory structure if it doesn't exist
    if (!file_exists($target_dir)) {
        if (!mkdir($target_dir, 0777, true)) {
             return ['success' => false, 'message' => 'Failed to create upload directory'];
        }
    }
    
    // Generate unique file name
    $new_filename = $custom_filename ? $custom_filename : (uniqid('nishchint_', true) . '.' . $file_ext);
    $target_file = rtrim($target_dir, '/') . '/' . $new_filename;
    
    if (move_uploaded_file($file['tmp_name'], $target_file)) {
        return ['success' => true, 'filename' => $new_filename, 'path' => $target_file];
    } else {
         return ['success' => false, 'message' => 'Failed to move uploaded file to target directory'];
    }
}
?>
