import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Central error representation for Raqmify.
/// Never exposes raw technical exceptions or stack traces to end users.
class AppFailure {
  final String message;
  final int? statusCode;
  final dynamic technicalDetails;

  const AppFailure({
    required this.message,
    this.statusCode,
    this.technicalDetails,
  });

  @override
  String toString() => message;

  /// Map any exception (especially DioException) into a clear, friendly AppFailure.
  factory AppFailure.fromException(dynamic error) {
    if (error is AppFailure) {
      return error;
    }

    if (error is DioException) {
      if (kDebugMode) {
        debugPrint('[DioException] Type: ${error.type}, Path: ${error.requestOptions.path}, Message: ${error.message}, Response: ${error.response?.data}');
      }

      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;
      String? backendMsg;

      if (responseData is Map) {
        backendMsg = responseData['message']?.toString() ??
            responseData['error']?.toString();
      }

      if (backendMsg != null && backendMsg.trim().isNotEmpty) {
        return AppFailure(
          message: backendMsg.trim(),
          statusCode: statusCode,
          technicalDetails: error,
        );
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return AppFailure(
            message: 'Server took too long to respond. The server may be waking up, please try again in a few seconds.',
            statusCode: statusCode,
            technicalDetails: error,
          );
        case DioExceptionType.connectionError:
          return AppFailure(
            message: 'Unable to connect. Please check your internet connection and try again.',
            statusCode: statusCode,
            technicalDetails: error,
          );
        case DioExceptionType.badResponse:
          if (statusCode == 400) {
            return AppFailure(
              message: 'Invalid request. Please verify your inputs.',
              statusCode: 400,
              technicalDetails: error,
            );
          } else if (statusCode == 401) {
            return AppFailure(
              message: 'Your session expired. Please sign in again.',
              statusCode: 401,
              technicalDetails: error,
            );
          } else if (statusCode == 403) {
            return AppFailure(
              message: 'You do not have permission to perform this action.',
              statusCode: 403,
              technicalDetails: error,
            );
          } else if (statusCode == 404) {
            return AppFailure(
              message: 'The requested resource was not found.',
              statusCode: 404,
              technicalDetails: error,
            );
          } else if (statusCode == 409) {
            return AppFailure(
              message: 'A conflict occurred. This record may already exist.',
              statusCode: 409,
              technicalDetails: error,
            );
          } else if (statusCode != null && statusCode >= 500) {
            return AppFailure(
              message: 'Our service is temporarily unavailable. Please try again shortly.',
              statusCode: statusCode,
              technicalDetails: error,
            );
          }
          return AppFailure(
            message: 'Something went wrong. Please try again.',
            statusCode: statusCode,
            technicalDetails: error,
          );
        case DioExceptionType.cancel:
          return AppFailure(
            message: 'Request was cancelled.',
            statusCode: statusCode,
            technicalDetails: error,
          );
        case DioExceptionType.badCertificate:
          return AppFailure(
            message: 'Security certificate verification failed.',
            statusCode: statusCode,
            technicalDetails: error,
          );
        case DioExceptionType.unknown:
        default:
          return AppFailure(
            message: 'Connection issue. Please check your internet connection.',
            statusCode: statusCode,
            technicalDetails: error,
          );
      }
    }

    if (kDebugMode) {
      debugPrint('[AppFailure.fromException] $error');
    }

    return AppFailure(
      message: 'An unexpected error occurred. Please try again.',
      technicalDetails: error,
    );
  }
}
