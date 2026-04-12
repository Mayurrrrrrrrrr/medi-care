<?php
// Set IST timezone globally
date_default_timezone_set('Asia/Kolkata');

// Gracefully handle ALL uncaught exceptions by outputting JSON instead of blank crashing
set_exception_handler(function ($e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Server Error: " . $e->getMessage()]);
    exit();
});

define('DB_HOST', 'localhost');
define('DB_NAME', 'medicare_family');
define('DB_USER', 'root');
define('DB_PASS', 'asjhb5465%&55fss');

try {
    $conn = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8", DB_USER, DB_PASS);
    // Set PDO to trigger exceptions
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    // Ensure IST is set at database connection level
    $conn->exec("SET time_zone = '+05:30'");
} catch(PDOException $exception) {
    http_response_code(500);
    echo json_encode(array("status" => "error", "message" => "Database Connection error: " . $exception->getMessage()));
    exit();
}
?>
