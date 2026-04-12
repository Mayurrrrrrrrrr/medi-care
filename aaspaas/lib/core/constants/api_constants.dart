class ApiConstants {
  // Live Domain deployed by user
  static const String baseUrl = 'https://aaspaas.yuktaa.com/api';

  // Auth
  static const String verifyOtp = '$baseUrl/auth/verify-otp.php';
  static const String register = '$baseUrl/auth/register.php';

  // Patients
  static const String patientsIndex = '$baseUrl/patients/index.php';
  static const String patientsCreate = '$baseUrl/patients/create.php';
  static String patientDetail(int id) => '$baseUrl/patients/detail.php?id=$id';
  static String patientUpdate(int id) => '$baseUrl/patients/update.php?id=$id';

  // Medicines
  static String medicineIndex(int patientId) => '$baseUrl/medicines/index.php?patient_id=$patientId';
  static const String medicineAdd = '$baseUrl/medicines/add.php';
  static String medicineUpdate(int id) => '$baseUrl/medicines/update.php?id=$id';
  static String medicineDelete(int id) => '$baseUrl/medicines/delete.php?id=$id';
  static const String medicineDecrementStock = '$baseUrl/medicines/decrement_stock.php';

  // Schedules
  static String scheduleIndex(int medicineId) => '$baseUrl/schedules/index.php?medicine_id=$medicineId';
  static const String scheduleAdd = '$baseUrl/schedules/add.php';
  static String scheduleUpdate(int id) => '$baseUrl/schedules/update.php?id=$id';
  static String scheduleDelete(int id) => '$baseUrl/schedules/delete.php?id=$id';

  // Voice
  static const String voiceUpload = '$baseUrl/voice/upload.php';

  // Logs
  static const String logUpdate = '$baseUrl/logs/update.php';
  static String logsToday(int patientId) => '$baseUrl/logs/today.php?patient_id=$patientId';
  static String logsHistory(int patientId) => '$baseUrl/logs/history.php?patient_id=$patientId';
  static String checkMissed(int patientId) => '$baseUrl/logs/check_missed.php?patient_id=$patientId';

  // Family
  static const String familyNotifyTaken = '$baseUrl/family/notify_taken.php';
  static String familyNotifications(int patientId) => '$baseUrl/family/notifications.php?patient_id=$patientId';
}
