import 'package:flutter/material.dart';
import 'package:siam_mobile/shared/shimmer_loading.dart';
import 'package:siam_mobile/mahasiswa/services/mahasiswa_service.dart';
import 'package:siam_mobile/shared/glass_card.dart';
import 'package:siam_mobile/mahasiswa/pages/kelas_detail_page.dart';


class KelasPage extends StatefulWidget {
  const KelasPage({super.key});

  @override
  State<KelasPage> createState() => _KelasPageState();
}

class _KelasPageState extends State<KelasPage> {
  final MahasiswaService _mahasiswaService = MahasiswaService();
  
  List<dynamic> _kelas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKelas();
  }

  Future<void> _loadKelas() async {
    try {
      final kelas = await _mahasiswaService.getKelasSaya();
      if (mounted) {
        setState(() {
          _kelas = kelas;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
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
                "Kelas Saya",
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
          
          // 🔥 CONTENT
          SliverToBoxAdapter(
            child: _isLoading 
                ? const Padding(padding: EdgeInsets.only(top: 20), child: ListShimmer(itemCount: 4))
                : _kelas.isEmpty 
                    ? const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(
                          child: Text(
                            "Anda belum terdaftar di kelas manapun.",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: _kelas.map((k) {
                            return _buildKelasCard(k);
                          }).toList(),
                        ),
                      ),
          ),
          
          // Spacer for bottom
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildKelasCard(Map<String, dynamic> kelasData) {
    final matkul = kelasData['mata_kuliah'] ?? {};
    final namaMk = matkul['nama_mk'] ?? 'Unknown MK';
    final kodeMk = matkul['kode_mk'] ?? '-';
    final sks = matkul['sks'] ?? 0;
    final ruangan = kelasData['ruangan'] ?? 'TBA';
    final kodeKelas = kelasData['kode_kelas'] ?? '-';
    
    final dosen = kelasData['dosen'] ?? {};
    final userDosen = dosen['user'] ?? {};
    final namaDosen = userDosen['name'] ?? 'Dosen Belum Ditentukan';
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KelasDetailPage(kelas: kelasData),
            ),
          );
        },
        child: GlassCard(
        child: Container(
          // ✨ Accent Line di sebelah kiri kartu
          decoration: BoxDecoration(
            border: const Border(
              left: BorderSide(color: Color(0xFF3B82F6), width: 4),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Kode Matkul & SKS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // Light Blue
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      "$kodeMk • $kodeKelas",
                      style: const TextStyle(
                        color: Color(0xFF1D4ED8), // Dark Blue
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7), // Light Amber
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        Text(
                          "$sks SKS",
                          style: const TextStyle(
                            color: Color(0xFFB45309), // Dark Amber
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Nama Matkul
              Text(
                namaMk,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B), // Slate 800
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              
              // Info Dosen & Ruangan
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded, size: 16, color: Color(0xFF3B82F6)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            namaDosen,
                            style: const TextStyle(
                              color: Color(0xFF475569), // Slate 600
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.meeting_room_rounded, size: 16, color: Color(0xFFA855F7)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Ruang: $ruangan",
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
