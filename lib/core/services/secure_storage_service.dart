import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PinVerifyStatus {
  success,
  incorrect,
  lockedOut,
  noPinSet,
  maxAttemptsExceeded,
}

class PinVerifyResult {
  final PinVerifyStatus status;
  final int attemptsRemaining;
  final int lockoutSeconds;
  final String? errorMessage;

  const PinVerifyResult({
    required this.status,
    this.attemptsRemaining = 5,
    this.lockoutSeconds = 0,
    this.errorMessage,
  });

  bool get isSuccess => status == PinVerifyStatus.success;
  bool get isLockedOut => status == PinVerifyStatus.lockedOut;
  bool get shouldLogout => status == PinVerifyStatus.maxAttemptsExceeded;
}

/// Secure storage service backed by Android Keystore (S2, S3).
/// Protects JWT tokens, hashes PINs with per-install random salt, and enforces progressive lockout.
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;

  final FlutterSecureStorage _storage;

  SecureStorageService._internal()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        );

  static const String _keyToken = 'auth_token';
  static const String _keyPinSalt = 'pin_salt';
  static const String _keyPinHash = 'pin_hash';
  static const String _keyFailedAttempts = 'failed_pin_attempts';
  static const String _keyLockoutUntil = 'pin_lockout_until';
  static const String _keyMigrationDone = 'storage_migrated_v2';

  // --- One-Time Migration from SharedPreferences (S2) ---
  Future<void> performOneTimeMigration() async {
    final prefs = await SharedPreferences.getInstance();
    final isMigrated = prefs.getBool(_keyMigrationDone) ?? false;
    if (isMigrated) return;

    // Migrate Auth Token
    final oldToken = prefs.getString('auth_token');
    if (oldToken != null && oldToken.isNotEmpty) {
      await saveAuthToken(oldToken);
      await prefs.remove('auth_token');
    }

    // Migrate Plaintext PIN to Salted Hash
    final oldPin = prefs.getString('vault_pin');
    if (oldPin != null && oldPin.isNotEmpty) {
      await savePin(oldPin);
      await prefs.remove('vault_pin');
    }

    await prefs.setBool(_keyMigrationDone, true);
  }

  // --- Auth Token (S2) ---
  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> clearAuthToken() async {
    await _storage.delete(key: _keyToken);
  }

  // --- PIN Management & Hashing (S2, S3) ---
  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _keyPinHash);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> savePin(String pin) async {
    final salt = _generateRandomSalt();
    final hash = _computeSaltedHash(pin, salt);

    await _storage.write(key: _keyPinSalt, value: salt);
    await _storage.write(key: _keyPinHash, value: hash);
    await resetFailedAttempts();
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _keyPinSalt);
    await _storage.delete(key: _keyPinHash);
    await resetFailedAttempts();
  }

  // --- PIN Verification & Progressive Lockout (S3) ---
  Future<PinVerifyResult> verifyPin(String enteredPin) async {
    // 1. Check if currently locked out
    final lockoutSeconds = await getRemainingLockoutSeconds();
    if (lockoutSeconds > 0) {
      return PinVerifyResult(
        status: PinVerifyStatus.lockedOut,
        lockoutSeconds: lockoutSeconds,
        errorMessage: 'Locked out due to repeated wrong PIN attempts. Try again in ${lockoutSeconds}s.',
      );
    }

    // 2. Check if PIN exists (never bypass if no PIN exists!)
    final salt = await _storage.read(key: _keyPinSalt);
    final storedHash = await _storage.read(key: _keyPinHash);

    if (salt == null || storedHash == null || salt.isEmpty || storedHash.isEmpty) {
      return const PinVerifyResult(
        status: PinVerifyStatus.noPinSet,
        errorMessage: 'No PIN set. Please set up a security PIN.',
      );
    }

    // 3. Compute hash and compare in constant time
    final enteredHash = _computeSaltedHash(enteredPin, salt);
    final isMatch = _constantTimeEquals(enteredHash, storedHash);

    if (isMatch) {
      await resetFailedAttempts();
      return const PinVerifyResult(status: PinVerifyStatus.success);
    }

    // 4. Failed attempt: increment and check thresholds
    final failedCount = (await _getFailedAttempts()) + 1;
    await _storage.write(key: _keyFailedAttempts, value: failedCount.toString());

    if (failedCount >= 10) {
      // 10 failures: require full logout
      await clearAuthToken();
      await resetFailedAttempts();
      return const PinVerifyResult(
        status: PinVerifyStatus.maxAttemptsExceeded,
        attemptsRemaining: 0,
        errorMessage: 'Too many failed attempts. You have been logged out for security.',
      );
    }

    if (failedCount >= 5) {
      // 5 to 9 failures: delay 30s doubling each round
      // round 1 (5 fails) = 30s, round 2 (6 fails) = 60s, round 3 (7 fails) = 120s...
      final round = failedCount - 4;
      final penaltySeconds = 30 * (1 << (round - 1));
      final lockoutUntil = DateTime.now().millisecondsSinceEpoch + (penaltySeconds * 1000);
      await _storage.write(key: _keyLockoutUntil, value: lockoutUntil.toString());

      return PinVerifyResult(
        status: PinVerifyStatus.lockedOut,
        lockoutSeconds: penaltySeconds,
        attemptsRemaining: 10 - failedCount,
        errorMessage: 'Incorrect PIN. Locked out for ${penaltySeconds}s (${10 - failedCount} attempts remaining before account logout).',
      );
    }

    final attemptsLeft = 5 - failedCount;
    return PinVerifyResult(
      status: PinVerifyStatus.incorrect,
      attemptsRemaining: attemptsLeft,
      errorMessage: 'Incorrect PIN. $attemptsLeft attempts remaining before cooldown.',
    );
  }

  Future<int> getRemainingLockoutSeconds() async {
    final lockoutUntilStr = await _storage.read(key: _keyLockoutUntil);
    if (lockoutUntilStr == null) return 0;

    final lockoutUntil = int.tryParse(lockoutUntilStr);
    if (lockoutUntil == null) return 0;

    final diffMs = lockoutUntil - DateTime.now().millisecondsSinceEpoch;
    if (diffMs <= 0) {
      await _storage.delete(key: _keyLockoutUntil);
      return 0;
    }
    return (diffMs / 1000).ceil();
  }

  Future<int> getFailedAttemptsCount() async {
    return await _getFailedAttempts();
  }

  Future<void> resetFailedAttempts() async {
    await _storage.delete(key: _keyFailedAttempts);
    await _storage.delete(key: _keyLockoutUntil);
  }

  Future<int> _getFailedAttempts() async {
    final str = await _storage.read(key: _keyFailedAttempts);
    return int.tryParse(str ?? '0') ?? 0;
  }

  // --- Cryptographic Helpers ---
  String _generateRandomSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _computeSaltedHash(String pin, String salt) {
    // Multi-round HMAC-SHA256 (PBKDF-style key derivation)
    final saltBytes = utf8.encode(salt);
    var key = utf8.encode(pin);
    var hmac = Hmac(sha256, key);
    var digest = hmac.convert(saltBytes);

    for (var i = 0; i < 1000; i++) {
      hmac = Hmac(sha256, digest.bytes);
      digest = hmac.convert(saltBytes);
    }

    return digest.toString();
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('vault_pin');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }
}
