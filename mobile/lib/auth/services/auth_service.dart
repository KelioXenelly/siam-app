import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mobile/core/dio_client.dart';
import 'package:mobile/core/storage_service.dart';
import 'package:mobile/core/dio_exception_handler.dart';
import 'package:mobile/auth/models/user_model.dart';

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
        throw DioExceptionHandler.handle(e, fallbackMessage: 'Login gagal');
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
        throw DioExceptionHandler.handle(e, fallbackMessage: 'Gagal mengambil user');
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
        throw DioExceptionHandler.handle(e, fallbackMessage: 'Gagal mengubah password');
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
        throw DioExceptionHandler.handle(e, fallbackMessage: 'Gagal mengunggah foto profil');
      }
      throw Exception('Gagal mengunggah foto profil');
    }
  }
}