import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/app_failure.dart';
import '../core/network/result.dart';
import '../core/services/secure_storage_service.dart';
import '../dev/demo_data.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _secureStorage = SecureStorageService();

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // Privacy Vault & PIN State
  bool _isPrivacyMasked = true;
  bool _hasPin = false;
  bool _isDemoUser = false;
  bool _isBiometricEnabled = true;
  bool _isAppUnlocked = false;

  // S3 Lockout state
  int _lockoutSeconds = 0;
  int _failedAttempts = 0;

  // Canonical Getters (Q6)
  UserModel? get currentUser => _currentUser;
  UserModel? get user => _currentUser; // Alias for backward compatibility
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get isPrivacyMasked => _isPrivacyMasked;
  bool get hasPin => _hasPin;
  bool get hasPrivacyPin => _hasPin; // Alias for backward compatibility
  bool get isDemoUser => kDebugMode && _isDemoUser;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isAppUnlocked => _isAppUnlocked;
  int get lockoutSeconds => _lockoutSeconds;
  int get failedAttempts => _failedAttempts;

  AuthProvider() {
    _apiClient.onSessionExpired = () {
      logout(expired: true);
    };
    init();
  }

  /// Explicit async initialization awaited by Splash Screen (S9)
  Future<void> init() async {
    try {
      // 1. One-time migration from SharedPreferences to Keystore (S2)
      await _secureStorage.performOneTimeMigration();

      // 2. Load auth token from Secure Storage (S2)
      _token = await _secureStorage.getAuthToken();
      _hasPin = await _secureStorage.hasPin();
      _lockoutSeconds = await _secureStorage.getRemainingLockoutSeconds();
      _failedAttempts = await _secureStorage.getFailedAttemptsCount();

      // Cache token in ApiClient interceptor
      _apiClient.setAuthToken(_token);

      // 3. Load non-sensitive preferences from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? true;
      _isPrivacyMasked = true; // Always default to masked on cold launch

      final userId = prefs.getString('user_id');
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');
      final easypaisa = prefs.getString('user_easypaisa');
      final jazzcash = prefs.getString('user_jazzcash');

      if (userId != null && userName != null && userEmail != null) {
        _currentUser = UserModel(
          id: userId,
          name: userName,
          email: userEmail,
          easypaisa: easypaisa,
          jazzcash: jazzcash,
        );
      }

      // 4. Validate session online if token exists
      if (_token != null && _token!.isNotEmpty) {
        await fetchCurrentUser();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthProvider.init] Error during initialization: $e');
      }
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  void unlockApp() {
    _isAppUnlocked = true;
    notifyListeners();
  }

  void lockApp() {
    _isAppUnlocked = false;
    notifyListeners();
  }

  /// Verify PIN with constant-time check & progressive lockout (S3)
  Future<PinVerifyResult> verifyPin(String pin) async {
    final result = await _secureStorage.verifyPin(pin);
    _lockoutSeconds = result.lockoutSeconds;
    _failedAttempts = 5 - result.attemptsRemaining;

    if (result.shouldLogout) {
      await logout(expired: true);
    }

    notifyListeners();
    return result;
  }

  Future<int> checkLockout() async {
    _lockoutSeconds = await _secureStorage.getRemainingLockoutSeconds();
    if (_lockoutSeconds <= 0) {
      _lockoutSeconds = 0;
    }
    notifyListeners();
    return _lockoutSeconds;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _isBiometricEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
    notifyListeners();
  }

  /// Toggle Privacy Eye (Mask / Unmask balance)
  Future<bool> togglePrivacyMask({String? pin, bool force = false}) async {
    if (_isPrivacyMasked) {
      // Unmasking requires valid PIN if PIN is set and not forced
      if (!force && _hasPin && pin != null) {
        final result = await verifyPin(pin);
        if (!result.isSuccess) {
          _errorMessage = result.errorMessage ?? 'Incorrect PIN';
          notifyListeners();
          return false;
        }
      }
      _isPrivacyMasked = false;
    } else {
      _isPrivacyMasked = true;
    }
    notifyListeners();
    return true;
  }

  /// Set 4-Digit Security PIN (S2, S3)
  Future<void> setVaultPin(String pin) async {
    await _secureStorage.savePin(pin);
    _hasPin = true;
    _lockoutSeconds = 0;
    _failedAttempts = 0;
    notifyListeners();
  }

  Future<void> setPrivacyPin(String pin) async => setVaultPin(pin);

  // Login
  Future<Result<UserModel>> login(String email, String password) async {
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
        _currentUser = UserModel.fromJson(userData);

        // Store token in Secure Storage (Android Keystore)
        await _secureStorage.saveAuthToken(_token!);
        _apiClient.setAuthToken(_token);

        // Store non-sensitive metadata in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', _currentUser!.id);
        await prefs.setString('user_name', _currentUser!.name);
        await prefs.setString('user_email', _currentUser!.email);
        if (_currentUser!.easypaisa != null) {
          await prefs.setString('user_easypaisa', _currentUser!.easypaisa!);
        }
        if (_currentUser!.jazzcash != null) {
          await prefs.setString('user_jazzcash', _currentUser!.jazzcash!);
        }

        _hasPin = await _secureStorage.hasPin();
        _isLoading = false;
        notifyListeners();
        return Success(_currentUser!);
      }

      final failure = AppFailure(message: data?['message'] ?? 'Login failed');
      _errorMessage = failure.message;
      _isLoading = false;
      notifyListeners();
      return Failure(failure);
    } catch (e) {
      final failure = AppFailure.fromException(e);
      _errorMessage = failure.message;
      _isLoading = false;
      notifyListeners();
      return Failure(failure);
    }
  }

  // Register
  Future<Result<UserModel>> register(String name, String email, String password) async {
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
        _currentUser = UserModel.fromJson(userData);

        await _secureStorage.saveAuthToken(_token!);
        _apiClient.setAuthToken(_token);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', _currentUser!.id);
        await prefs.setString('user_name', _currentUser!.name);
        await prefs.setString('user_email', _currentUser!.email);

        _hasPin = await _secureStorage.hasPin();
        _isLoading = false;
        notifyListeners();
        return Success(_currentUser!);
      }

      final failure = AppFailure(message: data?['message'] ?? 'Registration failed');
      _errorMessage = failure.message;
      _isLoading = false;
      notifyListeners();
      return Failure(failure);
    } catch (e) {
      final failure = AppFailure.fromException(e);
      _errorMessage = failure.message;
      _isLoading = false;
      notifyListeners();
      return Failure(failure);
    }
  }

  // Demo Login: Available strictly in kDebugMode (S1)
  Future<void> demoLogin() async {
    if (!kDebugMode) {
      throw UnsupportedError('Demo mode is disabled in production builds.');
    }

    _isDemoUser = true;
    _token = 'demo_jwt_token_raqmify_2026';
    _isPrivacyMasked = true;
    _currentUser = DemoData.demoUser;

    // Do NOT set a hardcoded default PIN '1234'
    _hasPin = await _secureStorage.hasPin();
    _apiClient.setAuthToken(_token);

    notifyListeners();
  }

  // Fetch Current User: Distinguish network error vs 401 session expiry (S9)
  Future<void> fetchCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiConstants.me);
      if (response.data != null) {
        final userData = response.data['user'] ?? response.data;
        _currentUser = UserModel.fromJson(userData);
        notifyListeners();
      }
    } catch (e) {
      final failure = AppFailure.fromException(e);
      if (failure.statusCode == 401) {
        // Expired session: log out cleanly
        await logout(expired: true);
      } else {
        // Network connection error: preserve local session in offline mode
        if (kDebugMode) {
          debugPrint('[fetchCurrentUser] Offline / network issue: ${failure.message}');
        }
      }
    }
  }

  // Logout (S2, S9)
  Future<void> logout({bool expired = false}) async {
    _token = null;
    _currentUser = null;
    _isDemoUser = false;
    _isAppUnlocked = false;
    _apiClient.clearAuthToken();

    await _secureStorage.clearAuthToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_easypaisa');
    await prefs.remove('user_jazzcash');

    if (expired) {
      _errorMessage = 'Your session expired. Please sign in again.';
    }

    notifyListeners();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
