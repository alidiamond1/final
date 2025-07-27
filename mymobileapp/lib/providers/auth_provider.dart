import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  Key _profileImageKey = UniqueKey();
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Key get profileImageKey => _profileImageKey;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (isLoggedIn) {
        _user = await AuthService.getUser();
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
        _user = null;
      }
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await AuthService.login(username, password);
      _user = data['user'];
      _isAuthenticated = true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthService.register(name, username, email, password);
      // Login after successful registration
      await login(username, password);
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _user = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.logout();
      _isAuthenticated = false;
      _user = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> updateProfile(String name, String email, String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await AuthService.updateProfile(name, email, username);
      _user = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthService.changePassword(oldPassword, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProfileImage(File imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    bool success = false;
    try {
      final updatedUser = await AuthService.uploadProfileImage(imageFile);
      _user = updatedUser;
      _profileImageKey = UniqueKey(); // Update the key to force a rebuild
      success = true;
    } catch (e) {
      _error = e.toString();
      success = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }
}