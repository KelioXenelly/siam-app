import 'package:flutter/material.dart';
import 'package:mobile/features/auth/data/services/auth_service.dart';
import 'package:mobile/shared/widgets/mahasiswa/glass_card.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;
  String _role = 'mahasiswa';

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_identifierController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Email/ID dan Password tidak boleh kosong"),
          backgroundColor: Colors.amber[800],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(
          _identifierController.text,
          _passwordController.text
      );

      if (!mounted) return;

      if (user.role != _role) {
        try {
          await _authService.logout();
        } catch (_) {}

        final formattedRole = user.role[0].toUpperCase() + user.role.substring(1);
        throw Exception("Akun Anda terdaftar sebagai $formattedRole. Silakan pilih tab yang sesuai.");
      }

      if (user.role == 'mahasiswa') {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (user.role == 'dosen') {
        Navigator.pushReplacementNamed(context, '/dosen/dashboard');
      }
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFFEFF6FF)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GlassCard(
                  child: Column(
                    children: [
                      Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "S", 
                            style: TextStyle(
                              fontSize: 48, 
                              fontWeight: FontWeight.w900, 
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4)
                              ]
                            )
                          )
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Selamat Datang", 
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)
                      ),
                      const Text(
                        "SIAM - Sistem Absensi Pintar", 
                        style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)
                      ),
                      const SizedBox(height: 32),

                      Container(
                        height: 50,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100], 
                          borderRadius: BorderRadius.circular(16)
                        ),
                        child: Stack(
                          children: [
                            AnimatedAlign(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              alignment: _role == 'mahasiswa' ? Alignment.centerLeft : Alignment.centerRight,
                              child: Container(
                                width: (MediaQuery.of(context).size.width - 100) / 2,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                _buildRoleTab("mahasiswa", "Mahasiswa"),
                                _buildRoleTab("dosen", "Dosen"),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      _buildLabel(_role == 'mahasiswa' ? 'Email / NIM' : 'Email / NIDN'),
                      TextField(
                        controller: _identifierController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          _role == 'mahasiswa' ? 'Contoh: 23110001' : 'Contoh: nidn@kampus.ac.id',
                          Icons.person_outline
                        ),
                      ),
                      const SizedBox(height: 18),

                      _buildLabel('Password'),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLogin(),
                        decoration: _inputDecoration('••••••••', Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureText = !_obscureText),
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)
                          ),
                          child: const Text("Lupa Password?"),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                                )
                              : const Text(
                                  "Masuk Sekarang", 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "© 2026 ITB STIKOM BALI",
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String value, String label) {
    bool isSelected = _role == value;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _role = value),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isSelected ? Colors.blue[700] : Colors.grey[500],
              fontWeight: FontWeight.bold,
              fontSize: 14
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft, 
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4), 
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey[800], fontSize: 13))
      )
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: Colors.grey[50],
      prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), 
        borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5)
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), 
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8)
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}