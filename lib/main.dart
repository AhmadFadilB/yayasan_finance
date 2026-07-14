import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

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
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Yayasan Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
