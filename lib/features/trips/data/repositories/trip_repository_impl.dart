import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:tourism_app/features/trips/presentation/bloc/trip_bloc.dart';
import '../../domain/entities/local_booking.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_local_datasource.dart';

class TripRepositoryImpl implements TripRepository {
  final TripLocalDataSource _local;
  final Connectivity _connectivity;

  TripRepositoryImpl({
    required TripLocalDataSource local,
    Connectivity? connectivity,
  })  : _local = local,
        _connectivity = connectivity ?? Connectivity();

  Future<bool> get _isOnline async {
    final r = await _connectivity.checkConnectivity();
    return r.any((c) => c != ConnectivityResult.none);
  }

  // ── LocalBooking ──────────────────────────────
  @override
  Future<Either<TripFailure, List<LocalBooking>>> getAllBookings(String userId) async {
    try { return Right(await _local.getAllBookings(userId)); }
    catch (e) { return Left(TripFailure('فشل تحميل الحجوزات: $e')); }
  }

  @override
  Future<Either<TripFailure, LocalBooking>> getBookingById(String bookingId) async {
    try {
      final b = await _local.getBookingById(bookingId);
      return b != null ? Right(b) : const Left(TripFailure('الحجز غير موجود'));
    } catch (e) { return Left(TripFailure('$e')); }
  }

  @override
  Stream<List<LocalBooking>> watchAllBookings(String userId) =>
      _local.watchBookings(userId);

  @override
  Future<Either<TripFailure, Unit>> saveBooking(LocalBooking booking) async {
    try { await _local.saveBooking(booking); return const Right(unit); }
    catch (e) { return Left(TripFailure('$e')); }
  }

  @override
  Future<Either<TripFailure, Unit>> saveAllBookings(List<LocalBooking> bookings) async {
    try { await _local.saveAllBookings(bookings); return const Right(unit); }
    catch (e) { return Left(TripFailure('$e')); }
  }

  @override
  Future<Either<TripFailure, Unit>> updateBookingStatus(
      String bookingId, BookingStatus status) async {
    try { await _local.updateStatus(bookingId, status); return const Right(unit); }
    catch (e) { return Left(TripFailure('$e')); }
  }

  @override
  Future<Either<TripFailure, Unit>> deleteBooking(String bookingId) async {
    try { await _local.deleteBooking(bookingId); return const Right(unit); }
    catch (e) { return Left(TripFailure('$e')); }
  }

  @override
  Future<Either<TripFailure, Unit>> clearAllBookings() async {
    try { await _local.clearAll(); return const Right(unit); }
    catch (e) { return Left(TripFailure('$e')); }
  }

  @override
  Future<Either<TripFailure, List<LocalBooking>>> syncFromCloud(String userId) async {
    try {
      final online = await _isOnline;
      if (!online) return Right(await _local.getAllBookings(userId));
      final hasLocal = await _local.hasBookings(userId);
      if (!hasLocal) {
        final mocks = TripMockDataSeeder.generateMockBookings(userId);
        await _local.saveAllBookings(mocks);
        return Right(mocks);
      }
      return Right(await _local.getAllBookings(userId));
    } catch (e) { return Left(TripFailure('فشل المزامنة: $e')); }
  }

  @override
  Future<Either<TripFailure, TripStats>> getStats(String userId) async {
    try {
      final b = await _local.getAllBookings(userId);
      return Right(TripStats.fromBookings(b));
    } catch (e) { return Left(TripFailure('$e')); }
  }

  // ── Booking (remote mock) ─────────────────────
  @override
  Future<Either<TripFailure, List<Booking>>> getBookings(String userId) async {
    // TODO: استبدل بـ Firestore عند الإنتاج
    return const Right([]);
  }

  @override
  Stream<List<Booking>> watchBookings(String userId) {
    return Stream.value([]);
  }

  @override
  Future<Either<TripFailure, List<Booking>>> getCachedBookings(String userId) async {
    return const Right([]);
  }

  // ── Summary & Sync ────────────────────────────
  @override
  Future<Either<TripFailure, TripSummary>> getTripSummary(String userId) async {
    try {
      final bookings = await _local.getAllBookings(userId);
      final stats = TripStats.fromBookings(bookings);
      return Right(TripSummary(
        totalBookings:     stats.totalTrips,
        upcomingBookings:  stats.upcomingCount,
        completedBookings: stats.completedCount,
        totalSpent:        stats.totalSpent,
        countriesVisited:  stats.totalDestinations,
      ));
    } catch (e) { return Left(TripFailure('$e')); }
  }

  @override
  Future<Either<TripFailure, int>> syncOfflineCache(String userId) async {
    try {
      final result = await syncFromCloud(userId);
      return result.fold(
            (f) => Left(f),
            (bookings) => Right(bookings.length),
      );
    } catch (e) { return Left(TripFailure('$e')); }
  }
}