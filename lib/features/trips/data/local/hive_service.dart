import 'package:hive_flutter/hive_flutter.dart';
import 'hive_booking_model.dart';

// ════════════════════════════════════════════════════════════
//  HiveService  –  manages Hive initialization & boxes
// ════════════════════════════════════════════════════════════
class HiveService {
  static const _bookingsBox = 'bookings_cache';
  static const _metaBox     = 'cache_meta';

  static bool _initialized = false;

  // ── Initialize Hive ────────────────────────────
  static Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(BookingHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(BookingLocationAdapter());
    }

    // Open boxes
    await Hive.openBox<BookingHiveModel>(_bookingsBox);
    await Hive.openBox<dynamic>(_metaBox);

    _initialized = true;
  }

  // ── Box accessors ──────────────────────────────
  static Box<BookingHiveModel> get bookingsBox =>
      Hive.box<BookingHiveModel>(_bookingsBox);

  static Box<dynamic> get metaBox =>
      Hive.box<dynamic>(_metaBox);

  // ── Cache management ───────────────────────────
  static Future<void> saveBooking(BookingHiveModel model) async {
    await bookingsBox.put(model.id, model);
    await _updateLastSync();
  }

  static Future<void> saveBookings(List<BookingHiveModel> models) async {
    final map = {for (final m in models) m.id: m};
    await bookingsBox.putAll(map);
    await _updateLastSync();
  }

  static List<BookingHiveModel> getBookingsForUser(String userId) {
    return bookingsBox.values
        .where((b) => b.userId == userId)
        .toList()
      ..sort((a, b) => a.checkIn.compareTo(b.checkIn));
  }

  static BookingHiveModel? getBookingById(String id) =>
      bookingsBox.get(id);

  static Future<void> deleteBooking(String id) async =>
      await bookingsBox.delete(id);

  static Future<void> clearUserBookings(String userId) async {
    final keys = bookingsBox.keys
        .where((k) => bookingsBox.get(k)?.userId == userId)
        .toList();
    await bookingsBox.deleteAll(keys);
  }

  static Future<void> clearAll() async {
    await bookingsBox.clear();
    await metaBox.clear();
  }

  // ── Sync metadata ──────────────────────────────
  static Future<void> _updateLastSync() async =>
      await metaBox.put('last_sync', DateTime.now().millisecondsSinceEpoch);

  static DateTime? get lastSyncTime {
    final ms = metaBox.get('last_sync') as int?;
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  static bool get isStale {
    final last = lastSyncTime;
    if (last == null) return true;
    return DateTime.now().difference(last).inMinutes > 30;
  }

  static int get cachedBookingCount => bookingsBox.length;

  // ── Close ─────────────────────────────────────
  static Future<void> close() async {
    await Hive.close();
    _initialized = false;
  }
}
