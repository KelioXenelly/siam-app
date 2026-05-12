import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';

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
        final message =
            e.response?.data['message'] ?? 'Gagal mengambil data kelas';
        throw Exception(message);
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
        final message =
            e.response?.data['message'] ?? 'Gagal mengambil data pertemuan';
        throw Exception(message);
      }
      throw Exception('Terjadi kesalahan jaringan');
    }
  }
}
