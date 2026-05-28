import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/services/storage_service.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';

class AuthService {
  final Dio _dio = DioClient.dio;

  // 🔐 LOGIN
  Future<User> login(String identifier, String password) async {
    try {
      final res = await _dio.post(
        '/login',
        data: {
          'identifier': identifier,
          'password': password,
        },
      );

      final token = res.data['token'];
      final user = User.fromJson(res.data['user']);

      // 🔥 simpan token & role
      await StorageService.saveToken(token);
      await StorageService.saveRole(user.role);

      return user;
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;

        // 🔥 1. errors = STRING
        if (data['errors'] != null && data['errors'] is String) {
          throw Exception(data['errors']);
        }

        // 🔥 2. errors = OBJECT (validation)
        if (data['errors'] != null && data['errors'] is Map) {
          final firstError = data['errors'].values.first[0];
          throw Exception(firstError);
        }

        // 🔥 3. message
        if (data['message'] != null) {
          throw Exception(data['message']);
        }
      }
      throw Exception('Login gagal');
    }
  }

  // 👤 GET USER LOGIN
  Future<User> getMe() async {
    try {
      final res = await _dio.get('/me');
      return User.fromJson(res.data);
    } catch (e) {
      if (e is DioException) {
        final errors = e.response?.data['errors'];

        if (errors != null && errors is Map) {
          final firstError = errors.values.first[0];
          throw Exception(firstError);
        }
      }

      throw Exception('Gagal mengambil user');
    }
  }

  // 🔑 UBAH PASSWORD
  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    try {
      await _dio.post(
        '/change-password',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data != null && data['message'] != null) {
          throw Exception(data['message']);
        }
      }
      throw Exception('Gagal mengubah password');
    }
  }

  // 🚪 LOGOUT
  Future<void> logout() async {
    try {
      // 1. Tell the server to invalidate the token
      // Using a try-catch inside so if the network fails, we still clear local data
      await _dio.post('/logout').catchError((e) {
        throw Exception('Logout gagal');
      });
    } finally {
      // 2. Clear ALL local storage (Token, Role, etc.)
      // This ensures the app is in a clean state even if the API call fails
      await StorageService.removeAll();
    }
  }

  // 📸 UPLOAD AVATAR
  Future<User> uploadAvatar(File file) async {
    try {
      String fileName = file.path.split('/').last;
      
      FormData formData = FormData.fromMap({
        "avatar": await MultipartFile.fromFile(file.path, filename: fileName),
      });
      
      final res = await _dio.post(
        '/update-avatar',
        data: formData,
      );
      
      return User.fromJson(res.data['user']);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data != null && data['message'] != null) {
          throw Exception(data['message']);
        }
      }
      throw Exception('Gagal mengunggah foto profil');
    }
  }
}