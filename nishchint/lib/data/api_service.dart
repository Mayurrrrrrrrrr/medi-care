import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import 'models/voice_reminder_model.dart';
import 'models/care_note_model.dart';

class ApiService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  Future<dynamic> get(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> post(String url, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(data),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> put(String url, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(data),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> delete(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse(url), headers: headers);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Need to handle token expiry globally
      throw Exception('Unauthorized');
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'An error occurred');
    }
  }

  Future<dynamic> multipartPost(String url, String filePath, Map<String, String> fields) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      var request = http.MultipartRequest('POST', Uri.parse(url));
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.fields.addAll(fields);
      // Compatibility with current usage (using 'voice_file' or 'audio_file' based on need)
      final fieldName = fields.containsKey('schedule_id') ? 'audio_file' : 'voice_file';
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _processResponse(response);
    } catch (e) {
      throw Exception('Multipart upload error: $e');
    }
  }

  Future<VoiceReminder> uploadVoiceReminder(int scheduleId, String filePath, String messageText) async {
    final response = await multipartPost(
      ApiConstants.voiceUpload,
      filePath,
      {
        'schedule_id': scheduleId.toString(),
        'message_text': messageText,
      },
    );
    
    if (response['status'] == 'success') {
      return VoiceReminder.fromJson(response['data']);
    } else {
      throw Exception(response['message'] ?? 'Upload failed');
    }
  }

  Future<List<CareNote>> getCareNotes(int medicineId) async {
    final response = await get(ApiConstants.notesIndex(medicineId));
    if (response['status'] == 'success') {
      return (response['data'] as List).map((n) => CareNote.fromJson(n)).toList();
    }
    return [];
  }

  Future<CareNote> addCareNote(int medicineId, String noteText) async {
    final response = await post(ApiConstants.notesAdd, {
      'medicine_id': medicineId,
      'note_text': noteText,
    });
    if (response['status'] == 'success') {
      return CareNote.fromJson(response['data']);
    } else {
      throw Exception(response['message'] ?? 'Failed to add note');
    }
  }

  // Auth Helpers
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}
