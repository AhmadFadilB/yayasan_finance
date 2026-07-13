import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil masuk!'),
            backgroundColor: Color(0xFF0D5C46),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      body: Row(
        children: [
          // Banner Kiri untuk layar lebar (Desktop/Tablet)
          if (isDesktop)
            Expanded(
              child: Container(
                color: const Color(0xFF0D5C46),
                child: Padding(
                  padding: const EdgeInsets.all(64.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        size: 72,
                        color: Color(0xFF2EC4B6),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Yayasan Finance',
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aplikasi Manajemen Keuangan Transparan dan Akuntabel untuk Masa Depan Yayasan yang Lebih Baik.',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Form Login Kanan / Tengah
          Expanded(
            child: Container(
              color: const Color(0xFFF7FBF9),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo untuk Mobile
                          if (!isDesktop) ...[
                            const Icon(
                              Icons.account_balance_wallet,
                              size: 64,
                              color: Color(0xFF0D5C46),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Yayasan Finance',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0D5C46),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                          
                          Text(
                            'Selamat Datang',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A2A25),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Masuk menggunakan akun Anda untuk mengelola keuangan yayasan.',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: const Color(0xFF6B7F79),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Error Alert jika ada
                          if (authState.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFEF9A9A)),
                              ),
                              child: Text(
                                authState.errorMessage!,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFC62828),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Field Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Alamat Email',
                              prefixIcon: Icon(Icons.email_outlined),
                              hintText: 'admin@yayasan.org',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Alamat email tidak boleh kosong';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Field Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            decoration: InputDecoration(
                              labelText: 'Kata Sandi',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kata sandi tidak boleh kosong';
                              }
                              if (value.length < 6) {
                                return 'Kata sandi minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Tombol Login
                          ElevatedButton(
                            onPressed: authState.isLoading ? null : _handleLogin,
                            child: authState.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Masuk'),
                          ),
                          const SizedBox(height: 24),

                          // Link Register
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Belum memiliki akun? ',
                                style: GoogleFonts.outfit(color: const Color(0xFF6B7F79)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  );
                                },
                                child: const Text('Daftar Sekarang'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
