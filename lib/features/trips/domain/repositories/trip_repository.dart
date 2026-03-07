import 'package:dartz/dartz.dart';
import '../entities/local_booking.dart';
import '../entities/booking.dart';

abstract class TripRepository {
  // ── LocalBooking (Hive offline) ───────────────
  Future<Either<TripFailure, List<LocalBooking>>> getAllBookings(String userId);
  Future<Either<TripFailure, LocalBooking>> getBookingById(String bookingId);
  Stream<List<LocalBooking>> watchAllBookings(String userId);
  Future<Either<TripFailure, Unit>> saveBooking(LocalBooking booking);
  Future<Either<TripFailure, Unit>> saveAllBookings(List<LocalBooking> bookings);
  Future<Either<TripFailure, Unit>> updateBookingStatus(String bookingId, BookingStatus status);
  Future<Either<TripFailure, Unit>> deleteBooking(String bookingId);
  Future<Either<TripFailure, Unit>> clearAllBookings();
  Future<Either<TripFailure, List<LocalBooking>>> syncFromCloud(String userId);
  Future<Either<TripFailure, TripStats>> getStats(String userId);

  // ── Booking (Firestore/remote) ────────────────
  Future<Either<TripFailure, List<Booking>>> getBookings(String userId);
  Stream<List<Booking>> watchBookings(String userId);
  Future<Either<TripFailure, List<Booking>>> getCachedBookings(String userId);

  // ── Summary & Sync ────────────────────────────
  Future<Either<TripFailure, TripSummary>> getTripSummary(String userId);
  Future<Either<TripFailure, int>> syncOfflineCache(String userId);
}