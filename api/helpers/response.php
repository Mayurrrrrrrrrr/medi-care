<?php
// Global response handler to ensure consistent JSON formatting
function sendResponse($status_code, $status, $message, $data = null) {
    http_response_code($status_code);
    header('Content-Type: application/json; charset=utf-8');
    
    $response = [
        'status' => $status,
        'message' => $message
    ];
    
    if ($data !== null) {
        $response['data'] = $data;
    }
    
    echo json_encode($response);
    exit;
}
?>
