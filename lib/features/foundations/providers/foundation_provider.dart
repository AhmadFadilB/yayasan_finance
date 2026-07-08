import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/foundation_model.dart';
import '../services/foundation_service.dart';

// State untuk data Yayasan
class FoundationState {
  final List<FoundationModel> foundations;
  final FoundationModel? activeFoundation;
  final bool isLoading;
  final String? errorMessage;

  FoundationState({
    this.foundations = const [],
    this.activeFoundation,
    this.isLoading = false,
    this.errorMessage,
  });

  FoundationState copyWith({
    List<FoundationModel>? foundations,
    FoundationModel? activeFoundation,
    bool? isLoading,
    String? errorMessage,
    bool clearActive = false,
  }) {
    return FoundationState(
      foundations: foundations ?? this.foundations,
      activeFoundation: clearActive ? null : (activeFoundation ?? this.activeFoundation),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Provider untuk FoundationService
final foundationServiceProvider = Provider<FoundationService>((ref) {
  return FoundationService();
});

// StateNotifier untuk FoundationState
class FoundationNotifier extends StateNotifier<FoundationState> {
  final FoundationService _service;
  final Ref _ref;

  FoundationNotifier(this._service, this._ref) : super(FoundationState()) {
    // Dengarkan perubahan status auth. Jika user logout, reset state yayasan.
    _ref.listen(authProvider, (previous, next) {
      if (!next.isAuthenticated) {
        state = FoundationState();
      } else if (previous?.session?.user.id != next.session?.user.id) {
        // Jika user berganti, load ulang yayasan
        loadFoundations();
      }
    });

    // Jalankan load yayasan jika sudah login
    final auth = _ref.read(authProvider);
    if (auth.isAuthenticated) {
      loadFoundations();
    }
  }

  // Load daftar yayasan milik user aktif
  Future<void> loadFoundations() async {
    final auth = _ref.read(authProvider);
    if (auth.session == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _service.getFoundationsForUser(auth.session!.user.id);
      
      FoundationModel? active = state.activeFoundation;
      if (active != null) {
        // Update data activeFoundation dengan yang terbaru dari list
        final index = list.indexWhere((item) => item.id == active!.id);
        if (index != -1) {
          active = list[index];
        } else {
          active = null;
        }
      }

      state = state.copyWith(
        foundations: list,
        activeFoundation: active,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat yayasan: ${e.toString()}',
      );
    }
  }

  // Pilih yayasan aktif
  void selectFoundation(FoundationModel? foundation) {
    if (foundation == null) {
      state = state.copyWith(clearActive: true);
    } else {
      state = state.copyWith(activeFoundation: foundation);
    }
  }

  // Membuat yayasan baru
  Future<bool> createFoundation(String name, String? description) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newFoundation = await _service.createFoundation(
        name: name,
        description: description,
      );
      
      // Reload daftar yayasan agar sinkron dengan database
      await loadFoundations();
      
      // Pilih yayasan yang baru dibuat sebagai yayasan aktif
      final latestList = state.foundations;
      final match = latestList.firstWhere(
        (f) => f.id == newFoundation.id,
        orElse: () => newFoundation,
      );
      
      state = state.copyWith(
        activeFoundation: match,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal membuat yayasan: ${e.toString()}',
      );
      return false;
    }
  }

  // Mengundang anggota baru ke yayasan aktif
  Future<bool> addMember(String email, String role) async {
    final active = state.activeFoundation;
    if (active == null) {
      state = state.copyWith(errorMessage: 'Tidak ada yayasan aktif');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.addMemberByEmail(
        foundationId: active.id,
        email: email,
        role: role,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
      return false;
    }
  }
}

// Provider utama untuk mengelola yayasan
final foundationProvider = StateNotifierProvider<FoundationNotifier, FoundationState>((ref) {
  final service = ref.watch(foundationServiceProvider);
  return FoundationNotifier(service, ref);
});

// FutureProvider untuk memuat daftar anggota yayasan aktif
final foundationMembersProvider = FutureProvider.autoDispose<List<FoundationMemberModel>>((ref) async {
  final activeFoundation = ref.watch(foundationProvider).activeFoundation;
  if (activeFoundation == null) return [];
  
  final service = ref.watch(foundationServiceProvider);
  return service.getMembers(activeFoundation.id);
});
