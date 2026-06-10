import 'package:dio/dio.dart';
import 'package:mobile/core/dio_client.dart';
import 'package:mobile/core/dio_exception_handler.dart';

class DosenService {
  final Dio _dio = DioClient.dio;

  Future<List<dynamic>> getKelasSaya() async {
    try {
      final res = await _dio.get('/dosen/kelas-saya');
      if (res.data['success'] == true) {
        return res.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e, 'Gagal mengambil data kelas');
      }
      throw Exception('Terjadi kesalahan jaringan');
    }
  }

  // 📅 GET PERTEMUAN BY KELAS
  Future<List<dynamic>> getPertemuanByKelas(int kelasId) async {
    try {
      final res = await _dio.get('/kelas/$kelasId/pertemuan');
      if (res.data['success'] == true) {
        return res.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e, 'Gagal mengambil data pertemuan');
      }
      throw Exception('Terjadi kesalahan jaringan');
    }
  }

  // 🚀 START PERTEMUAN
  Future<Map<String, dynamic>> startPertemuan(int pertemuanId) async {
    try {
      final res = await _dio.post('/pertemuan/$pertemuanId/start');
      return res.data;
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e, 'Gagal memulai pertemuan');
      }
      throw Exception('Terjadi kesalahan jaringan');
    }
  }

  // 🏁 END PERTEMUAN
  Future<Map<String, dynamic>> endPertemuan(int pertemuanId) async {
    try {
      final res = await _dio.post('/pertemuan/$pertemuanId/end');
      return res.data;
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e, 'Gagal mengakhiri pertemuan');
      }
      throw Exception('Terjadi kesalahan jaringan');
    }
  }

  // 📲 GENERATE QR
  Future<Map<String, dynamic>> generateQR(int pertemuanId, double lat, double lng) async {
    try {
      final res = await _dio.post('/generate-qr', data: {
        'pertemuan_id': pertemuanId,
        'latitude_dosen': lat,
        'longitude_dosen': lng,
      });
      return res.data;
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e, 'Gagal membuat QR absensi');
      }
      throw Exception('Terjadi kesalahan jaringan');
    }
  }

  // 🔍 GET ACTIVE SESI
  Future<Map<String, dynamic>?> getActiveSesi(int pertemuanId) async {
    try {
      final res = await _dio.get('/pertemuan/$pertemuanId/sesi-aktif');
      if (res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return null;
      }
      if (e is DioException) {
        throw _handleDioError(e, 'Gagal memeriksa sesi aktif');
      }
      return null; // Gracefully return null if session is not active/not found
    }
  }

  // 🔍 GET ALL SESI (Termasuk yang sudah ditutup)
  Future<List<dynamic>> getAllSesi(int pertemuanId) async {
    try {
      final res = await _dio.get('/pertemuan/$pertemuanId/sesi');
      if (res.data['success'] == true) {
        return res.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return [];
      }
      if (e is DioException) {
        throw _handleDioError(e, 'Gagal mengambil riwayat sesi');
      }
      return [];
    }
  }

  // 👥 GET SESI ABSENSI (LIST MAHASISWA CHECKED IN)
  Future<List<dynamic>> getSesiAbsensi(int sesiId) async {
    try {
      final res = await _dio.get('/sesi/$sesiId/absensi');
      if (res.data['success'] == true) {
        return res.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e, 'Gagal mengambil data kehadiran');
      }
      throw Exception('Terjadi kesalahan jaringan');
    }
  }

  // 📝 UPDATE STATUS MANUAL
  Future<bool> updateStatusManual(int absensiId, String status) async {
    try {
      final res = await _dio.put('/absensi/$absensiId/manual', data: {
        'status': status,
      });
      return res.data['success'] == true;
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e, 'Gagal mengubah status presensi');
      }
      throw Exception('Terjadi kesalahan jaringan');
    }
  }

  // 🔒 CLOSE SESI
  Future<bool> closeSesi(int sesiId) async {
    try {
      final res = await _dio.post('/sesi/$sesiId/close');
      return res.data['success'] == true;
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e, 'Gagal menutup sesi absensi');
      }
      throw Exception('Terjadi kesalahan jaringan');
    }
  }

  Exception _handleDioError(DioException e, String defaultMessage) {
    return DioExceptionHandler.handle(e, fallbackMessage: defaultMessage);
  }
}
