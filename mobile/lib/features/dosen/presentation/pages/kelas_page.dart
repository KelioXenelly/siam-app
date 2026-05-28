import 'package:flutter/material.dart';
import 'package:mobile/features/dosen/data/services/dosen_service.dart';
import 'package:mobile/features/dosen/presentation/pages/kelas_detail_page.dart';
import 'package:mobile/shared/widgets/dosen/bottom_nav.dart';

class DosenKelasPage extends StatefulWidget {
  const DosenKelasPage({super.key});

  @override
  State<DosenKelasPage> createState() => _DosenKelasPageState();
}

class _DosenKelasPageState extends State<DosenKelasPage> {

  final _currentIndex = 1;
  final DosenService _dosenService = DosenService();
  
  List<dynamic> _courses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadKelas();
  }

  Future<void> _loadKelas() async {
    try {
      final data = await _dosenService.getKelasSaya();
      if (mounted) {
        setState(() {
          _courses = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onNavTapped(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dosen/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/dosen/kelas');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/dosen/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            // 🔵 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/dosen/dashboard');
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Kelas Saya",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          "${_courses.length} kelas aktif semester ini",
                          style: const TextStyle(color: Colors.white70),
                        )
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 🔥 LIST KELAS ATAU LOADING
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildBody(),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadKelas();
              },
              child: const Text('Coba Lagi'),
            )
          ],
        ),
      );
    }

    if (_courses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: Text('Belum ada kelas yang ditugaskan kepada Anda.')),
      );
    }

    return Column(
      children: _courses.map((course) {
        return _kelasCard(course);
      }).toList(),
    );
  }

  // 🔹 CARD KELAS
  Widget _kelasCard(dynamic course) {
    final namaMk = course['mata_kuliah']?['nama_mk'] ?? 'Mata Kuliah Unknown';
    final kodeKelas = course['kode_kelas'] ?? '-';
    final semester = course['semester'] ?? '-';
    final tahunAjaran = course['tahun_ajaran'] ?? '-';
    
    final totalMahasiswa = (course['mahasiswas'] as List?)?.length ?? 0;
    final pertemuans = course['pertemuans'] as List?;
    final totalPertemuan = pertemuans?.length ?? 16;
    final pertemuanSelesai = pertemuans?.where((p) => p['status'] == 'Selesai').length ?? 0;

    return GestureDetector(
      onTap: () {
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            )
          ],
        ),
        child: Column(
          children: [
            // HEADER
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: const Icon(Icons.menu_book, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaMk,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "$kodeKelas • SMT $semester ($tahunAjaran)",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: 16),

            // STATS
            Row(
              children: [
                Expanded(child: _statBox("$totalMahasiswa", "Mahasiswa", Colors.purple)),
                const SizedBox(width: 10),
                Expanded(child: _statBox("$totalPertemuan", "Total", Colors.blue)),
                const SizedBox(width: 10),
                Expanded(child: _statBox("$pertemuanSelesai", "Selesai", Colors.green)),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),

            // ACTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Lihat detail & mulai sesi"),
                Icon(Icons.arrow_forward, color: Colors.purple),
              ],
            )
          ],
        ),
      ),
    );
  }

  // 🔹 STAT BOX
  Widget _statBox(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12))
        ],
      ),
    );
  }
}