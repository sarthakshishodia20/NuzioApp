import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';
import '../../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _token != null;

  final ApiClient _api = ApiClient();

  /// Restore session from SharedPreferences on app start
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userId = prefs.getString('user_id');

    if (_token != null && userId != null) {
      try {
        final res = await _api.get('/auth/me');
        _user = UserModel.fromJson(res.data);
      } catch (_) {
        // Token expired — clear session
        await _clearSession();
      }
    }
    notifyListeners();
  }

  /// Email-based JWT login — sends name + email to backend, gets JWT
  Future<bool> loginWithEmail({
    required String email,
    String? name,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.post('/auth/login', data: {
        'name': name,
        'email': email,
      });

      _token = res.data['token'];
      _user = UserModel.fromJson(res.data['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('user_id', _user!.id);
      await prefs.setString('user_name', _user!.name);
      await prefs.setString('user_email', _user!.email);

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          _error = 'Server is waking up (Render free tier). Please try again in a few moments.';
        } else if (e.response?.data is Map && e.response!.data['error'] != null) {
          _error = e.response!.data['error'].toString();
        } else {
          _error = 'Login failed. Please check your connection.';
        }
      } else {
        _error = 'Login failed. Please check your connection.';
      }
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mock Google login — sends name + email to backend, gets JWT
  Future<bool> loginWithGoogle({
    required String name,
    required String email,
  }) async {
    return loginWithEmail(email: email, name: name);
  }

  /// Save onboarding preferences to backend
  Future<void> savePreferences(Map<String, dynamic> prefs) async {
    try {
      final res = await _api.put('/user/preferences', data: prefs);
      _user = UserModel.fromJson(res.data);
      notifyListeners();
    } catch (e) {
      debugPrint('Save preferences error: $e');
    }
  }

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
