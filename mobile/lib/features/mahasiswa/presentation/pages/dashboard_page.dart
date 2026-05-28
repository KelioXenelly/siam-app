import 'package:flutter/material.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/auth/data/services/auth_service.dart';
import 'package:mobile/features/mahasiswa/data/services/mahasiswa_service.dart';
import 'package:mobile/shared/widgets/mahasiswa/glass_card.dart';
import 'package:mobile/shared/widgets/mahasiswa/progress_ring.dart';
import 'package:mobile/shared/widgets/mahasiswa/bottom_nav.dart';
import 'package:mobile/features/mahasiswa/presentation/pages/scan_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  final _currentIndex = 0;
  final AuthService _authService = AuthService();
  final MahasiswaService _mahasiswaService = MahasiswaService();

  User? _user;
  List<dynamic> _riwayat = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await _authService.getMe();
      final riwayat = await _mahasiswaService.getRiwayatAbsensi();
      
      if (mounted) {
        setState(() {
          _user = user;
          _riwayat = riwayat;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onNavTapped(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;

      case 1:
        Navigator.pushReplacementNamed(context, '/kelas');
        break;

      case 2:
        Navigator.pushReplacementNamed(context, '/riwayat');
        break;

      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 📊 STATS CALCULATION
    int hadir = _riwayat.where((r) => r['status'] == 'hadir').length;
    int terlambat = _riwayat.where((r) => r['status'] == 'terlambat').length;
    int alfa = _riwayat.where((r) => r['status'] == 'alfa').length;
    int totalAbsen = hadir + terlambat + alfa;
    
    double progress = totalAbsen == 0 ? 0 : ((hadir + terlambat) / totalAbsen) * 100;
    
    String progressText = "Belum ada data kehadiran.";
    if (totalAbsen > 0) {
      if (progress >= 80) {
        progressText = "Tingkat kehadiran Anda sangat baik! 🎉";
      } else if (progress >= 60) {
        progressText = "Tingkat kehadiran Anda cukup baik. 👍";
      } else {
        progressText = "Tingkat kehadiran Anda perlu ditingkatkan! ⚠️";
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF2563EB),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [

            // 🔵 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
                child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Halo,", style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 5),
                            Text(
                              _user?.name ?? "Nama Tidak Diketahui",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${_user?.identifier ?? '-'} • ${_user?.prodiName ?? '-'}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(_user?.name ?? ""),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
            ),

            const SizedBox(height: 16),

            // 🔥 CONTENT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [

                  // 📊 STATS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard("Hadir", hadir, Colors.green),
                      _buildStatCard("Terlambat", terlambat, Colors.orange),
                      _buildStatCard("Alfa", alfa, Colors.red),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 📈 PROGRESS
                  GlassCard(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        // Assuming ProgressRing takes a double from 0 to 100
                        ProgressRing(progress: progress),
                        const SizedBox(height: 10),
                        Text(progressText, textAlign: TextAlign.center),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 📷 SCAN BUTTON
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScanPage()),
                      ).then((val) {
                        // Refresh riwayat jika val == true (berhasil absen)
                        if (val == true) {
                          _loadData();
                        }
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.qr_code_scanner, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            "Scan Presensi Sekarang",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    margin: const EdgeInsets.only(bottom: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Absensi Terkini",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/riwayat');
                          },
                          child: Row(
                            children: const [
                              Text(
                                "Lihat Semua",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, size: 16, color: Colors.blue),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  // 📋 RECENT
                  _buildRecentList(),

                  const SizedBox(height: 80),
                ],
              ),
            )
          ],
        ),
      ),
      ),
    );
  }

  // 🔹 RECENT LIST
  Widget _buildRecentList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_riwayat.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("Belum ada riwayat absensi."),
      );
    }

    // Ambil maksimal 3 data terakhir
    final recentItems = _riwayat.take(3).toList();

    return Column(
      children: recentItems.map((item) {
        // Safe access to nested JSON properties
        final sesi = item['sesi_absensi'] ?? {};
        final pertemuan = sesi['pertemuan'] ?? {};
        final kelas = pertemuan['kelas'] ?? {};
        final mataKuliah = kelas['mata_kuliah'] ?? {};
        
        final namaMk = mataKuliah['nama_mk'] ?? 'Unknown MK';
        
        // Capitalize status
        String status = item['status'] ?? 'Unknown';
        if (status.isNotEmpty) {
          status = status[0].toUpperCase() + status.substring(1);
        }

        return _buildRecentItem(namaMk, status);
      }).toList(),
    );
  }

  // 🔹 STAT CARD
  Widget _buildStatCard(String title, int value, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GlassCard(
          child: Column(
            children: [
              Icon(Icons.circle, color: color, size: 14),
              const SizedBox(height: 6),
              Text(
                "$value",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 RECENT ITEM
  Widget _buildRecentItem(String matkul, String status) {
    Color color = status == "Hadir"
        ? Colors.green
        : status == "Terlambat"
        ? Colors.orange
        : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Row(
          children: [
            Icon(Icons.check_circle, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(matkul)),
            Text(
              status,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "??";
    List<String> parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }
}
