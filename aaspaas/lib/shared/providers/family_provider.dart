import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../data/api_service.dart';
import '../../data/models/family_member_model.dart';

class FamilyProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<FamilyMemberModel> _members = [];
  bool _isLoading = false;

  List<FamilyMemberModel> get members => _members;
  bool get isLoading => _isLoading;

  Future<void> fetchFamilyMembers(int patientId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/family/list.php?patient_id=$patientId');
      if (response['status'] == 'success') {
        _members = (response['data'] as List)
            .map((item) => FamilyMemberModel.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching family: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> inviteMember(int patientId, String phone, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('${ApiConstants.baseUrl}/family/invite.php', {
        'patient_id': patientId,
        'phone': phone,
        'role': role,
      });
      
      if (response['status'] == 'success') {
        await fetchFamilyMembers(patientId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error inviting member: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
