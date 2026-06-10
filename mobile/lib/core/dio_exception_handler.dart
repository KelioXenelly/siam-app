import 'package:dio/dio.dart';

class DioExceptionHandler {
  /// Ekstrak pesan error secara aman dari response DioException,
  /// baik berupa Object (Map), Array, maupun String biasa (Laravel validation errors).
  static Exception handle(DioException e, {String fallbackMessage = 'Terjadi kesalahan jaringan'}) {
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError || e.type == DioExceptionType.unknown) {
      return Exception('Gagal terhubung ke server (IP tidak valid atau server mati): ${e.message}');
    }

    final data = e.response?.data;

    // 1. Cek jika data adalah Map
    if (data != null && data is Map<String, dynamic>) {
      // Prioritaskan key 'errors'
      if (data.containsKey('errors') && data['errors'] != null) {
        final errors = data['errors'];

        // Jika errors adalah teks murni
        if (errors is String) {
          return Exception(errors);
        }

        // Jika errors adalah Map (Object validasi standar Laravel)
        if (errors is Map) {
          if (errors.isNotEmpty) {
            final firstErrorValue = errors.values.first;
            if (firstErrorValue is List && firstErrorValue.isNotEmpty) {
              return Exception(firstErrorValue[0].toString());
            }
            if (firstErrorValue is String) {
              return Exception(firstErrorValue);
            }
          }
        }

        // Jika errors adalah List
        if (errors is List && errors.isNotEmpty) {
          return Exception(errors[0].toString());
        }
      }

      // 2. Cek key 'message' jika 'errors' tidak ada/kosong
      if (data.containsKey('message') && data['message'] != null) {
        final message = data['message'].toString();
        // Abaikan pesan bawaan Laravel yang tidak informatif
        if (message != 'The given data was invalid.' && message != 'Server Error') {
          return Exception(message);
        }
      }
    }

    // Jika response string mentah
    if (data is String && data.isNotEmpty) {
       // Kita kembalikan fallback daripada menampilkan string HTML yang panjang dari server crash
       return Exception(fallbackMessage);
    }

    return Exception(fallbackMessage);
  }
}
