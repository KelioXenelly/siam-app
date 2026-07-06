import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siam_mobile/auth/providers/user_provider.dart';
import 'package:siam_mobile/dosen/services/dosen_service.dart';
import 'package:siam_mobile/shared/shimmer_loading.dart';
import 'package:siam_mobile/shared/glass_card.dart';
import 'package:siam_mobile/core/api_constants.dart';
import 'package:siam_mobile/dosen/pages/kelas_detail_page.dart';

class DosenDashboardPage extends StatefulWidget {
  final Function(int)? onTabChange;
  const DosenDashboardPage({super.key, this.onTabChange});

  @override
  State<DosenDashboardPage> createState() => _DosenDashboardPageState();
}

class _DosenDashboardPageState extends State<DosenDashboardPage> {
  final DosenService _dosenService = DosenService();
  
  bool _isLoading = true;
  List<dynamic> _courses = [];
  int _activeSessions = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (context.read<UserProvider>().user == null) {
          context.read<UserProvider>().fetchUser();
        }
      }
    });
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final courses = await _dosenService.getKelasSaya();
      
      // Calculate active sessions
      int active = 0;
      for (var course in courses) {
        final pertemuans = course['pertemuans'] as List?;
        if (pertemuans != null) {
          active += pertemuans.where((p) => p['status'] == 'Berlangsung').length;
        }
      }

      if (mounted) {
        setState(() {
          _courses = courses;
          _activeSessions = active;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "D";
    List<String> parts = name.trim().split(" ");
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return "${parts[0][0]}${parts[1][0]}".toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: const Color(0xFF7C3AED),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          children: [
            /// 🔵 PREMIUM HEADER
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5), Color(0xFF312E81)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Selamat datang kembali,", 
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w600)
                            ),
                            const SizedBox(height: 6),
                            _isLoading 
                              ? Container(
                                  width: 150, height: 28, 
                                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8))
                                )
                              : Text(
                                  user?.name ?? "Dosen",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            const SizedBox(height: 4),
                            _isLoading
                              ? Container(
                                  width: 100, height: 16, margin: const EdgeInsets.only(top: 6), 
                                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    "NIDN: ${user?.identifier ?? '-'}",
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                          ],
                        ),
                      ),
                      Container(
                        width: 60, height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 15,
                              spreadRadius: 2,
                            )
                          ],
                          image: (user?.avatar != null)
                              ? DecorationImage(
                                  image: NetworkImage(user!.avatar!.startsWith('http') ? user.avatar! : '${ApiConstants.baseUrl.replaceAll('/api', '/storage')}${user.avatar!.startsWith('/') ? '' : '/'}${user.avatar}'),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (user?.avatar == null)
                            ? Text(
                                user != null ? _getInitials(user.name) : "D",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ],
            ),

            if (_isLoading)
              const DashboardShimmer()
            else
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Text(
                    "Menu Utama",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 16),
                  
                  _menuCard(
                    icon: Icons.qr_code_scanner_rounded,
                    title: "Mulai Absensi",
                    subtitle: "Buka sesi absensi dari daftar kelas",
                    color: const Color(0xFF8B5CF6),
                    onTap: () => _showQuickAbsensiModal(context),
                  ),

                  _menuCard(
                    icon: Icons.analytics_outlined,
                    title: "Jadwal & Riwayat",
                    subtitle: "Pantau riwayat kehadiran mahasiswa",
                    color: const Color(0xFF3B82F6),
                    onTap: () => widget.onTabChange != null ? widget.onTabChange!(1) : Navigator.pushNamed(context, '/dosen/kelas'), // Route to Kelas Page
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(child: _statCard("Total Kelas", _courses.length.toString(), const Color(0xFF6366F1))),
                      const SizedBox(width: 16),
                      Expanded(child: _statCard("Sesi Aktif", _activeSessions.toString(), const Color(0xFF10B981))),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Jadwal Hari Ini",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      TextButton(
                        onPressed: () => widget.onTabChange != null ? widget.onTabChange!(1) : Navigator.pushNamed(context, '/dosen/kelas'),
                        child: const Text("Lihat Semua →", style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (_courses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Text("Tidak ada kelas pada semester aktif ini.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ..._courses.take(3).map((c) {
                      final title = c['mata_kuliah']?['nama_mk'] ?? 'Unknown';
                      final room = c['kode_kelas'] ?? '-';
                      return _kelasCard(title, room, "SKS: ${c['mata_kuliah']?['sks'] ?? '-'}");
                    }),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(color: Colors.blueGrey[400], fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.blueGrey[300])
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.show_chart_rounded, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(color: Colors.blueGrey[400], fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showQuickAbsensiModal(BuildContext context) {
    if (_courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anda belum memiliki kelas.')));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Text(
              "Pilih Kelas",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              "Pilih kelas untuk mengelola sesi absensi saat ini.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  final namaMk = course['mata_kuliah']?['nama_mk'] ?? 'Mata Kuliah Unknown';
                  final kodeKelas = course['kode_kelas'] ?? '-';
                  final semester = course['semester'] ?? '-';
                  final tahunAjaran = course['tahun_ajaran'] ?? '-';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pop(context); // Tutup modal
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DosenDetailKelasPage(
                              kelasId: course['id'],
                              namaMataKuliah: namaMk,
                              kodeKelas: kodeKelas,
                              semester: "$semester",
                              tahunAjaran: tahunAjaran,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.class_rounded, color: Color(0xFF8B5CF6)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(namaMk, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                                  const SizedBox(height: 4),
                                  Text("Kelas $kodeKelas", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kelasCard(String title, String time, String room) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        child: Container(
          decoration: BoxDecoration(
            border: const Border(
              left: BorderSide(color: Color(0xFF7C3AED), width: 4),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 45, height: 45,
                decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.class_rounded, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(time, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 16),
                        const Icon(Icons.location_on_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(room, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}