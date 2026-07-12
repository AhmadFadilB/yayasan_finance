import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/screens/main_navigation_screen.dart';
import 'features/foundations/providers/foundation_provider.dart';
import 'features/foundations/screens/foundation_select_screen.dart';
import 'features/projects/screens/public_project_detail_screen.dart';
import 'features/projects/screens/public_project_feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Memuat konfigurasi Environment (.env)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Peringatan: File .env tidak ditemukan, menggunakan nilai bawaan.');
  }

  // 2. Inisialisasi Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://your-project-id.supabase.co';
  final supabasePublishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? 
      dotenv.env['SUPABASE_ANON_KEY'] ?? 
      'your-supabase-publishable-key';

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  // 3. Inisialisasi format tanggal lokal Indonesia (id_ID) untuk intl package
  await initializeDateFormatting('id_ID', null);

  runApp(
    const ProviderScope(
      child: YayasanFinanceApp(),
    ),
  );
}

class YayasanFinanceApp extends ConsumerWidget {
  const YayasanFinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final foundationState = ref.watch(foundationProvider);

    return MaterialApp(
      title: 'Yayasan Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _getHomeScreen(authState, foundationState),
      onGenerateRoute: (settings) {
        final name = settings.name;
        if (name != null && name.contains('/public/project')) {
          final uri = Uri.parse(name);
          final projectId = uri.queryParameters['id'];
          if (projectId != null && projectId.isNotEmpty) {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => PublicProjectDetailScreen(projectId: projectId),
            );
          }
        }
        return null;
      },
    );
  }

  // Pengendali Alur Routing Reaktif
  Widget _getHomeScreen(AuthState authState, FoundationState foundationState) {
    // 0. Interseptor URL Publik (Bypass Auth untuk Crowdfunding)
    final uri = Uri.base;
    final isPublicProjectRoute = uri.path.contains('/public/project') || uri.fragment.contains('/public/project');
    if (isPublicProjectRoute) {
      String? projectId;
      if (uri.path.contains('/public/project')) {
        projectId = uri.queryParameters['id'];
      } else if (uri.fragment.contains('/public/project')) {
        final fragmentUri = Uri.parse(uri.fragment);
        projectId = fragmentUri.queryParameters['id'];
      }
      if (projectId != null && projectId.isNotEmpty) {
        return PublicProjectDetailScreen(projectId: projectId);
      }
    }

    // A. Jika belum masuk/login, tampilkan halaman Feed Proyek Publik (Kickstarter-like)
    if (!authState.isAuthenticated) {
      return const PublicProjectFeedScreen();
    }

    // B. Jika sudah masuk, pastikan data profil terisi sebelum memproses yayasan
    if (authState.profile == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat profil Anda...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // C. Jika sudah login tetapi belum memilih yayasan aktif (atau yayasan null),
    // tampilkan halaman pemilihan/pembuatan yayasan
    if (foundationState.activeFoundation == null) {
      return const FoundationSelectScreen();
    }

    // D. Jika sudah login dan memiliki yayasan aktif, masuk ke aplikasi utama
    return const MainNavigationScreen();
  }
}
