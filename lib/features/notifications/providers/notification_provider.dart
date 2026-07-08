import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../../auth/providers/auth_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final int unreadCount;
  final NotificationModel? lastNewNotification; // Untuk memicu banner in-app di UI

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.unreadCount = 0,
    this.lastNewNotification,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    int? unreadCount,
    NotificationModel? lastNewNotification,
    bool clearLastNew = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      unreadCount: unreadCount ?? this.unreadCount,
      lastNewNotification: clearLastNew ? null : (lastNewNotification ?? this.lastNewNotification),
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;
  final Ref _ref;
  StreamSubscription<List<NotificationModel>>? _subscription;

  NotificationNotifier(this._service, this._ref) : super(NotificationState()) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      final userId = next.session?.user.id;
      if (userId != null) {
        _subscribeToNotifications(userId);
      } else {
        _unsubscribe();
      }
    }, fireImmediately: true);
  }

  void _subscribeToNotifications(String userId) {
    _unsubscribe();
    state = state.copyWith(isLoading: true);

    _subscription = _service.streamNotifications(userId).listen((list) {
      NotificationModel? recentNew;
      
      // Deteksi jika ada notifikasi baru masuk yang belum dibaca (unread)
      if (state.notifications.isNotEmpty) {
        final oldIds = state.notifications.map((n) => n.id).toSet();
        final newUnread = list.where((n) => !n.isRead && !oldIds.contains(n.id)).toList();
        
        if (newUnread.isNotEmpty) {
          // Ambil notifikasi teranyar untuk ditampilkan di banner UI
          recentNew = newUnread.first;
        }
      }

      final unread = list.where((n) => !n.isRead).length;
      state = NotificationState(
        notifications: list,
        isLoading: false,
        unreadCount: unread,
        lastNewNotification: recentNew,
      );
    }, onError: (err) {
      state = state.copyWith(isLoading: false);
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
    state = NotificationState();
  }

  // Membersihkan notifikasi baru terakhir setelah ditampilkan di banner UI
  void clearLastNewNotification() {
    state = state.copyWith(clearLastNew: true);
  }

  Future<void> markAsRead(String id) async {
    try {
      await _service.markAsRead(id);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final authState = _ref.read(authProvider);
    final userId = authState.session?.user.id;
    if (userId == null) return;
    try {
      await _service.markAllAsRead(userId);
    } catch (_) {}
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationNotifier(service, ref);
});
