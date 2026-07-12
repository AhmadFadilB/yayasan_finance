import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/error_handler.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';

// State untuk daftar proyek
class ProjectState {
  final List<ProjectModel> projects;
  final bool isLoading;
  final String? errorMessage;

  ProjectState({
    this.projects = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ProjectState copyWith({
    List<ProjectModel>? projects,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProjectState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Provider untuk ProjectService
final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService();
});

// StateNotifier untuk mengelola proyek
class ProjectNotifier extends StateNotifier<ProjectState> {
  final ProjectService _service;
  final Ref _ref;

  ProjectNotifier(this._service, this._ref) : super(ProjectState()) {
    // Dengarkan perubahan yayasan aktif. Jika berganti, load ulang proyek.
    _ref.listen(foundationProvider, (previous, next) {
      if (next.activeFoundation != null) {
        loadProjects(next.activeFoundation!.id);
      } else {
        state = ProjectState();
      }
    });

    // Inisialisasi awal jika ada yayasan aktif
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    if (activeFoundation != null) {
      loadProjects(activeFoundation.id);
    }
  }

  // Memuat daftar proyek dari database
  Future<void> loadProjects(String foundationId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _service.getProjects(foundationId);
      state = state.copyWith(
        projects: list,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat proyek: ${ErrorHandler.formatError(e)}',
      );
    }
  }

  // Menambahkan proyek baru
  Future<bool> addProject({
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    required String status,
    bool isPublic = false,
    double targetAmount = 0.0,
  }) async {
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    if (activeFoundation == null) {
      state = state.copyWith(errorMessage: 'Tidak ada yayasan aktif.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newProj = ProjectModel(
        id: '', // Di-generate otomatis oleh DB
        foundationId: activeFoundation.id,
        name: name,
        description: description,
        startDate: startDate,
        endDate: endDate,
        status: status,
        isPublic: isPublic,
        targetAmount: targetAmount,
        createdAt: DateTime.now(),
      );

      await _service.createProject(newProj);
      await loadProjects(activeFoundation.id);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menambahkan proyek: ${ErrorHandler.formatError(e)}',
      );
      return false;
    }
  }

  // Mengupdate proyek yang sudah ada
  Future<bool> updateProject({
    required String id,
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    required String status,
    bool isPublic = false,
    double targetAmount = 0.0,
  }) async {
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    if (activeFoundation == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final proj = ProjectModel(
        id: id,
        foundationId: activeFoundation.id,
        name: name,
        description: description,
        startDate: startDate,
        endDate: endDate,
        status: status,
        isPublic: isPublic,
        targetAmount: targetAmount,
        createdAt: DateTime.now(), // Diabaikan oleh DB update
      );

      await _service.updateProject(proj);
      await loadProjects(activeFoundation.id);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memperbarui proyek: ${ErrorHandler.formatError(e)}',
      );
      return false;
    }
  }

  // Menghapus proyek
  Future<bool> deleteProject(String projectId) async {
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    if (activeFoundation == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.deleteProject(projectId);
      await loadProjects(activeFoundation.id);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menghapus proyek: ${ErrorHandler.formatError(e)}',
      );
      return false;
    }
  }
}

// Provider utama untuk project state
final projectProvider = StateNotifierProvider<ProjectNotifier, ProjectState>((ref) {
  final service = ref.watch(projectServiceProvider);
  return ProjectNotifier(service, ref);
});

// Provider kombinasi untuk menghitung secara reaktif total keuangan masing-masing proyek
final projectsWithFinanceProvider = Provider<List<ProjectModel>>((ref) {
  final projects = ref.watch(projectProvider).projects;
  final transactions = ref.watch(transactionProvider).transactions;

  return projects.map((project) {
    double totalIncome = 0;
    double totalExpense = 0;

    // Filter transaksi yang terkait dengan proyek ini
    final projectTxs = transactions.where((tx) => tx.projectId == project.id && tx.status == 'approved');
    for (var tx in projectTxs) {
      if (tx.isIncome) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }

    return project.copyWith(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  }).toList();
});
