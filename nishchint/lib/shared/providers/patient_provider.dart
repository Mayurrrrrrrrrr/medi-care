import 'package:flutter/material.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/adherence_log_model.dart';
import '../../data/models/medicine_model.dart';
import '../../services/voice_cache_service.dart';
import '../../services/alarm_service.dart';
import '../../data/api_service.dart';
import '../../core/constants/api_constants.dart';

class PatientProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<PatientModel> _patients = [];
  List<MedicineModel> _todayMedicines = [];
  List<AdherenceLogModel> _adherenceLogs = [];
  PatientModel? _selectedPatient;
  
  bool _isLoading = false;

  List<PatientModel> get patients => _patients;
  List<MedicineModel> get todayMedicines => _todayMedicines;
  List<AdherenceLogModel> get adherenceLogs => _adherenceLogs;
  PatientModel? get selectedPatient => _selectedPatient;
  bool get isLoading => _isLoading;

  Future<void> fetchPatients() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get(ApiConstants.patientsIndex);
      if (response['status'] == 'success') {
        _patients = (response['data'] as List)
            .map((item) => PatientModel.fromJson(item))
            .toList();
            
        if (_patients.isNotEmpty && _selectedPatient == null) {
          _selectedPatient = _patients.first;
          await fetchTodayMedicines(_selectedPatient!.id);
          await fetchTodayAdherence(_selectedPatient!.id);
        }
      }
    } catch (e) {
      debugPrint("Error fetching patients: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTodayMedicines(int patientId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get(ApiConstants.medicineIndex(patientId));
      if (response['status'] == 'success') {
        _todayMedicines = (response['data'] as List)
            .map((item) => MedicineModel.fromJson(item))
            .toList();
            
        // ----- BLAZING FAST BACKGROUND ALARM SYNC -----
        for (var med in _todayMedicines) {
           if (med.timeSlot != null && med.scheduleId != null) {
              // Only schedule if the medicine is active today
              final today = DateTime.now().weekday.toString();
              if (med.daysOfWeek != null && med.daysOfWeek != 'Everyday' && !med.daysOfWeek!.split(',').contains(today)) {
                continue;
              }

              // 1. Aggressively cache voice note invisibly
              String? localVoicePath;
              if (med.voiceNoteUrl != null && med.voiceNoteUrl!.isNotEmpty) {
                 localVoicePath = await VoiceCacheService.downloadAndCache(med.voiceNoteUrl!);
              }
              
              // 2. Parse HH:MM:00 into specific CPU cycles
              final parts = med.timeSlot!.split(':');
              final now = DateTime.now();
              var alarmTime = DateTime(
                 now.year, 
                 now.month, 
                 now.day, 
                 int.parse(parts[0]), 
                 int.parse(parts[1])
              );
              
              // Only load it into the Android Alarm Manager if it hasn't passed!
              if (alarmTime.isAfter(now)) {
                  await AlarmService.scheduleMedicineAlarm(
                    med.scheduleId!, 
                    patientId,
                    med.id,
                    alarmTime, 
                    med.name, 
                    localVoicePath
                  );
              }
           }
        }
      }
    } catch (e) {
      debugPrint("Error fetching medicines: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTodayAdherence(int patientId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get(ApiConstants.logsToday(patientId));
      if (response['status'] == 'success') {
        _adherenceLogs = (response['data'] as List)
            .map((item) => AdherenceLogModel.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching adherence logs: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectPatient(PatientModel patient) {
    _selectedPatient = patient;
    fetchTodayMedicines(patient.id);
    fetchTodayAdherence(patient.id);
  }
}
