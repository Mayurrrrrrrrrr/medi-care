import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
      request.files.add(await http.MultipartFile.fromPath('voice_file', filePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _processResponse(response);
    } catch (e) {
      throw Exception('Multipart upload error: $e');
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
