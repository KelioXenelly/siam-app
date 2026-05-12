import 'package:flutter/material.dart';
import 'package:mobile/core/services/storage_service.dart';
import 'package:mobile/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/features/dosen/presentation/pages/dashboard_page.dart';
import 'package:mobile/features/dosen/presentation/pages/kelas_page.dart';
import 'package:mobile/features/dosen/presentation/pages/profile_page.dart';
import 'package:mobile/features/mahasiswa/presentation/pages/dashboard_page.dart';
import 'package:mobile/features/mahasiswa/presentation/pages/profile_page.dart';

void main() {
  // Ensure plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Helper to fetch auth data
  Future<Map<String, dynamic>> getAuthStatus() async {
    final token = await StorageService.getToken();
    final role = await StorageService.getRole();
    return {
      'isLoggedIn': token != null,
      'role': role,
    };
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIAM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        // Mahasiswa Routes
        '/dashboard': (context) => const DashboardPage(),
        '/profile': (context) => const ProfilePage(),
        // Dosen Routes
        '/dosen/dashboard': (context) => const DosenDashboardPage(),
        '/dosen/kelas': (context) => const DosenKelasPage(),
        '/dosen/profile': (context) => const DosenProfilePage(),
      },
      home: FutureBuilder<Map<String, dynamic>>(
        future: getAuthStatus(),
        builder: (context, snapshot) {
          // Handle Loading State
          // Handle Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data;

          // Role-based Redirection Logic
          if (data != null && data['isLoggedIn'] == true) {
            final role = data['role'];
            if (role == 'dosen') {
              return const DosenDashboardPage();
            } else {
              // Default to Mahasiswa Dashboard
              return const DashboardPage();
            }
          }

          // Not logged in
          return const LoginPage();
        }
      ),
    );
  }
}