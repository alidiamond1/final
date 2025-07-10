import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Replace with your actual API URL. For Android emulator, use 10.0.2.2
  //  static const String baseUrl = 'http://10.202.244.22:3000/api/users';
  static const String serverBaseUrl = 'http://10.202.244.22:3000';
  static const String baseUrl = '$serverBaseUrl/api/users';

  // Store auth token
  static Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Store user data
  static Future<void> storeUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  // Get stored user
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      return jsonDecode(userStr);
    }
    return null;
  }

  // Clear stored user data on logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user');
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Register a new user
  static Future<Map<String, dynamic>> register(String name, String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to register');
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await storeToken(data['token']);
      await storeUser(data['user']);
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to login');
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile(String name, String email) async {
    final token = await getToken();
    final user = await getUser();
    if (token == null || user == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/${user['_id']}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await storeUser(data['user']);
      return data['user'];
    } else {
      throw Exception(data['error'] ?? 'Failed to update profile');
    }
  }

  // Change user password
  static Future<void> changePassword(String oldPassword, String newPassword) async {
    final token = await getToken();
    final user = await getUser();
    if (token == null || user == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/${user['_id']}/password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to change password');
    }
  }

  // Upload profile image
  static Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    final token = await getToken();
    final user = await getUser();
    if (token == null || user == null) {
      throw Exception('Not authenticated');
    }

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/${user['_id']}/profile-image'));
    request.headers['Authorization'] = 'Bearer $token';
    final mimeTypeData = lookupMimeType(imageFile.path, headerBytes: [0xFF, 0xD8])?.split('/');
    
    request.files.add(
      await http.MultipartFile.fromPath(
        'profileImage',
        imageFile.path,
        contentType: mimeTypeData != null ? MediaType(mimeTypeData[0], mimeTypeData[1]) : null,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);

    if (response.statusCode == 200) {
      final updatedUser = data['user'];
      if (updatedUser is Map<String, dynamic>) {
        await storeUser(updatedUser);
        return updatedUser;
      } else {
        throw Exception('Server returned success, but user data was invalid.');
      }
    } else {
      throw Exception(data['message'] ?? data['error'] ?? 'Failed to upload image');
    }
  }
}