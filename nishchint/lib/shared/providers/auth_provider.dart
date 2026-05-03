import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/constants/api_constants.dart';
import '../../data/api_service.dart';
import '../../data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkExistingAuth() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    
    if (token != null) {
      _isAuthenticated = true;
      _setupFCM();
      // Ideally ping a /me endpoint here to get latest user details
      // For now, assume authenticated.
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> verifyOtp(String phone, String? firebaseToken) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConstants.verifyOtp, {
        'phone': phone,
        'firebase_token': firebaseToken,
        'fcm_token': await FirebaseMessaging.instance.getToken()
      });

      if (response['status'] == 'success') {
        _currentUser = UserModel.fromJson(response['data']['user']);
        await _apiService.saveToken(response['data']['token']);
        _isAuthenticated = true;
        _setupFCM();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // If 404, the user needs to register instead.
      throw e;
    }
  }

  Future<void> _setupFCM() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _apiService.post('${ApiConstants.baseUrl}/auth/update_fcm.php', {
          'fcm_token': token
        });
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await _apiService.post('${ApiConstants.baseUrl}/auth/update_fcm.php', {
          'fcm_token': newToken
        });
      });
    } catch (e) {
      debugPrint("FCM Setup error: $e");
    }
  }

  Future<void> logout() async {
    await _apiService.clearAuth();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
