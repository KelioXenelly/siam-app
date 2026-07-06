import 'package:flutter/material.dart';
import 'package:siam_mobile/auth/models/user_model.dart';
import 'package:siam_mobile/auth/services/auth_service.dart';
import 'package:siam_mobile/core/storage_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  /// Fetch user from API and update state
  Future<void> fetchUser() async {
    _isLoading = true;
    // Don't call notifyListeners here if we don't want to flash loading states
    // but usually it's fine.
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token != null) {
        _user = await _authService.getMe();
      } else {
        _user = null;
      }
    } catch (e) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Manually update the user (e.g. after login or profile update)
  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  /// Clear the user state (e.g. after logout)
  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
