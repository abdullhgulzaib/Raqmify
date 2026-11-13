import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../services/secure_storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  String? _cachedToken;
  bool _isHandling401 = false;

  /// Global callback triggered on 401 unauthorized to navigate to login and clear state (S9)
  VoidCallback? onSessionExpired;

  void setAuthToken(String? token) {
    _cachedToken = token;
  }

  void clearAuthToken() {
    _cachedToken = null;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 25),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Request & Auth Token Interceptor (S2, S9)
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          _cachedToken ??= await SecureStorageService().getAuthToken();
          if (_cachedToken != null && _cachedToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_cachedToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Handle 401 unauthorized (S9)
          if (error.response?.statusCode == 401) {
            final path = error.requestOptions.path;
            final isAuthEndpoint = path.contains(ApiConstants.login) ||
                path.contains(ApiConstants.register);

            if (!isAuthEndpoint && !_isHandling401) {
              _isHandling401 = true;
              _cachedToken = null;
              await SecureStorageService().clearAuthToken();

              if (onSessionExpired != null) {
                onSessionExpired!();
              }

              Future.delayed(const Duration(seconds: 3), () {
                _isHandling401 = false;
              });
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  // GET
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  // POST
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await dio.post(path, data: data, queryParameters: queryParameters);
  }

  // PUT
  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await dio.put(path, data: data, queryParameters: queryParameters);
  }

  // DELETE
  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await dio.delete(path, data: data, queryParameters: queryParameters);
  }
}
