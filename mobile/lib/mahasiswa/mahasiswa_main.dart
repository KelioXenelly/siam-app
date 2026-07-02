import 'package:flutter/material.dart';
import 'package:siam_mobile/mahasiswa/pages/dashboard_page.dart';
import 'package:siam_mobile/mahasiswa/pages/kelas_page.dart';
import 'package:siam_mobile/mahasiswa/pages/riwayat_page.dart';
import 'package:siam_mobile/mahasiswa/pages/profile_page.dart';
import 'package:siam_mobile/shared/mahasiswa_bottom_nav.dart';

class MahasiswaMain extends StatefulWidget {
  const MahasiswaMain({super.key});

  @override
  State<MahasiswaMain> createState() => _MahasiswaMainState();
}

class _MahasiswaMainState extends State<MahasiswaMain> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    DashboardPage(onTabChange: _onTabTapped),
    const KelasPage(),
    const RiwayatPage(),
    const ProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
