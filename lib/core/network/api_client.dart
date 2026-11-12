import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  int _androidFallbackIndex = 0;
  static final List<String> _androidUrls = [
    ApiConstants.productionUrl,
    'http://127.0.0.1:5000', // Local ADB fallback if offline
  ];

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20), // 20s to accommodate serverless cold starts
        receiveTimeout: const Duration(seconds: 25),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Request & Auth Token Interceptor + Auto Fallback for Android Network
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // If on Android and connection failed (timeout or socket unreachable), attempt next endpoint
          if (!kIsWeb && Platform.isAndroid && 
              (error.type == DioExceptionType.connectionTimeout || 
               error.type == DioExceptionType.connectionError)) {
            
            // Try next candidate endpoint if not exhausted
            if (_androidFallbackIndex < _androidUrls.length - 1) {
              _androidFallbackIndex++;
              final nextBase = _androidUrls[_androidFallbackIndex];
              dio.options.baseUrl = nextBase;
              
              final requestOptions = error.requestOptions;
              requestOptions.baseUrl = nextBase;
              
              try {
                final response = await dio.fetch(requestOptions);
                return handler.resolve(response);
              } catch (e) {
                // Keep propagating to return final error
              }
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
