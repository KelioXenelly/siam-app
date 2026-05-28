import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/auth/data/services/auth_service.dart';
import 'package:mobile/shared/widgets/dosen/bottom_nav.dart';
import 'package:mobile/shared/widgets/mahasiswa/glass_card.dart';

class DosenProfilePage extends StatefulWidget {
  const DosenProfilePage({super.key});

  @override
  State<DosenProfilePage> createState() => _DosenProfilePageState();
}

class _DosenProfilePageState extends State<DosenProfilePage> {
  final _currentIndex = 2;
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getMe();
      if (mounted) {
        setState(() {
          _user = user;
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

  Future<void> _uploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final updatedUser = await _authService.uploadAvatar(File(image.path));
        if (mounted) {
          setState(() {
            _user = updatedUser;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil berhasil diperbarui!')));
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))));
        }
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

            /// 🔵 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 50),
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

                  const Center(
                    child: Text(
                      "Profil Dosen",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  /// 👤 PROFILE INFO
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _isLoading ? null : _uploadAvatar,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                image: (_user?.avatar != null)
                                    ? DecorationImage(
                                        image: NetworkImage(ApiConstants.baseUrl.replaceAll('/api', '') + _user!.avatar!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: (_user?.avatar == null)
                                  ? Text(
                                      _user != null ? _getInitials(_user!.name) : "D",
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF4F46E5)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_isLoading)
                        const CircularProgressIndicator(color: Colors.white)
                      else
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _user?.name ?? "Nama Tidak Diketahui",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _user?.email ?? "-",
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "NIDN: ${_user?.identifier ?? '-'}",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              )
                            ],
                          ),
                        )
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// 🔥 CONTENT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [

                  /// 📋 INFO CARD
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    GlassCard(
                      child: Column(
                        children: [
                          _buildItem(Icons.person, "Nama Lengkap", _user?.name ?? "-"),
                          _divider(),
                          _buildItem(Icons.email, "Email", _user?.email ?? "-"),
                          _divider(),
                          _buildItem(Icons.badge, "NIDN", _user?.identifier ?? "-"),
                          _divider(),
                          _buildItem(Icons.person_outline, "Role", _user?.role ?? "-"),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  /// ⚙️ SETTINGS
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Pengaturan",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/ubah-password');
                    },
                    child: GlassCard(
                      child: Row(
                        children: const [
                          Icon(Icons.key, color: Colors.deepPurpleAccent),
                          SizedBox(width: 10),
                          Expanded(child: Text("Ubah Password")),
                          Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// 🔴 LOGOUT
                  GestureDetector(
                    onTap: () async {
                      await _authService.logout();

                      if (!context.mounted) return;

                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.red, Colors.redAccent],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "Logout",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// 🔹 ITEM BUILDER
  Widget _buildItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurpleAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1);
  }
}