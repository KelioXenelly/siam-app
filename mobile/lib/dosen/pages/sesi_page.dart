import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:siam_mobile/dosen/services/dosen_service.dart';
import 'package:siam_mobile/core/api_constants.dart';
import 'package:siam_mobile/shared/glass_card.dart';

class DosenSesiPage extends StatefulWidget {
  final int pertemuanId;
  final int kelasId;
  final String namaMataKuliah;
  final String topikPertemuan;
  final String kodeKelas;
  final String semester;
  final String tahunAjaran;

  const DosenSesiPage({
    super.key,
    required this.pertemuanId,
    required this.kelasId,
    required this.namaMataKuliah,
    required this.topikPertemuan,
    required this.kodeKelas,
    required this.semester,
    required this.tahunAjaran,
  });

  @override
  State<DosenSesiPage> createState() => _DosenSesiPageState();
}

class _DosenSesiPageState extends State<DosenSesiPage> {
  final DosenService _dosenService = DosenService();
  
  bool _isLoading = true;
  String? _errorMessage;

  // Session state
  int? _sesiId;
  String? _qrData;
  DateTime? _expiredAt;
  bool _isClosed = false;
  List<dynamic> _attendances = [];
  
  // GPS Coordinates state
  double _lat = -6.200000;
  double _lng = 106.816666;
  bool _isMockGps = false;

  // Timers
  Timer? _countdownTimer;
  Timer? _pollingTimer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initSessionFlow();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  // 🔄 MAIN SESSION FLOW SETUP
  Future<void> _initSessionFlow() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Cek Sesi Aktif di Database terlebih dahulu
      final activeSesi = await _dosenService.getActiveSesi(widget.pertemuanId);
      
      if (activeSesi != null) {
        // 🔹 Sesi Absensi Aktif Ditemukan!
        final expiredAtStr = activeSesi['expired_at'] as String;
        final expiredDateTime = DateTime.parse(expiredAtStr).toLocal();
        
        if (mounted) {
          setState(() {
            _sesiId = activeSesi['id'];
            _qrData = jsonEncode({'token': activeSesi['qr_token']});
            _expiredAt = expiredDateTime;
            _isClosed = activeSesi['is_closed'] == 1 || activeSesi['is_closed'] == true;
            _lat = double.tryParse(activeSesi['latitude_dosen'].toString()) ?? -6.200000;
            _lng = double.tryParse(activeSesi['longitude_dosen'].toString()) ?? 106.816666;
            _isMockGps = false; // Memakai GPS yang tersimpan di DB
            _isLoading = false;
          });
        }
        
        if (!_isClosed) {
          _startTimers();
        }
        _loadAttendances();
      } else {
        // Cek apakah ada riwayat sesi (pertemuan sudah selesai)
        final allSesi = await _dosenService.getAllSesi(widget.pertemuanId);
        if (allSesi.isNotEmpty) {
          final lastSesi = allSesi.last;
          if (mounted) {
            setState(() {
              _sesiId = lastSesi['id'];
              _qrData = jsonEncode({'token': lastSesi['qr_token'] ?? ''});
              _isClosed = true; // Riwayat pasti sudah ditutup
              _isLoading = false;
            });
          }
          _loadAttendances();
        } else {
          // 🔹 Tidak Ada Sesi Aktif maupun Riwayat Sesi, Mari Dapatkan Koordinat & Buat Baru!
          await _fetchCoordinatesAndGenerateQR();
        }
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

  // 🗺️ GET GPS & GENERATE NEW QR
  Future<void> _fetchCoordinatesAndGenerateQR() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    // Ambil Koordinat GPS
    final gpsData = await _getCurrentLocation();
    _lat = gpsData['lat']!;
    _lng = gpsData['lng']!;
    _isMockGps = gpsData['mocked'] == 1.0;

    try {
      final response = await _dosenService.generateQR(widget.pertemuanId, _lat, _lng);
      
      if (response['success'] == true) {
        final data = response['data'];
        final expiredAtStr = data['expired_at'] as String;
        final expiredDateTime = DateTime.parse(expiredAtStr).toLocal();

        // Ambil ID sesi dengan memanggil getActiveSesi kembali
        final activeSesi = await _dosenService.getActiveSesi(widget.pertemuanId);

        if (mounted) {
          setState(() {
            _sesiId = activeSesi != null ? activeSesi['id'] : null;
            _qrData = data['qr_data'];
            _expiredAt = expiredDateTime;
            _isClosed = false;
            _isLoading = false;
          });
        }
        
        _startTimers();
        if (_sesiId != null) {
          _loadAttendances();
        }
        
        _showSuccessSnackbar(_isMockGps 
          ? "Sesi dimulai menggunakan Mock GPS default (Emulator)."
          : "Sesi presensi dimulai dengan GPS aktif!"
        );
      } else {
        throw Exception(response['message'] ?? 'Gagal mengenerate sesi QR.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  // 🕒 START TICKING & POLLING TIMERS
  void _startTimers() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();

    if (_expiredAt == null || _isClosed) return;

    // 1. Countdown Timer (Every 1 second)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.isAfter(_expiredAt!)) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _timeLeft = Duration.zero;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _timeLeft = _expiredAt!.difference(now);
          });
        }
      }
    });

    // 2. Real-time Student Check-in Polling (Every 5 seconds)
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadAttendances();
    });
  }

  // 👥 LOAD ATTENDANCES LOG FROM DATABASE
  Future<void> _loadAttendances() async {
    if (_sesiId == null) return;
    try {
      final list = await _dosenService.getSesiAbsensi(_sesiId!);
      if (mounted) {
        setState(() {
          _attendances = list;
        });
      }
    } catch (e) {
      debugPrint("Error loading attendances polling: $e");
    }
  }

  // 📡 GEOLOCATOR HELPER WITH FAILSAFE
  Future<Map<String, double>> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions denied.';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 4),
      );
      
      return {
        'lat': position.latitude,
        'lng': position.longitude,
        'mocked': 0.0,
      };
    } catch (e) {
      // Mock Fallback
      debugPrint("GPS Retrieval failed: $e. Using default ITB SS coordinates.");
      return {
        'lat': -6.229728, // ITB Stikom Ambon / Mock Center
        'lng': 106.829498,
        'mocked': 1.0,
      };
    }
  }

  // 📝 MANUAL ATTENDANCE ADJUSTMENT
  Future<void> _updateStatusManual(int absensiId, String targetStatus) async {
    Navigator.pop(context); // Close dialog
    setState(() {
      _isLoading = true;
    });

    try {
      final ok = await _dosenService.updateStatusManual(absensiId, targetStatus.toLowerCase());
      if (ok) {
        _showSuccessSnackbar("Status kehadiran mahasiswa berhasil diupdate!");
        await _loadAttendances();
      }
    } catch (e) {
      _showErrorDialog(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 🔒 CLOSE ATTENDANCE SESSION
  Future<void> _closeSesiFlow() async {
    if (_sesiId == null) return;
    
    // Konfirmasi dialog
    final confirm = await _showConfirmDialog(
      title: "Tutup Sesi Presensi",
      content: "Apakah Anda yakin ingin menutup sesi scan QR? Sisa mahasiswa terdaftar yang belum scan akan otomatis dicatat sebagai ALFA.",
      actionLabel: "Tutup Sekarang",
      actionColor: Colors.red,
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final ok = await _dosenService.closeSesi(_sesiId!);
      if (ok) {
        _countdownTimer?.cancel();
        _pollingTimer?.cancel();
        
        setState(() {
          _isClosed = true;
          _timeLeft = Duration.zero;
        });

        _showSuccessSnackbar("Sesi presensi ditutup. Status mahasiswa terakumulasi!");
        await _loadAttendances();
      }
    } catch (e) {
      _showErrorDialog(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 🏁 END THE CLASS MEETING COMPLETELY
  Future<void> _endPertemuanFlow() async {
    // Konfirmasi dialog
    final confirm = await _showConfirmDialog(
      title: "Akhiri Pertemuan Kelas",
      content: "Apakah Anda yakin kelas sudah selesai? Pertemuan ini akan diberi status 'Selesai' di sistem.",
      actionLabel: "Akhiri Kelas",
      actionColor: Colors.blueAccent,
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Otomatis close sesi jika masih terbuka
      if (!_isClosed && _sesiId != null) {
        await _dosenService.closeSesi(_sesiId!);
      }

      // 2. End pertemuan
      final res = await _dosenService.endPertemuan(widget.pertemuanId);
      
      if (res['success'] == true) {
        if (mounted) {
          _countdownTimer?.cancel();
          _pollingTimer?.cancel();
          
          Navigator.pop(context, true); // Balik ke kelas_detail_page dan trigger refresh
          _showSuccessSnackbar("Kelas berhasil diakhiri. Sampai jumpa di sesi berikutnya!");
        }
      }
    } catch (e) {
      _showErrorDialog(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 🔹 REGENERATE QR METHOD
  Future<void> _regenerateQRFlow() async {
    final confirm = await _showConfirmDialog(
      title: "Regenerate QR Presensi",
      content: "Membuat QR baru akan mengatur ulang masa kedaluwarsa presensi kembali ke 10 menit. Lanjutkan?",
      actionLabel: "Generate Baru",
      actionColor: Colors.purple,
    );

    if (confirm != true) return;

    await _fetchCoordinatesAndGenerateQR();
  }

  // 🕒 MINUTES & SECONDS CONVERTER
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final hasQrExpired = _timeLeft == Duration.zero && _expiredAt != null;
    final totalHadir = _attendances.where((a) {
      final st = a['status']?.toString().toLowerCase() ?? '';
      return st == 'hadir' || st == 'terlambat';
    }).length;
    final progressVal = _timeLeft.inSeconds > 0 && _expiredAt != null
        ? _timeLeft.inSeconds / 600.0 // 10 menit = 600 detik
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _initSessionFlow,
            color: const Color(0xFF7C3AED),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                
                // 🔵 PREMIUM HEADER SECTION
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
                          
                          // Row Back Button & GPS Indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
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
                              
                              // GPS pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isMockGps 
                                    ? Colors.orangeAccent.withValues(alpha: 0.25) 
                                    : Colors.greenAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _isMockGps ? Colors.orangeAccent.withValues(alpha: 0.5) : Colors.greenAccent.withValues(alpha: 0.5), 
                                    width: 1
                                  )
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isMockGps ? Icons.location_searching_rounded : Icons.gps_fixed_rounded, 
                                      color: Colors.white, 
                                      size: 14
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isMockGps ? "Mock GPS Active" : "GPS Lock: OK",
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                              )
                            ],
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
                            "${widget.topikPertemuan} • ${widget.kodeKelas} (${widget.tahunAjaran})",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w500),
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

                const SizedBox(height: 24),

                // 📲 ACTIVE QR CARD
                if (_qrData != null && !_isClosed && !hasQrExpired)
                  _buildActiveQrCard(progressVal)
                else if (_isClosed || hasQrExpired)
                  _buildClosedOrExpiredCard(hasQrExpired)
                else if (_errorMessage != null)
                  _buildErrorCard()
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),

                const SizedBox(height: 24),

                // 👥 LIVE PARTICIPANTS HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Daftar Kehadiran Mahasiswa",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                      
                      // Live pill count
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "$totalHadir Hadir",
                          style: const TextStyle(
                            color: Colors.blueAccent, 
                            fontWeight: FontWeight.bold,
                            fontSize: 12
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 📋 STUDENT LIST
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStudentList(),
                ),

                const SizedBox(height: 120), // Bottom navigation clearance
              ],
            ),
          ),
          ),

          // ❄️ GLASS ACTION FOOTER
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActionBar(),
          ),

          // LOADING OVERLAY
          if (_isLoading)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
        ],
      ),
    );
  }

  // 🔹 WIDGET: ACTIVE QR CARD
  Widget _buildActiveQrCard(double progressVal) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                "SILAKAN SCAN UNTUK ABSENSI",
                style: TextStyle(
                  fontWeight: FontWeight.w800, 
                  color: Color(0xFF7C3AED), 
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // QR CODE IMAGE
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]
                ),
                child: QrImageView(
                  data: _qrData!,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // TIMER COUNTDOWN ROW
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        value: progressVal,
                        strokeWidth: 3,
                        backgroundColor: Colors.red.withValues(alpha: 0.2),
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text("QR berlaku hingga: ", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      _formatDuration(_timeLeft),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.red, fontSize: 16),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 WIDGET: CLOSED OR EXPIRED QR CARD
  Widget _buildClosedOrExpiredCard(bool hasQrExpired) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (_isClosed ? Colors.red : Colors.orange).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isClosed ? Icons.lock_rounded : Icons.timer_off_rounded,
                  color: _isClosed ? Colors.red : Colors.orange,
                  size: 50,
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                _isClosed ? "SESI PRESENSI DITUTUP" : "QR CODE EXPIRED",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                _isClosed 
                  ? "Sesi absen QR telah diakhiri. Sisa mahasiswa yang belum presensi dicatat Alfa."
                  : "Batas waktu 10 menit presensi habis. Anda dapat memperbarui masa aktif QR di bawah.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, height: 1.5),
              ),
              
              if (!_isClosed && hasQrExpired) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _regenerateQRFlow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Generate QR Baru", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 WIDGET: ERROR STATE CARD
  Widget _buildErrorCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 50),
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage ?? "Terjadi kesalahan",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initSessionFlow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: const Text("Coba Lagi", style: TextStyle(fontWeight: FontWeight.w800)),
              )
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 WIDGET: SHOW IMAGE DIALOG
  void _showImageDialog(String imageUrl, String studentName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(40),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("Gagal memuat gambar", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  studentName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 WIDGET: STUDENT Kehadiran LIST
  Widget _buildStudentList() {
    if (_attendances.isEmpty) {
      return GlassCard(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          child: const Center(
            child: Column(
              children: [
                Icon(Icons.people_alt_rounded, color: Color(0xFFCBD5E1), size: 50),
                SizedBox(height: 16),
                Text("Belum ada mahasiswa yang masuk kelas.", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: _attendances.map((item) {
        final mahasiswa = item['mahasiswa'] ?? {};
        final user = mahasiswa['user'] ?? {};
        final name = user['name'] ?? 'Mahasiswa Unknown';
        final nim = mahasiswa['nim'] ?? '-';
        String rawStatus = item['status']?.toString() ?? 'alfa';
        final status = rawStatus.isNotEmpty 
            ? rawStatus[0].toUpperCase() + rawStatus.substring(1).toLowerCase() 
            : 'Alfa';
        
        String checkInTime = '--:--';
        if (item['waktu_absen'] != null) {
          try {
            final dt = DateTime.parse(item['waktu_absen'].toString()).toLocal();
            checkInTime = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
          } catch (_) {
            checkInTime = '--:--';
          }
        }

        final selfiePath = item['selfie_photo']?.toString();
        final selfieUrl = selfiePath != null && selfiePath.isNotEmpty
            ? ApiConstants.baseUrl.replaceAll('/api', '/storage/') + selfiePath
            : null;

        // Styling pills
        Color pillBg = Colors.red.withValues(alpha: 0.1);
        Color pillText = Colors.red;
        
        if (status == 'Hadir') {
          pillBg = Colors.green.withValues(alpha: 0.1);
          pillText = Colors.green;
        } else if (status == 'Terlambat' || status == 'Izin') {
          pillBg = Colors.orange.withValues(alpha: 0.1);
          pillText = Colors.orange;
        } else if (status == 'Sakit') {
          pillBg = Colors.purple.withValues(alpha: 0.1);
          pillText = Colors.purple;
        }

        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';

        return GestureDetector(
          onTap: () {
            _showManualStatusDialog(item['id'], name, status);
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: pillText, width: 4)),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    
                    // Avatar
                    selfieUrl != null
                      ? GestureDetector(
                          onTap: () => _showImageDialog(selfieUrl, name),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: NetworkImage(selfieUrl),
                          ),
                        )
                      : CircleAvatar(
                          radius: 24,
                          backgroundColor: pillText.withValues(alpha: 0.15),
                          child: Text(
                            initial,
                            style: TextStyle(color: pillText, fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                        ),
                    
                    const SizedBox(width: 16),
                    
                    // Name & Check-in details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "NIM $nim • $checkInTime WIB",
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: pillText, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 🔹 WIDGET: BOTTOM GLASS BAR
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            
            // TUTUP SESI ABSENSI
            if (!_isClosed) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _closeSesiFlow,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.lock_outline_rounded),
                  label: const Text("Tutup Absensi", style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 16),
            ],
            
            // AKHIRI KELAS
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                child: ElevatedButton.icon(
                  onPressed: _endPertemuanFlow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: const Text("Akhiri Kelas", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 DIALOG: MANUAL STATUS ADJUSTMENT
  void _showManualStatusDialog(int absensiId, String name, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            "Ubah Presensi: $name",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogStatusTile(absensiId, "Hadir", currentStatus, Colors.green),
              _dialogStatusTile(absensiId, "Terlambat", currentStatus, Colors.orange),
              _dialogStatusTile(absensiId, "Izin", currentStatus, Colors.blue),
              _dialogStatusTile(absensiId, "Sakit", currentStatus, Colors.purple),
              _dialogStatusTile(absensiId, "Alfa", currentStatus, Colors.red),
            ],
          ),
        );
      },
    );
  }

  Widget _dialogStatusTile(int absensiId, String status, String current, Color color) {
    final active = status == current;
    return ListTile(
      onTap: () {
        _updateStatusManual(absensiId, status);
      },
      leading: Icon(
        active ? Icons.radio_button_checked : Icons.radio_button_off,
        color: color,
      ),
      title: Text(
        status,
        style: TextStyle(fontWeight: active ? FontWeight.bold : FontWeight.normal, color: color),
      ),
      trailing: active 
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: const Text("Aktif", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          )
        : null,
    );
  }

  // 🔹 CONFIRM DIALOG HELPER
  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String actionLabel,
    required Color actionColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(actionLabel),
            )
          ],
        );
      },
    );
  }

  // 🔹 SNACKBAR HELPERS
  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Gagal", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text("OK"),
            )
          ],
        );
      },
    );
  }
}
