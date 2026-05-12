import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';

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
        // Jika 404 (Tidak ada riwayat), kembalikan array kosong, bukan error
        if (e.response?.statusCode == 404) {
          return [];
        }
        final message = e.response?.data['message'] ?? 'Gagal mengambil riwayat absensi';
        throw Exception(message);
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
        final message = e.response?.data['message'] ?? 'Gagal mengambil data kelas';
        throw Exception(message);
      }
      throw Exception('Terjadi kesalahan jaringan');
    }
  }
}
