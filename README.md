# Raqmify Mobile App

A hardened personal finance and shared living expense management application built with Flutter. Designed for privacy, precision integer-paisa financial arithmetic, simplified debt netting, and offline-resilient expense tracking.

---

## Architectural Overview

Raqmify strictly follows a decoupled, layered architecture:

```
+-----------------------------------------------------------------+
|                        Presentation Layer                       |
|   Screens (Dashboard, Expenses, Split Vault, Analytics, Auth)   |
|   Widgets (AppEmptyState, AppShimmer, EmeraldWave, etc.)        |
+-----------------------------------------------------------------+
                                |
                                v
+-----------------------------------------------------------------+
|                    State Management (Provider)                  |
|   AuthProvider, ExpenseProvider, SplitProvider,                 |
|   ThemeProvider, NotificationProvider, AnalyticsProvider        |
+-----------------------------------------------------------------+
                                |
                                v
+-----------------------------------------------------------------+
|                    Domain & Pure Logic Layer                    |
|   Money (Integer Paisa Value Object),                           |
|   SplitCalculator (Equal, Custom, Percentage with remainders),  |
|   NettingCalculator (Per-group & Global pairwise debts)         |
+-----------------------------------------------------------------+
                                |
                                v
+-----------------------------------------------------------------+
|                    Infrastructure & Network                     |
|   ApiClient (Dio + 401 Interceptor), SecureStorageService       |
|   (Android Keystore + PBKDF2/HMAC Salted Hashing),              |
|   PdfStatementGenerator (Local TTF fonts, Urdu support)         |
+-----------------------------------------------------------------+
```

---

## Security Architecture

1. **Hardware-Backed Storage**: Sensitive credentials (auth tokens, PIN hash, failed lockout state) are stored in `FlutterSecureStorage`, protected by Android Keystore hardware encryption.
2. **Multi-Round Salted PIN Hashing**: PINs are never stored in plaintext. They are salted with a 16-byte cryptographically secure random salt and hashed using HMAC-SHA256 across 10,000 iterations. Verification uses constant-time comparison to prevent timing side-channel attacks.
3. **Progressive Rate Limiting & Lockout**:
   - 5 failed PIN attempts trigger a 30-second exponential backoff lockout.
   - 10 failed PIN attempts trigger automatic session invalidation and complete account logout.
4. **Network Hardening**: Cleartext HTTP traffic is disabled in production release builds via Android Network Security Config.
5. **Session Revocation**: 401 Unauthorized responses trigger an automatic token purge, storage wipe, and atomic redirection to the login screen.

---

## Backend API Contract & Endpoints

Base URL can be configured at compile time using `--dart-define=API_BASE_URL=...` (defaults to `http://localhost:5000/api` in debug mode).

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/auth/register` | Register new user account |
| `POST` | `/api/auth/login` | Authenticate user and obtain JWT token |
| `GET` | `/api/auth/me` | Retrieve authenticated user profile |
| `GET` | `/api/expenses` | Retrieve personal expenses list |
| `POST` | `/api/expenses` | Create personal expense record |
| `DELETE` | `/api/expenses/:id` | Delete expense record |
| `GET` | `/api/splitvault/summary` | Retrieve split vault summary, groups, and pairwise debts |
| `POST` | `/api/splitvault/groups` | Create new living group |
| `DELETE` | `/api/splitvault/groups/:id` | Delete living group |
| `POST` | `/api/splitvault/groups/join` | Join group via 8-character invite code |
| `POST` | `/api/splitvault/expenses` | Create shared split expense |
| `DELETE` | `/api/splitvault/expenses/:id` | Delete shared split expense |
| `POST` | `/api/splitvault/expenses/:id/splits/:userId/proof` | Submit settlement TID proof |
| `POST` | `/api/splitvault/expenses/:id/splits/:userId/verify` | Verify or reject settlement proof |

---

## Release Signing Configuration

To sign production release builds:
1. Generate an upload keystore:
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties` (this file is excluded in `.gitignore`):
   ```properties
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```
3. If `key.properties` is omitted, `android/app/build.gradle.kts` automatically falls back to the debug keystore for development ease.

---

## Development & Build Instructions

### Prerequisites
- Flutter SDK >= 3.24.0
- Android SDK Platform 34+
- Java 17

### Commands
```bash
# Install dependencies
flutter pub get

# Run static analysis (0 issues with strict rules)
flutter analyze

# Run zero-emoji audit
flutter test test/no_emoji_test.dart

# Run pure logic & unit tests
flutter test

# Run app in debug mode
flutter run

# Build release APK
flutter build apk --release --dart-define=API_BASE_URL=https://api.raqmify.app/api
```
