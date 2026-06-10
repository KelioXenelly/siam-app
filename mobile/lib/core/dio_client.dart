import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobile/core/api_constants.dart';
import 'package:mobile/core/storage_service.dart';
import 'package:mobile/main.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Cek Konektivitas Internet
          final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
          if (connectivityResult.contains(ConnectivityResult.none)) {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Tidak ada koneksi internet. Pastikan Anda terhubung ke jaringan.',
                type: DioExceptionType.connectionError,
              ),
            );
          }

          final token = await StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Jika token expired atau ditolak (401)
          if (e.response?.statusCode == 401) {
            await StorageService.removeAll();
            
            final context = globalNavigatorKey.currentContext;
            if (context != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sesi Anda telah berakhir, silakan login kembali.'),
                  backgroundColor: Colors.red,
                ),
              );
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            }
          }
          return handler.next(e);
        },
      ),
    );
}