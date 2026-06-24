import 'package:flutter/material.dart';
import 'package:siam_mobile/dosen/services/dosen_service.dart';
import 'package:siam_mobile/shared/dosen_bottom_nav.dart';
import 'package:siam_mobile/dosen/pages/sesi_page.dart';
import 'package:siam_mobile/shared/glass_card.dart';

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

            // 🔵 PREMIUM HEADER
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5), Color(0xFF312E81)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.namaMataKuliah,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${widget.kodeKelas} • SMT ${widget.semester} (${widget.tahunAjaran})",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 24),
                      // 📊 PROGRESS
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Progress", style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
                                Text(
                                  "$_completedCount/${_meetings.length} Pertemuan",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                value: _meetings.isEmpty ? 0 : _completedCount / _meetings.length,
                                backgroundColor: Colors.white.withValues(alpha: 0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          ],
                        ),
                      )
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

            const SizedBox(height: 16),

            // 📊 STATS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _statBox("${_meetings.length}", "Total Sesi", const Color(0xFF3B82F6))),
                  const SizedBox(width: 10),
                  Expanded(child: _statBox("$_completedCount", "Selesai", const Color(0xFF10B981))),
                  const SizedBox(width: 10),
                  Expanded(child: _statBox("${_meetings.length - _completedCount}", "Tersisa", const Color(0xFF8B5CF6))),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
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
    return GlassCard(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  // 🔹 MEETING CARD
  Widget _meetingCard(dynamic m) {
    final status = m['status'] ?? 'Terjadwal';
    final isDone = status == 'Selesai';
    final isBerlangsung = status == 'Berlangsung';
    final dateStr = m['tanggal'] ?? ''; 
    
    DateTime? date;
    if (dateStr.isNotEmpty) {
      try {
        date = DateTime.parse(dateStr);
      } catch (e) {
        // Ignore parse error
      }
    }

    Color statusColor = Colors.grey;
    if (isDone) statusColor = const Color(0xFF10B981); // Emerald
    if (isBerlangsung) statusColor = const Color(0xFF3B82F6); // Blue

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: GlassCard(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: statusColor, width: 4),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ICON
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDone ? Icons.check_circle_rounded : (isBerlangsung ? Icons.play_circle_fill_rounded : Icons.access_time_rounded),
                  color: statusColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['topik'] ?? "Pertemuan ke-${m["pertemuan_ke"]}",
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date != null ? _formatDate(date) : dateStr,
                      style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    if (isBerlangsung)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Row(
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            const Text("Sedang Berlangsung", style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      )
                  ],
                ),
              ),

              const SizedBox(width: 12),

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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.remove_red_eye_rounded, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 6),
                        Text("Lihat", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700, fontSize: 13)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isBerlangsung ? null : const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                      ),
                      color: isBerlangsung ? const Color(0xFF3B82F6) : null,
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      boxShadow: isBerlangsung ? null : [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isBerlangsung ? Icons.meeting_room_rounded : Icons.play_arrow_rounded, 
                          color: Colors.white, 
                          size: 16
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isBerlangsung ? "Masuk" : "Mulai", 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)
                        ),
                      ],
                    ),
                  ),
                )
            ],
          ),
        ),
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