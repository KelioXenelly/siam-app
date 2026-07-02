import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:siam_mobile/core/storage_service.dart';
import 'package:siam_mobile/auth/pages/login_page.dart';
import 'package:siam_mobile/auth/pages/ubah_password_page.dart';
import 'package:siam_mobile/dosen/pages/kelas_page.dart';
import 'package:siam_mobile/dosen/pages/profile_page.dart';
import 'package:siam_mobile/mahasiswa/mahasiswa_main.dart';
import 'package:siam_mobile/dosen/dosen_main.dart';
import 'package:siam_mobile/mahasiswa/pages/profile_page.dart';
import 'package:siam_mobile/mahasiswa/pages/kelas_page.dart';
import 'package:siam_mobile/mahasiswa/pages/riwayat_page.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
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
      navigatorKey: globalNavigatorKey,
      title: 'SIAM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/ubah-password': (context) => const UbahPasswordPage(),
        // Mahasiswa Routes
        '/dashboard': (context) => const MahasiswaMain(),
        '/kelas': (context) => const KelasPage(),
        '/riwayat': (context) => const RiwayatPage(),
        '/profile': (context) => const ProfilePage(),
        // Dosen Routes
        '/dosen/dashboard': (context) => const DosenMain(),
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
              return const DosenMain();
            } else {
              // Default to Mahasiswa Dashboard
              return const MahasiswaMain();
            }
          }

          // Not logged in
          return const LoginPage();
        }
      ),
    );
  }
}