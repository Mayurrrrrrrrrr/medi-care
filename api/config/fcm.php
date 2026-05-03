<?php
// Nishchint - Firebase Push Notification Configuration (Modern HTTP v1 API)

// Generate an OAuth 2.0 token securely from the JSON file using Core PHP (No Composer needed!)
function getFCMv1Token() {
    $credentialsPath = __DIR__ . '/firebase_credentials.json';
    if (!file_exists($credentialsPath)) {
        return false;
    }

    $credentials = json_decode(file_get_contents($credentialsPath), true);
    
    $clientEmail = $credentials['client_email'];
    $privateKey = $credentials['private_key'];
    
    // Create JWT Header
    $header = json_encode(['alg' => 'RS256', 'typ' => 'JWT']);
    
    // Create JWT Payload matching Google's OAuth requirements
    $now = time();
    $payload = json_encode([
        'iss' => $clientEmail,
        'scope' => 'https://www.googleapis.com/auth/cloud-platform', // Required scope for Firebase HTTP v1
        'aud' => 'https://oauth2.googleapis.com/token',
        'exp' => $now + 3600,
        'iat' => $now
    ]);
    
    $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
    $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));
    
    // Sign the JWT with the RSA Private Key
    $signature = '';
    openssl_sign($base64UrlHeader . "." . $base64UrlPayload, $signature, $privateKey, OPENSSL_ALGO_SHA256);
    $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
    
    $jwt = $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
    
    // Exchange JWT for standard OAuth Access Token
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt
    ]));
    
    $response = curl_exec($ch);
    curl_close($ch);
    
    $data = json_decode($response, true);
    return isset($data['access_token']) ? $data['access_token'] : false;
}

// Send standard Push using V1 Protocol
function sendFCMNotification($token, $title, $body, $data = []) {
    $credentialsPath = __DIR__ . '/firebase_credentials.json';
    if (!file_exists($credentialsPath)) {
        return ['http_code' => 500, 'response' => 'Missing firebase_credentials.json configuration file.'];
    }
    
    $credentials = json_decode(file_get_contents($credentialsPath), true);
    $projectId = $credentials['project_id'];
    
    // Grab the live OAuth token dynamically
    $accessToken = getFCMv1Token();
    if (!$accessToken) {
        return ['http_code' => 500, 'response' => 'Failed to generate OAuth token from credentials.'];
    }

    $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

    $headers = [
        'Authorization: Bearer ' . $accessToken,
        'Content-Type: application/json'
    ];

    // Payload now correctly wrapped in 'message' parameter
    $fields = [
        'message' => [
            'token' => $token,
            'notification' => [
                'title' => $title,
                'body' => $body
            ],
            'data' => empty($data) ? new stdClass() : $data // Force object if empty to satisfy strict JSON requirements
        ]
    ];

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));
    
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return [
        'http_code' => $httpCode,
        'response' => json_decode($result, true)
    ];
}
?>
