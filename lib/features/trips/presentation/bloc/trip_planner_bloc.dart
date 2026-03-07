import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourism_app/features/trips/domain/entities/local_booking.dart';
import '../../domain/entities/booking.dart';
import '../../domain/usecases/trip_usecases.dart';
import '../../../../core/network/connectivity_service.dart';

// ════════════════════════════════════════════════════════════
//  ConnectivityCubit
// ════════════════════════════════════════════════════════════
class ConnectivityCubit extends Cubit<bool> {
  final ConnectivityService _service;
  StreamSubscription<bool>? _sub;

  ConnectivityCubit(this._service) : super(_service.isOnline) {
    _sub = _service.onConnectivityChanged.listen((online) {
      emit(online);
    });
  }

  bool get isOnline => state;

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

// ════════════════════════════════════════════════════════════
//  EVENTS
// ════════════════════════════════════════════════════════════
abstract class TripPlannerEvent extends Equatable {
  const TripPlannerEvent();
  @override
  List<Object?> get props => [];
}

class LoadTripPlannerEvent extends TripPlannerEvent {
  final String userId;
  const LoadTripPlannerEvent(this.userId);
  @override List<Object?> get props => [userId];
}

class RefreshTripPlannerEvent extends TripPlannerEvent {
  final String userId;
  const RefreshTripPlannerEvent(this.userId);
  @override List<Object?> get props => [userId];
}

class SyncOfflineEvent extends TripPlannerEvent {
  final String userId;
  const SyncOfflineEvent(this.userId);
  @override List<Object?> get props => [userId];
}

class FilterTripsEvent extends TripPlannerEvent {
  final TripFilter filter;
  const FilterTripsEvent(this.filter);
  @override List<Object?> get props => [filter];
}

class _BookingsUpdated extends TripPlannerEvent {
  final List<Booking> bookings;
  const _BookingsUpdated(this.bookings);
  @override List<Object?> get props => [bookings.length];
}

// ════════════════════════════════════════════════════════════
//  Filter Enum
// ════════════════════════════════════════════════════════════
enum TripFilter { all, upcoming, active, completed, cancelled }

extension TripFilterX on TripFilter {
  String nameAr(bool _) {
    switch (this) {
      case TripFilter.all:       return 'الكل';
      case TripFilter.upcoming:  return 'القادمة';
      case TripFilter.active:    return 'الجارية';
      case TripFilter.completed: return 'المكتملة';
      case TripFilter.cancelled: return 'الملغاة';
    }
  }
  String nameEn() {
    switch (this) {
      case TripFilter.all:       return 'All';
      case TripFilter.upcoming:  return 'Upcoming';
      case TripFilter.active:    return 'Active';
      case TripFilter.completed: return 'Completed';
      case TripFilter.cancelled: return 'Cancelled';
    }
  }
}

// ════════════════════════════════════════════════════════════
//  STATES
// ════════════════════════════════════════════════════════════
abstract class TripPlannerState extends Equatable {
  const TripPlannerState();
  @override List<Object?> get props => [];
}

class TripPlannerInitial extends TripPlannerState {}
class TripPlannerLoading extends TripPlannerState {}

class TripPlannerLoaded extends TripPlannerState {
  final List<Booking> allBookings;
  final List<TripDay> tripDays;
  final TripSummary summary;
  final TripFilter activeFilter;
  final bool isOffline;
  final bool isSyncing;
  final String? errorMessage;
  final DateTime? lastSync;

  const TripPlannerLoaded({
    required this.allBookings,
    required this.tripDays,
    required this.summary,
    this.activeFilter = TripFilter.all,
    this.isOffline = false,
    this.isSyncing = false,
    this.errorMessage,
    this.lastSync,
  });

  TripPlannerLoaded copyWith({
    List<Booking>? allBookings,
    List<TripDay>? tripDays,
    TripSummary? summary,
    TripFilter? activeFilter,
    bool? isOffline,
    bool? isSyncing,
    String? Function()? errorMessage,
    DateTime? lastSync,
  }) => TripPlannerLoaded(
    allBookings:  allBookings  ?? this.allBookings,
    tripDays:     tripDays     ?? this.tripDays,
    summary:      summary      ?? this.summary,
    activeFilter: activeFilter ?? this.activeFilter,
    isOffline:    isOffline    ?? this.isOffline,
    isSyncing:    isSyncing    ?? this.isSyncing,
    errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    lastSync:     lastSync     ?? this.lastSync,
  );

  @override
  List<Object?> get props =>
      [allBookings.length, activeFilter, isOffline, isSyncing, errorMessage];
}

class TripPlannerError extends TripPlannerState {
  final String message;
  final bool isOfflineError;
  const TripPlannerError(this.message, {this.isOfflineError = false});
  @override List<Object?> get props => [message];
}

// ════════════════════════════════════════════════════════════
//  BLOC
// ════════════════════════════════════════════════════════════
class TripPlannerBloc extends Bloc<TripPlannerEvent, TripPlannerState> {
  final GetBookings _getBookings;
  final WatchBookings _watchBookings;
  final SyncOfflineCache _syncCache;
  final GetTripSummary _getSummary;
  final ConnectivityService _connectivity;

  StreamSubscription<List<Booking>>? _bookingsSub;

  TripPlannerBloc({
    required GetBookings getBookings,
    required WatchBookings watchBookings,
    required SyncOfflineCache syncCache,
    required GetTripSummary getSummary,
    required ConnectivityService connectivity,
  })  : _getBookings   = getBookings,
        _watchBookings  = watchBookings,
        _syncCache      = syncCache,
        _getSummary     = getSummary,
        _connectivity   = connectivity,
        super(TripPlannerInitial()) {
    on<LoadTripPlannerEvent>(_onLoad);
    on<RefreshTripPlannerEvent>(_onRefresh);
    on<SyncOfflineEvent>(_onSync);
    on<FilterTripsEvent>(_onFilter);
    on<_BookingsUpdated>(_onBookingsUpdated);
  }

  // ── Load ────────────────────────────────────────
  Future<void> _onLoad(
    LoadTripPlannerEvent event,
    Emitter<TripPlannerState> emit,
  ) async {
    emit(TripPlannerLoading());

    final isOnline = await _connectivity.checkNow();

    // Subscribe to real-time stream
    await _bookingsSub?.cancel();
    _bookingsSub = _watchBookings(event.userId).listen(
      (bookings) => add(_BookingsUpdated(bookings)),
    );

    // Also fetch summary
    final summaryResult = await _getSummary(event.userId);
    final summary = summaryResult.fold((_) => const TripSummary(), (s) => s);

    final result = await _getBookings(event.userId);
    result.fold(
      (failure) {
        if (failure.isOfflineError) {
          emit(TripPlannerError(failure.message, isOfflineError: true));
        } else {
          emit(TripPlannerError(failure.message));
        }
      },
      (bookings) {
        emit(TripPlannerLoaded(
          allBookings: bookings,
          tripDays: _groupByDay(bookings),
          summary: summary,
          isOffline: !isOnline,
          lastSync: DateTime.now(),
        ));
      },
    );
  }

  // ── Refresh ─────────────────────────────────────
  Future<void> _onRefresh(
    RefreshTripPlannerEvent event,
    Emitter<TripPlannerState> emit,
  ) async {
    if (state is TripPlannerLoaded) {
      final current = state as TripPlannerLoaded;
      emit(current.copyWith(isSyncing: true));
    }

    final result = await _getBookings(event.userId);
    final summaryResult = await _getSummary(event.userId);
    final summary = summaryResult.fold((_) => const TripSummary(), (s) => s);

    result.fold(
      (failure) {
        if (state is TripPlannerLoaded) {
          emit((state as TripPlannerLoaded).copyWith(
            isSyncing: false,
            errorMessage: () => failure.message,
          ));
        }
      },
      (bookings) {
        final current = state is TripPlannerLoaded
            ? state as TripPlannerLoaded
            : null;
        emit(TripPlannerLoaded(
          allBookings: bookings,
          tripDays: _groupByDay(
            _applyFilter(bookings, current?.activeFilter ?? TripFilter.all),
          ),
          summary: summary,
          activeFilter: current?.activeFilter ?? TripFilter.all,
          isOffline: false,
          isSyncing: false,
          lastSync: DateTime.now(),
        ));
      },
    );
  }

  // ── Sync offline cache ──────────────────────────
  Future<void> _onSync(
    SyncOfflineEvent event,
    Emitter<TripPlannerState> emit,
  ) async {
    if (state is TripPlannerLoaded) {
      emit((state as TripPlannerLoaded).copyWith(isSyncing: true));
    }
    final result = await _syncCache(event.userId);
    result.fold(
      (f) {
        if (state is TripPlannerLoaded) {
          emit((state as TripPlannerLoaded).copyWith(
            isSyncing: false,
            errorMessage: () => f.message,
          ));
        }
      },
      (count) {
        if (state is TripPlannerLoaded) {
          emit((state as TripPlannerLoaded).copyWith(
            isSyncing: false,
            isOffline: false,
          ));
        }
      },
    );
  }

  // ── Filter ──────────────────────────────────────
  void _onFilter(FilterTripsEvent event, Emitter<TripPlannerState> emit) {
    if (state is! TripPlannerLoaded) return;
    final current = state as TripPlannerLoaded;
    final filtered = _applyFilter(current.allBookings, event.filter);
    emit(current.copyWith(
      activeFilter: event.filter,
      tripDays: _groupByDay(filtered),
    ));
  }

  // ── Stream update ───────────────────────────────
  void _onBookingsUpdated(
    _BookingsUpdated event,
    Emitter<TripPlannerState> emit,
  ) {
    if (state is TripPlannerLoaded) {
      final current = state as TripPlannerLoaded;
      final filtered = _applyFilter(event.bookings, current.activeFilter);
      emit(current.copyWith(
        allBookings: event.bookings,
        tripDays: _groupByDay(filtered),
      ));
    }
  }

  // ── Helpers ─────────────────────────────────────
  List<Booking> _applyFilter(List<Booking> bookings, TripFilter filter) {
    switch (filter) {
      case TripFilter.all:       return bookings;
      case TripFilter.upcoming:  return bookings.where((b) => b.isUpcoming && b.isConfirmed).toList();
      case TripFilter.active:    return bookings.where((b) => b.isActive).toList();
      case TripFilter.completed: return bookings.where((b) => b.status == BookingStatus.completed).toList();
      case TripFilter.cancelled: return bookings.where((b) => b.status == BookingStatus.cancelled).toList();
    }
  }

  List<TripDay> _groupByDay(List<Booking> bookings) {
    // Group by check-in date
    final Map<String, List<Booking>> grouped = {};
    for (final b in bookings) {
      final key = '${b.checkIn.year}-${b.checkIn.month}-${b.checkIn.day}';
      grouped.putIfAbsent(key, () => []).add(b);
    }

    return grouped.entries
        .map((e) {
          final parts = e.key.split('-');
          final date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          return TripDay(date: date, bookings: e.value);
        })
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<void> close() {
    _bookingsSub?.cancel();
    return super.close();
  }
}
