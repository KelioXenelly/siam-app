import 'package:flutter/material.dart';
import 'package:siam_mobile/mahasiswa/services/mahasiswa_service.dart';
import 'package:siam_mobile/shared/glass_card.dart';
import 'package:intl/intl.dart';

class KelasDetailPage extends StatefulWidget {
  final Map<String, dynamic> kelas;

  const KelasDetailPage({super.key, required this.kelas});

  @override
  State<KelasDetailPage> createState() => _KelasDetailPageState();
}

class _KelasDetailPageState extends State<KelasDetailPage> {
  final MahasiswaService _mahasiswaService = MahasiswaService();
  List<dynamic> _riwayatKelas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    try {
      final allRiwayat = await _mahasiswaService.getRiwayatAbsensi();
      final kelasId = widget.kelas['id'];
      
      // Filter riwayat yang sesuai dengan kelas_id ini
      final filtered = allRiwayat.where((item) {
        final sesi = item['sesi_absensi'] ?? {};
        final pertemuan = sesi['pertemuan'] ?? {};
        final kId = pertemuan['kelas_id'];
        return kId == kelasId;
      }).toList();

      if (mounted) {
        setState(() {
          _riwayatKelas = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matkul = widget.kelas['mata_kuliah'] ?? {};
    final namaMk = matkul['nama_mk'] ?? 'Unknown MK';
    final kodeMk = matkul['kode_mk'] ?? '-';
    final sks = matkul['sks'] ?? 0;
    final ruangan = widget.kelas['ruangan'] ?? 'TBA';
    final kodeKelas = widget.kelas['kode_kelas'] ?? '-';
    
    final dosen = widget.kelas['dosen'] ?? {};
    final userDosen = dosen['user'] ?? {};
    final namaDosen = userDosen['name'] ?? 'Dosen Belum Ditentukan';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadRiwayat,
        color: const Color(0xFF2563EB),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 🔵 HEADER
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF2563EB),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF4F46E5), Color(0xFF312E81)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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
                ],
              ),
              titlePadding: const EdgeInsets.only(left: 48, bottom: 16, right: 16),
              title: Text(
                namaMk,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // 🔥 CONTENT
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // INFO KELAS
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "$kodeMk • $kodeKelas",
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "$sks SKS",
                                  style: const TextStyle(
                                    color: Color(0xFFB45309),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(namaDosen, style: const TextStyle(fontSize: 15)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Text("Ruang: $ruangan", style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "Riwayat Kehadiran",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _riwayatKelas.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text("Belum ada riwayat kehadiran untuk kelas ini.",
                                    style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          : Column(
                              children: _riwayatKelas.map((item) {
                                final sesi = item['sesi_absensi'] ?? {};
                                final pertemuan = sesi['pertemuan'] ?? {};
                                final pKe = pertemuan['pertemuan_ke'] ?? '?';
                                final tanggal = pertemuan['tanggal'] ?? '';
                                final topik = pertemuan['topik'] ?? 'Topik Belum Ditentukan';
                                final waktuMulai = sesi['waktu_mulai'] ?? pertemuan['started_at'] ?? '';
                                final waktuSelesai = sesi['waktu_selesai'] ?? pertemuan['ended_at'] ?? '';
                                
                                String waktuString = waktuMulai;
                                if (waktuMulai.isNotEmpty && waktuSelesai.isNotEmpty) {
                                  // Format: 08:00 - 10:00
                                  waktuString = "${waktuMulai.substring(0,5)} - ${waktuSelesai.substring(0,5)}";
                                } else if (waktuMulai.isNotEmpty) {
                                  waktuString = waktuMulai.substring(0,5);
                                }
                                
                                String status = item['status'] ?? 'unknown';
                                status = status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : 'Unknown';
                                
                                Color statusColor = Colors.grey;
                                IconData statusIcon = Icons.help;
                                if (status == 'Hadir') {
                                  statusColor = Colors.green;
                                  statusIcon = Icons.check_circle;
                                } else if (status == 'Terlambat') {
                                  statusColor = Colors.orange;
                                  statusIcon = Icons.access_time_filled;
                                } else if (status == 'Alfa') {
                                  statusColor = Colors.red;
                                  statusIcon = Icons.cancel;
                                } else if (status == 'Izin') {
                                  statusColor = Colors.blue;
                                  statusIcon = Icons.info;
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            "P$pKe",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                topik,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800, 
                                                  fontSize: 16,
                                                  color: Color(0xFF1E293B),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    tanggal.isNotEmpty ? DateFormat('dd MMM yyyy').format(DateTime.parse(tanggal)) : 'TBA',
                                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    waktuString,
                                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            Icon(statusIcon, color: statusColor, size: 24),
                                            const SizedBox(height: 4),
                                            Text(
                                              status,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
      ),
    );
  }
}
