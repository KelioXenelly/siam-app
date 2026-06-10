import 'package:flutter/material.dart';
import 'package:mobile/dosen/pages/dashboard_page.dart';
import 'package:mobile/dosen/pages/kelas_page.dart';
import 'package:mobile/dosen/pages/profile_page.dart';
import 'package:mobile/shared/dosen_bottom_nav.dart';

class DosenMain extends StatefulWidget {
  const DosenMain({super.key});

  @override
  State<DosenMain> createState() => _DosenMainState();
}

class _DosenMainState extends State<DosenMain> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    DosenDashboardPage(onTabChange: _onTabTapped),
    const DosenKelasPage(),
    const DosenProfilePage(),
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
