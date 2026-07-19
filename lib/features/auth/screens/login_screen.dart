import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/app_logo.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_card.dart';
import '../providers/auth_provider.dart';

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
            backgroundColor: AppTheme.colorSuccess,
          ),
        );
        if (context.mounted) {
          try {
            context.pop();
          } catch (_) {
            // Redirect will handle if it cannot pop
          }
        }
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
                color: AppTheme.primaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(64.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Unified branding logo mark in white
                      const AppLogo(size: 72, color: Colors.white),
                      const SizedBox(height: 24),
                      Text(
                        'Yayasan Finance',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aplikasi Manajemen Keuangan Transparan dan Akuntabel untuk Masa Depan Yayasan yang Lebih Baik.',
                        style: GoogleFonts.inter(
                          fontSize: 16,
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
              color: AppTheme.backgroundColor,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AppCard(
                      padding: const EdgeInsets.all(28.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo untuk Mobile
                            if (!isDesktop) ...[
                              const Center(
                                child: AppLogo(size: 64),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Yayasan Finance',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                            
                            Text(
                              'Selamat Datang',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Masuk menggunakan akun Anda untuk mengelola keuangan yayasan.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textLight,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Error Alert jika ada
                            if (authState.errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.colorError.withAlpha(26),
                                  borderRadius: AppRadius.radiusSm,
                                  border: Border.all(color: AppTheme.colorError.withAlpha(51)),
                                ),
                                child: Text(
                                  authState.errorMessage!,
                                  style: GoogleFonts.inter(
                                    color: AppTheme.colorError,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
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

                          // Tombol Login menggunakan AppButton
                          AppButton(
                            text: 'Masuk',
                            style: AppButtonStyle.primary,
                            isLoading: authState.isLoading,
                            onPressed: authState.isLoading ? null : _handleLogin,
                          ),
                          const SizedBox(height: 24),

                          // Link Register
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Belum memiliki akun? ',
                                style: GoogleFonts.inter(color: AppTheme.textLight),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.push('/register');
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
          ),
        ],
      ),
    );
  }
}
