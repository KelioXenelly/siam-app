import 'package:dio/dio.dart';
import 'package:siam_mobile/core/dio_client.dart';
import 'package:siam_mobile/core/dio_exception_handler.dart';

class MahasiswaService {
  final Dio _dio = DioClient.dio;

  // 📝 GET RIWAYAT ABSENSI
  Future<List<dynamic>> getRiwayatAbsensi() async {
    try {
      final res = await _dio.get('/absensi/riwayat');
      if (res.data['success'] == true) {
        return res.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          return [];
        }
        throw DioExceptionHandler.handle(e, fallbackMessage: 'Gagal mengambil riwayat absensi');
      }
      throw Exception('Terjadi kesalahan jaringan');
    }
  }

  // 🎓 GET KELAS SAYA
  Future<List<dynamic>> getKelasSaya() async {
    try {
      final res = await _dio.get('/mahasiswa/kelas-saya');
      if (res.data['success'] == true) {
        return res.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        throw DioExceptionHandler.handle(e, fallbackMessage: 'Gagal mengambil data kelas');
      }
      throw Exception('Terjadi kesalahan jaringan');
    }
  }

  // 📸 SCAN QR & UPLOAD SELFIE
  Future<Map<String, dynamic>> scanAbsensi({
    required String token,
    required double lat,
    required double lng,
    required String selfiePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'token': token,
        'latitude_mahasiswa': lat,
        'longitude_mahasiswa': lng,
        'selfie_photo': await MultipartFile.fromFile(selfiePath, filename: 'selfie.jpg'),
      });

      final res = await _dio.post('/absensi/scan', data: formData);
      return res.data;
    } catch (e) {
      if (e is DioException) {
        throw DioExceptionHandler.handle(e, fallbackMessage: 'Gagal memproses absensi');
      }
      throw Exception('Terjadi kesalahan jaringan');
    }
  }
}
