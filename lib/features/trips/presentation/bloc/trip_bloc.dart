import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/local_booking.dart';
import '../../domain/repositories/trip_repository.dart';

// ════════════════════════════════════════════════════════════
//  EVENTS
// ════════════════════════════════════════════════════════════
abstract class TripEvent extends Equatable {
  const TripEvent();
  @override
  List<Object?> get props => [];
}

class InitTripsEvent extends TripEvent {
  final String userId;
  const InitTripsEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class SyncTripsEvent extends TripEvent {
  final String userId;
  const SyncTripsEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class _BookingsUpdated extends TripEvent {
  final List<LocalBooking> bookings;
  const _BookingsUpdated(this.bookings);
  @override
  List<Object?> get props => [bookings];
}

class _ConnectivityChanged extends TripEvent {
  final bool isOnline;
  const _ConnectivityChanged(this.isOnline);
  @override
  List<Object?> get props => [isOnline];
}

class SelectTabEvent extends TripEvent {
  final int tabIndex;
  const SelectTabEvent(this.tabIndex);
  @override
  List<Object?> get props => [tabIndex];
}

class DeleteBookingEvent extends TripEvent {
  final String bookingId;
  const DeleteBookingEvent(this.bookingId);
  @override
  List<Object?> get props => [bookingId];
}

class RefreshTripsEvent extends TripEvent {
  final String userId;
  const RefreshTripsEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

// ════════════════════════════════════════════════════════════
//  STATES
// ════════════════════════════════════════════════════════════
abstract class TripState extends Equatable {
  const TripState();
  @override
  List<Object?> get props => [];
}

class TripInitial extends TripState {}

class TripLoading extends TripState {}

class TripLoaded extends TripState {
  final List<LocalBooking> allBookings;
  final TripStats stats;
  final int selectedTab;        // 0=upcoming, 1=ongoing, 2=completed
  final bool isOnline;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  const TripLoaded({
    required this.allBookings,
    required this.stats,
    this.selectedTab    = 0,
    this.isOnline       = true,
    this.isSyncing      = false,
    this.lastSyncTime,
    this.errorMessage,
  });

  // ── Filtered getters ──────────────────────────
  List<LocalBooking> get upcomingBookings =>
      allBookings.where((b) => b.isUpcoming).toList()
        ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

  List<LocalBooking> get ongoingBookings =>
      allBookings.where((b) => b.isOngoing).toList()
        ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

  List<LocalBooking> get completedBookings =>
      allBookings.where((b) => b.isCompleted || b.isCancelled).toList()
        ..sort((a, b) => b.checkOut.compareTo(a.checkOut));

  List<LocalBooking> get currentTabBookings {
    switch (selectedTab) {
      case 0: return upcomingBookings;
      case 1: return ongoingBookings;
      case 2: return completedBookings;
      default: return upcomingBookings;
    }
  }

  // ── Unsync'd bookings needing upload ──────────
  List<LocalBooking> get pendingSyncBookings =>
      allBookings.where((b) => !b.isSyncedToCloud).toList();

  TripLoaded copyWith({
    List<LocalBooking>? allBookings,
    TripStats? stats,
    int? selectedTab,
    bool? isOnline,
    bool? isSyncing,
    DateTime? lastSyncTime,
    String? Function()? errorMessage,
  }) =>
      TripLoaded(
        allBookings:  allBookings   ?? this.allBookings,
        stats:        stats         ?? this.stats,
        selectedTab:  selectedTab   ?? this.selectedTab,
        isOnline:     isOnline      ?? this.isOnline,
        isSyncing:    isSyncing     ?? this.isSyncing,
        lastSyncTime: lastSyncTime  ?? this.lastSyncTime,
        errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      );

  @override
  List<Object?> get props =>
      [allBookings, stats, selectedTab, isOnline, isSyncing, lastSyncTime, errorMessage];
}

class TripError extends TripState {
  final String message;
  const TripError(this.message);
  @override
  List<Object?> get props => [message];
}

// ════════════════════════════════════════════════════════════
//  BLOC
// ════════════════════════════════════════════════════════════
class TripBloc extends Bloc<TripEvent, TripState> {
  final TripRepository _repository;
  final Connectivity _connectivity;

  StreamSubscription<List<LocalBooking>>? _bookingSub;
  StreamSubscription<List<ConnectivityResult>>? _connectSub;

  TripBloc({
    required TripRepository repository,
    Connectivity? connectivity,
  })  : _repository   = repository,
        _connectivity = connectivity ?? Connectivity(),
        super(TripInitial()) {
    on<InitTripsEvent>(_onInit);
    on<SyncTripsEvent>(_onSync);
    on<_BookingsUpdated>(_onBookingsUpdated);
    on<_ConnectivityChanged>(_onConnectivity);
    on<SelectTabEvent>(_onSelectTab);
    on<DeleteBookingEvent>(_onDelete);
    on<RefreshTripsEvent>(_onRefresh);
  }

  // ── Init ─────────────────────────────────────────
  Future<void> _onInit(InitTripsEvent event, Emitter<TripState> emit) async {
    emit(TripLoading());

    // 1. Check initial connectivity
    final conn = await _connectivity.checkConnectivity();
    final isOnline = conn.any((r) => r != ConnectivityResult.none);

    // 2. Subscribe to local Hive stream
    await _bookingSub?.cancel();
    _bookingSub = _repository.watchAllBookings(event.userId).listen(
          (bookings) => add(_BookingsUpdated(bookings)),
    );

    // 3. Subscribe to connectivity changes
    await _connectSub?.cancel();
    _connectSub = _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      add(_ConnectivityChanged(online));
    }) as StreamSubscription<List<ConnectivityResult>>?;

    // 4. Sync (loads mock data first time, or local cache)
    add(SyncTripsEvent(event.userId));
  }

  // ── Sync from cloud ───────────────────────────────
  Future<void> _onSync(SyncTripsEvent event, Emitter<TripState> emit) async {
    if (state is TripLoaded) {
      emit((state as TripLoaded).copyWith(isSyncing: true));
    }

    final result = await _repository.syncFromCloud(event.userId);
    result.fold(
          (failure) {
        if (state is TripLoaded) {
          emit((state as TripLoaded).copyWith(
            isSyncing: false,
            errorMessage: () => failure.message,
          ));
        }
      },
          (_) {
        if (state is TripLoaded) {
          emit((state as TripLoaded).copyWith(
            isSyncing: false,
            lastSyncTime: DateTime.now(),
          ));
        }
      },
    );
  }

  // ── Handle Hive stream update ─────────────────────
  Future<void> _onBookingsUpdated(
      _BookingsUpdated event, Emitter<TripState> emit) async {
    final stats = TripStats.fromBookings(event.bookings);
    final conn = await _connectivity.checkConnectivity();
    final isOnline = conn.any((r) => r != ConnectivityResult.none);

    if (state is TripLoaded) {
      emit((state as TripLoaded).copyWith(
        allBookings: event.bookings,
        stats: stats,
        isOnline: isOnline,
      ));
    } else {
      emit(TripLoaded(
        allBookings: event.bookings,
        stats: stats,
        isOnline: isOnline,
        lastSyncTime: DateTime.now(),
      ));
    }
  }

  // ── Connectivity change ───────────────────────────
  void _onConnectivity(
      _ConnectivityChanged event, Emitter<TripState> emit) {
    if (state is TripLoaded) {
      emit((state as TripLoaded).copyWith(isOnline: event.isOnline));
    }
  }

  // ── Select tab ────────────────────────────────────
  void _onSelectTab(SelectTabEvent event, Emitter<TripState> emit) {
    if (state is TripLoaded) {
      emit((state as TripLoaded).copyWith(selectedTab: event.tabIndex));
    }
  }

  // ── Delete ────────────────────────────────────────
  Future<void> _onDelete(
      DeleteBookingEvent event, Emitter<TripState> emit) async {
    await _repository.deleteBooking(event.bookingId);
    // stream will auto-update
  }

  // ── Refresh (pull-to-refresh) ─────────────────────
  Future<void> _onRefresh(
      RefreshTripsEvent event, Emitter<TripState> emit) async {
    add(SyncTripsEvent(event.userId));
  }

  @override
  Future<void> close() {
    _bookingSub?.cancel();
    _connectSub?.cancel();
    return super.close();
  }
}

extension ConnectivityResultExtension on ConnectivityResult {

  bool get hasConnection {
    return this != ConnectivityResult.none;
  }

  bool any(bool Function(ConnectivityResult) test) {
    return test(this);
  }
}
