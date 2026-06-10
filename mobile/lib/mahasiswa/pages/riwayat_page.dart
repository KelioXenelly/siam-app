import 'package:flutter/material.dart';
import 'package:mobile/shared/shimmer_loading.dart';
import 'package:mobile/mahasiswa/services/mahasiswa_service.dart';
import 'package:mobile/shared/glass_card.dart';
import 'package:intl/intl.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final MahasiswaService _mahasiswaService = MahasiswaService();
  
  List<dynamic> _riwayat = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    try {
      final riwayat = await _mahasiswaService.getRiwayatAbsensi();
      if (mounted) {
        setState(() {
          _riwayat = riwayat;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 📊 STATS CALCULATION
    int hadir = _riwayat.where((r) => r['status'] == 'hadir').length;
    int terlambat = _riwayat.where((r) => r['status'] == 'terlambat').length;
    int alfa = _riwayat.where((r) => r['status'] == 'alfa').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadRiwayat,
        color: const Color(0xFF2563EB),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 🔵 HEADER GRADIENT SIVER
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF2563EB),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                "Riwayat Lengkap",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          
          // 📊 SUMMARY STATS CARD
          if (!_isLoading && _riwayat.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn("Hadir", hadir, Colors.green),
                        _buildStatColumn("Terlambat", terlambat, Colors.orange),
                        _buildStatColumn("Alfa", alfa, Colors.red),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 🔥 CONTENT
          SliverToBoxAdapter(
            child: _isLoading 
                ? const Padding(padding: EdgeInsets.only(top: 20), child: ListShimmer(itemCount: 4))
                : _riwayat.isEmpty 
                    ? Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 80,
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Belum ada riwayat absensi",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Mulai presensi di kelas pertamamu!",
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: _riwayat.map((r) {
                            final sesi = r['sesi_absensi'] ?? {};
                            final pertemuan = sesi['pertemuan'] ?? {};
                            final kelas = pertemuan['kelas'] ?? {};
                            final mataKuliah = kelas['mata_kuliah'] ?? {};
                            
                            final namaMk = mataKuliah['nama_mk'] ?? 'Unknown MK';
                            final topik = pertemuan['topik'] ?? "Pertemuan ke-${pertemuan['pertemuan_ke'] ?? '?'}";
                            
                            String rawStatus = r['status'] ?? 'Unknown';
                            final status = rawStatus.isNotEmpty 
                                ? rawStatus[0].toUpperCase() + rawStatus.substring(1) 
                                : 'Unknown';
                            
                            final rawDate = r['waktu_absen'] ?? r['created_at'];
                            String formattedDate = "-";
                            if (rawDate != null) {
                              try {
                                final dt = DateTime.parse(rawDate).toLocal();
                                formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(dt);
                              } catch (_) {}
                            }

                            return _buildRiwayatCard(
                              namaMk: namaMk,
                              topik: topik,
                              status: status,
                              waktuAbsen: formattedDate,
                            );
                          }).toList(),
                        ),
                      ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatCard({
    required String namaMk,
    required String topik,
    required String status,
    required String waktuAbsen,
  }) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'hadir':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'terlambat':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time_filled;
        break;
      case 'alfa':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'izin':
      case 'sakit':
        statusColor = Colors.blue;
        statusIcon = Icons.info;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER (Topik & Status)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      topik,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
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
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // NAMA MATKUL
              Row(
                children: [
                  const Icon(Icons.book, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      namaMk,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // TIMESTAMP
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    waktuAbsen,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          "$count",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
