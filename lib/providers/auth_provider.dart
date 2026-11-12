import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  // Privacy Vault & Quick Access PIN State
  bool _isPrivacyMasked = false;
  String? _vaultPin;
  bool _isDemoUser = false;
  bool _isBiometricEnabled = true;
  bool _isAppUnlocked = false;

  UserModel? get user => _user;
  UserModel? get currentUser => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPrivacyMasked => _isPrivacyMasked;
  bool get hasPin => _vaultPin != null && _vaultPin!.isNotEmpty;
  bool get hasPrivacyPin => hasPin;
  String? get vaultPin => _vaultPin;
  bool get isDemoUser => _isDemoUser;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isAppUnlocked => _isAppUnlocked;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _vaultPin = prefs.getString('vault_pin');
    // Default to Privacy Mask ON whenever app launches fresh
    _isPrivacyMasked = true;
    _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? true;

    final userId = prefs.getString('user_id');
    final userName = prefs.getString('user_name');
    final userEmail = prefs.getString('user_email');

    if (userId != null && userName != null && userEmail != null) {
      _user = UserModel(id: userId, name: userName, email: userEmail);
    }

    if (_token != null) {
      await fetchCurrentUser();
    }
    notifyListeners();
  }

  void unlockApp() {
    _isAppUnlocked = true;
    notifyListeners();
  }

  void lockApp() {
    _isAppUnlocked = false;
    notifyListeners();
  }

  bool verifyPin(String pin) {
    if (_vaultPin == null || _vaultPin!.isEmpty) {
      // If no PIN set yet, accept default or allow pass
      return true;
    }
    return _vaultPin == pin;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _isBiometricEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
    notifyListeners();
  }

  // Toggle Privacy Eye (Mask / Unmask balance)
  void togglePrivacyMask({String? pin}) {
    if (_isPrivacyMasked) {
      // Unmasking
      if (hasPin && pin != null) {
        if (pin != _vaultPin) {
          _errorMessage = 'Incorrect PIN';
          notifyListeners();
          return;
        }
      }
      _isPrivacyMasked = false;
    } else {
      _isPrivacyMasked = true;
    }
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('privacy_masked', _isPrivacyMasked);
    });
    notifyListeners();
  }

  // Set 4-Digit Privacy PIN
  Future<void> setVaultPin(String pin) async {
    _vaultPin = pin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vault_pin', pin);
    notifyListeners();
  }

  Future<void> setPrivacyPin(String pin) async => setVaultPin(pin);

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _isDemoUser = false;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: {'email': email.trim(), 'password': password},
      );

      final data = response.data;
      if (data != null && (data['token'] != null || data['data']?['token'] != null)) {
        _token = data['token'] ?? data['data']['token'];
        final userData = data['user'] ?? data['data']?['user'] ?? data;
        _user = UserModel.fromJson(userData);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_id', _user!.id);
        await prefs.setString('user_name', _user!.name);
        await prefs.setString('user_email', _user!.email);

        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = data['message'] ?? data['error'] ?? 'Login failed';
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? e.response?.data?['error'] ?? e.message ?? 'Connection error';
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Register
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _isDemoUser = false;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.register,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data;
      if (data != null && (data['token'] != null || data['data']?['token'] != null)) {
        _token = data['token'] ?? data['data']['token'];
        final userData = data['user'] ?? data['data']?['user'] ?? data;
        _user = UserModel.fromJson(userData);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_id', _user!.id);
        await prefs.setString('user_name', _user!.name);
        await prefs.setString('user_email', _user!.email);

        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = data['message'] ?? data['error'] ?? 'Registration failed';
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? e.response?.data?['error'] ?? e.message ?? 'Registration failed';
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Demo Login (One-click bypass for instant offline testing & viva demo)
  Future<void> demoLogin() async {
    _isDemoUser = true;
    _token = 'demo_jwt_token_raqmify_2026';
    _vaultPin ??= '1234';
    _isPrivacyMasked = true;
    _user = UserModel(
      id: 'demo_user_101',
      name: 'Rana Abdullah',
      email: 'rana.abdullah@hostel.edu.pk',
      easypaisa: '03001234567',
      jazzcash: '03001234567',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setString('user_id', _user!.id);
    await prefs.setString('user_name', _user!.name);
    await prefs.setString('user_email', _user!.email);
    notifyListeners();
  }

  // Fetch Current User
  Future<void> fetchCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiConstants.me);
      if (response.data != null) {
        final userData = response.data['user'] ?? response.data;
        _user = UserModel.fromJson(userData);
        notifyListeners();
      }
    } catch (_) {}
  }

  // Logout
  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    notifyListeners();
  }
}
