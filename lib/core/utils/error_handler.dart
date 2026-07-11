class ErrorHandler {
  static String formatError(Object error) {
    final errStr = error.toString();

    // Deteksi error koneksi internet lambat / bermasalah
    if (errStr.contains('SocketException') ||
        errStr.contains('ClientException') ||
        errStr.contains('Failed to fetch') ||
        errStr.contains('AuthRetryableFetchException') ||
        errStr.contains('NetworkRequestFailed') ||
        errStr.contains('Connection failed') ||
        errStr.contains('Connection timed out') ||
        errStr.contains('connection refused') ||
        errStr.contains('HandshakeException')) {
      return 'Koneksi internet lambat atau bermasalah. Silakan periksa koneksi Anda dan coba lagi.';
    }

    // Deteksi error autentikasi Supabase
    if (errStr.contains('Invalid login credentials')) {
      return 'Email atau kata sandi salah. Silakan coba lagi.';
    }
    if (errStr.contains('Email not confirmed')) {
      return 'Email Anda belum dikonfirmasi. Silakan periksa kotak masuk email Anda.';
    }
    if (errStr.contains('User already registered') || errStr.contains('already exists')) {
      return 'Email ini sudah terdaftar. Silakan masuk atau gunakan email lain.';
    }

    // Deteksi database row-level security / izin akses ditolak
    if (errStr.contains('row-level security') || errStr.contains('permission denied')) {
      return 'Akses ditolak. Anda tidak memiliki izin untuk melakukan tindakan ini.';
    }

    // Bersihkan prefix teknis Exception / AuthException / PostgrestException dll.
    String cleanMsg = errStr;
    if (cleanMsg.startsWith('Exception: ')) {
      cleanMsg = cleanMsg.substring('Exception: '.length);
    } else if (cleanMsg.startsWith('Exception')) {
      cleanMsg = cleanMsg.substring('Exception'.length);
    }

    // Ganti class name exception (misal: AuthException: xxxx -> xxxx)
    cleanMsg = cleanMsg.replaceAll(RegExp(r'^[a-zA-Z]+Exception:\s*'), '');

    return cleanMsg;
  }
}
