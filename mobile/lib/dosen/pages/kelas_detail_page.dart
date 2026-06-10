import 'package:flutter/material.dart';
import 'package:mobile/dosen/services/dosen_service.dart';
import 'package:mobile/shared/dosen_bottom_nav.dart';
import 'package:mobile/dosen/pages/sesi_page.dart';

class DosenDetailKelasPage extends StatefulWidget {
  final int kelasId;
  final String namaMataKuliah;
  final String kodeKelas;
  final String semester;
  final String tahunAjaran;

  const DosenDetailKelasPage({
    super.key,
    required this.kelasId,
    required this.namaMataKuliah,
    required this.kodeKelas,
    required this.semester,
    required this.tahunAjaran,
  });

  @override
  State<DosenDetailKelasPage> createState() => _DosenDetailKelasPageState();
}

class _DosenDetailKelasPageState extends State<DosenDetailKelasPage> {

  final _currentIndex = 1;
  final DosenService _dosenService = DosenService();

  List<dynamic> _meetings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    try {
      final data = await _dosenService.getPertemuanByKelas(widget.kelasId);
      if (mounted) {
        setState(() {
          _meetings = data;
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

  Future<void> _startMeetingAndNavigate(dynamic m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Mulai Sesi Pertemuan?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Apakah Anda yakin ingin memulai '${m['topik'] ?? "Pertemuan ${m['pertemuan_ke']}"}' sekarang?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Mulai"),
          )
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Call API startPertemuan
      final startRes = await _dosenService.startPertemuan(m['id']);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (startRes['success'] == true) {
        // Refresh the local meetings list
        _loadMeetings();

        // 2. Navigate to Sesi Page
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DosenSesiPage(
                pertemuanId: m['id'],
                kelasId: widget.kelasId,
                namaMataKuliah: widget.namaMataKuliah,
                topikPertemuan: m['topik'] ?? "Pertemuan ke-${m["pertemuan_ke"]}",
                kodeKelas: widget.kodeKelas,
                semester: widget.semester,
                tahunAjaran: widget.tahunAjaran,
              ),
            ),
          ).then((val) {
            if (val == true) {
              _loadMeetings();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      _showErrorDialog(e.toString().replaceAll("Exception: ", ""));
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Gagal", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  int get _completedCount => _meetings.where((m) => m['status'] == 'Selesai').length;

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
      body: RefreshIndicator(
        onRefresh: _loadMeetings,
        color: const Color(0xFF7C3AED),
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

                  // BACK BUTTON
                  GestureDetector(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.pushReplacementNamed(context, '/dosen/kelas');
                      }
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

                  const SizedBox(height: 20),

                  Text(
                    widget.namaMataKuliah,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    "${widget.kodeKelas} • SMT ${widget.semester} (${widget.tahunAjaran})",
                    style: const TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 16),

                  // 📊 PROGRESS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Progress", style: TextStyle(color: Colors.white)),
                            Text(
                              "$_completedCount/${_meetings.length} Pertemuan",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _meetings.isEmpty ? 0 : _completedCount / _meetings.length,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 📊 STATS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _statBox("${_meetings.length}", "Total Sesi", Colors.blue)),
                  const SizedBox(width: 10),
                  Expanded(child: _statBox("$_completedCount", "Selesai", Colors.green)),
                  const SizedBox(width: 10),
                  Expanded(child: _statBox("${_meetings.length - _completedCount}", "Tersisa", Colors.purple)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📋 TITLE
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Daftar Pertemuan",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 📋 LIST MEETING
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMeetingList(),
            ),

            const SizedBox(height: 80),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (_meetings.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined, size: 70, color: Colors.blueAccent.withValues(alpha: 0.2)),
            const SizedBox(height: 20),
            const Text(
              "Belum Ada Sesi",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Jadwal pertemuan untuk kelas ini belum tersedia.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _meetings.map((m) => _meetingCard(m)).toList(),
    );
  }

  // 🔹 STAT BOX
  Widget _statBox(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // 🔹 MEETING CARD
  Widget _meetingCard(dynamic m) {
    final status = m['status'] ?? 'Terjadwal';
    final isDone = status == 'Selesai';
    final isBerlangsung = status == 'Berlangsung';
    final dateStr = m['tanggal'] ?? ''; // Format: YYYY-MM-DD
    
    DateTime? date;
    if (dateStr.isNotEmpty) {
      try {
        date = DateTime.parse(dateStr);
      } catch (e) {
        // Abaikan
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
        border: isBerlangsung ? Border.all(color: Colors.blueAccent, width: 1.5) : null,
      ),
      child: Row(
        children: [

          // ICON
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDone 
                ? Colors.green.withValues(alpha: 0.1) 
                : (isBerlangsung ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isDone ? Icons.check_circle : (isBerlangsung ? Icons.play_circle_fill : Icons.access_time),
              color: isDone ? Colors.green : (isBerlangsung ? Colors.blue : Colors.grey),
            ),
          ),

          const SizedBox(width: 12),

          // TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m['topik'] ?? "Pertemuan ke-${m["pertemuan_ke"]}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  date != null ? _formatDate(date) : dateStr,
                  style: const TextStyle(color: Colors.grey),
                ),
                if (isBerlangsung)
                  const Text(
                    "Sedang Berlangsung",
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                  )
              ],
            ),
          ),

          // ACTION
          if (isDone)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DosenSesiPage(
                      pertemuanId: m['id'],
                      kelasId: widget.kelasId,
                      namaMataKuliah: widget.namaMataKuliah,
                      topikPertemuan: m['topik'] ?? "Pertemuan ke-${m["pertemuan_ke"]}",
                      kodeKelas: widget.kodeKelas,
                      semester: widget.semester,
                      tahunAjaran: widget.tahunAjaran,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.remove_red_eye, color: Colors.green, size: 16),
                    SizedBox(width: 6),
                    Text("Lihat", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () {
                if (isBerlangsung) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DosenSesiPage(
                        pertemuanId: m['id'],
                        kelasId: widget.kelasId,
                        namaMataKuliah: widget.namaMataKuliah,
                        topikPertemuan: m['topik'] ?? "Pertemuan ke-${m["pertemuan_ke"]}",
                        kodeKelas: widget.kodeKelas,
                        semester: widget.semester,
                        tahunAjaran: widget.tahunAjaran,
                      ),
                    ),
                  ).then((val) {
                    if (val == true) {
                      _loadMeetings();
                    }
                  });
                } else {
                  _startMeetingAndNavigate(m);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isBerlangsung ? null : const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                  ),
                  color: isBerlangsung ? Colors.blueAccent : null,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isBerlangsung ? Icons.door_front_door : Icons.qr_code, 
                      color: Colors.white, 
                      size: 16
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isBerlangsung ? "Masuk" : "Mulai", 
                      style: const TextStyle(color: Colors.white)
                    ),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  // 🔹 FORMAT DATE
  String _formatDate(DateTime date) {
    const bulan = [
      "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
      "Jul", "Agu", "Sep", "Okt", "Nov", "Des"
    ];

    const hari = [
      "Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"
    ];

    return "${hari[date.weekday % 7]}, ${date.day} ${bulan[date.month - 1]} ${date.year}";
  }
}