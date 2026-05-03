<?php
// Nishchint - Simple stateless JWT authentication configuration
define('JWT_SECRET', 'Nishchint_Super_Secret_Key_2026!');

// Generate a token valid for 30 days
function generateJWT($user_id) {
    $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
    $payload = json_encode(['user_id' => $user_id, 'exp' => time() + (86400 * 30)]);
    
    $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
    $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));
    $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, JWT_SECRET, true);
    $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
    
    return $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
}

// Authenticate via Bearer Token header
function authenticate() {
    // Check headers including non-Apache servers
    if (function_exists('getallheaders')) {
        $headers = getallheaders();
    } else {
        $headers = [];
        foreach ($_SERVER as $name => $value) {
            if (substr($name, 0, 5) == 'HTTP_') {
                $headers[str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($name, 5)))))] = $value;
            }
        }
    }
    
    if (!isset($headers['Authorization']) && !isset($headers['authorization'])) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Authorization header missing']);
        exit;
    }
    
    $authHeader = isset($headers['Authorization']) ? $headers['Authorization'] : $headers['authorization'];
    $tokenParts = explode(" ", $authHeader);
    
    if(count($tokenParts) != 2 || strcasecmp($tokenParts[0], 'Bearer') !== 0) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Invalid Bearer token format']);
        exit;
    }
    
    $token = $tokenParts[1];
    $parts = explode('.', $token);
    if (count($parts) != 3) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Invalid token structure']);
        exit;
    }
    
    $signature = hash_hmac('sha256', $parts[0] . "." . $parts[1], JWT_SECRET, true);
    $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
    
    if (hash_equals($base64UrlSignature, $parts[2])) {
        $payload = json_decode(base64_decode(str_replace(['-', '_'], ['+', '/'], $parts[1])));
        if (isset($payload->exp) && $payload->exp < time()) {
            http_response_code(401);
            echo json_encode(['status' => 'error', 'message' => 'Token expired']);
            exit;
        }
        return $payload->user_id;
    } else {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Token signature verification failed']);
        exit;
    }
}
?>
