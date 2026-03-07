import 'package:dartz/dartz.dart';
import '../entities/local_booking.dart';
import '../entities/booking.dart';
import '../repositories/trip_repository.dart';

// ── LocalBooking usecases ─────────────────────────────────
class GetAllBookings {
  final TripRepository repo;
  GetAllBookings(this.repo);
  Future<Either<TripFailure, List<LocalBooking>>> call(String userId) =>
      repo.getAllBookings(userId);
}

class SaveBooking {
  final TripRepository repo;
  SaveBooking(this.repo);
  Future<Either<TripFailure, Unit>> call(LocalBooking booking) =>
      repo.saveBooking(booking);
}

class UpdateBookingStatus {
  final TripRepository repo;
  UpdateBookingStatus(this.repo);
  Future<Either<TripFailure, Unit>> call(String bookingId, BookingStatus status) =>
      repo.updateBookingStatus(bookingId, status);
}

class DeleteBooking {
  final TripRepository repo;
  DeleteBooking(this.repo);
  Future<Either<TripFailure, Unit>> call(String bookingId) =>
      repo.deleteBooking(bookingId);
}

class SyncFromCloud {
  final TripRepository repo;
  SyncFromCloud(this.repo);
  Future<Either<TripFailure, List<LocalBooking>>> call(String userId) =>
      repo.syncFromCloud(userId);
}

class GetStats {
  final TripRepository repo;
  GetStats(this.repo);
  Future<Either<TripFailure, TripStats>> call(String userId) =>
      repo.getStats(userId);
}

// ── Booking (remote) usecases ─────────────────────────────
class GetBookings {
  final TripRepository repo;
  GetBookings(this.repo);
  Future<Either<TripFailure, List<Booking>>> call(String userId) =>
      repo.getBookings(userId);
}

class WatchBookings {
  final TripRepository repo;
  WatchBookings(this.repo);
  Stream<List<Booking>> call(String userId) => repo.watchBookings(userId);
}

class GetCachedBookings {
  final TripRepository repo;
  GetCachedBookings(this.repo);
  Future<Either<TripFailure, List<Booking>>> call(String userId) =>
      repo.getCachedBookings(userId);
}

// ── Summary & Sync ────────────────────────────────────────
class GetTripSummary {
  final TripRepository repo;
  GetTripSummary(this.repo);
  Future<Either<TripFailure, TripSummary>> call(String userId) =>
      repo.getTripSummary(userId);
}

class SyncOfflineCache {
  final TripRepository repo;
  SyncOfflineCache(this.repo);
  Future<Either<TripFailure, int>> call(String userId) =>
      repo.syncOfflineCache(userId);
}

class GetBookingById {
  final TripRepository repo;
  GetBookingById(this.repo);
  Future<Either<TripFailure, LocalBooking>> call(String bookingId) =>
      repo.getBookingById(bookingId);
}