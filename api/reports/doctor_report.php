<?php
header('Content-Type: application/json');
require_once '../config/db.php';
require_once '../config/auth.php';

$user_id = authenticate();

$patient_id = isset($_GET['patient_id']) ? intval($_GET['patient_id']) : 0;
$date_to = isset($_GET['date_to']) ? $_GET['date_to'] : date('Y-m-d');
$date_from = isset($_GET['date_from']) ? $_GET['date_from'] : date('Y-m-d', strtotime('-30 days'));

if (!$patient_id) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'patient_id is required']);
    exit;
}

// Check if user has access to this patient
$stmt = $conn->prepare("SELECT id FROM family_members WHERE patient_id = ? AND user_id = ?");
$stmt->execute([$patient_id, $user_id]);
if (!$stmt->fetch()) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'message' => 'Access denied to this patient profile']);
    exit;
}

// Fetch Patient Info
$stmt = $conn->prepare("SELECT name, conditions, doctor_name, emergency_contact FROM patient_profiles WHERE id = ?");
$stmt->execute([$patient_id]);
$patient = $stmt->fetch(PDO::FETCH_ASSOC);

// Fetch Medicines and their stats
$stmt = $conn->prepare("
    SELECT id, name, dose, form, food_timing, is_critical, start_date, end_date, stock_count 
    FROM medicines 
    WHERE patient_id = ? AND deleted_at IS NULL
");
$stmt->execute([$patient_id]);
$medicines_list = $stmt->fetchAll(PDO::FETCH_ASSOC);

$medicines_data = [];
$total_taken_overall = 0;
$total_expected_overall = 0;

foreach ($medicines_list as $med) {
    $med_id = $med['id'];
    
    // Fetch Schedules
    $stmt_sched = $conn->prepare("SELECT label, time_slot, days_of_week FROM medicine_schedules WHERE medicine_id = ? AND is_active = 1");
    $stmt_sched->execute([$med_id]);
    $schedules = $stmt_sched->fetchAll(PDO::FETCH_ASSOC);
    
    // Fetch Adherence Stats for this medicine
    $stmt_stats = $conn->prepare("
        SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN status = 'taken' THEN 1 ELSE 0 END) as taken,
            SUM(CASE WHEN status = 'skipped' THEN 1 ELSE 0 END) as skipped,
            SUM(CASE WHEN status = 'snoozed' THEN 1 ELSE 0 END) as snoozed
        FROM reminder_logs 
        WHERE patient_id = ? 
        AND schedule_id IN (SELECT id FROM medicine_schedules WHERE medicine_id = ?)
        AND scheduled_datetime BETWEEN ? AND ?
    ");
    $stmt_stats->execute([$patient_id, $med_id, $date_from . ' 00:00:00', $date_to . ' 23:59:59']);
    $stats = $stmt_stats->fetch(PDO::FETCH_ASSOC);
    
    $total = intval($stats['total']);
    $taken = intval($stats['taken']);
    $skipped = intval($stats['skipped']);
    $snoozed = intval($stats['snoozed']);
    
    $adherence_percent = $total > 0 ? round(($taken / $total) * 100, 1) : 100.0;
    
    $total_taken_overall += $taken;
    $total_expected_overall += $total;
    
    $medicines_data[] = [
        "name" => $med['name'],
        "dose" => $med['dose'],
        "form" => $med['form'],
        "food_timing" => $med['food_timing'],
        "is_critical" => (bool)$med['is_critical'],
        "start_date" => $med['start_date'],
        "end_date" => $med['end_date'],
        "stock_count" => intval($med['stock_count']),
        "schedules" => $schedules,
        "adherence" => [
            "total_doses" => $total,
            "taken" => $taken,
            "skipped" => $skipped,
            "snoozed" => $snoozed,
            "adherence_percent" => $adherence_percent
        ]
    ];
}

$overall_adherence_percent = $total_expected_overall > 0 ? round(($total_taken_overall / $total_expected_overall) * 100, 1) : 100.0;

echo json_encode([
    "patient" => $patient,
    "medicines" => $medicines_data,
    "overall_adherence_percent" => $overall_adherence_percent,
    "report_generated_at" => date('Y-m-d H:i:s'),
    "date_range" => ["from" => $date_from, "to" => $date_to]
]);
