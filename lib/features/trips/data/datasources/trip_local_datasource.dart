import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/local_booking.dart';
import '../models/hive_booking.dart';

// ════════════════════════════════════════════════════════════
//  Abstract
// ════════════════════════════════════════════════════════════
abstract class TripLocalDataSource {
  Future<List<LocalBooking>> getAllBookings(String userId);
  Future<LocalBooking?> getBookingById(String bookingId);
  Stream<List<LocalBooking>> watchBookings(String userId);
  Future<void> saveBooking(LocalBooking booking);
  Future<void> saveAllBookings(List<LocalBooking> bookings);
  Future<void> updateStatus(String bookingId, BookingStatus status);
  Future<void> deleteBooking(String bookingId);
  Future<void> clearAll();
  Future<bool> hasBookings(String userId);
}

// ════════════════════════════════════════════════════════════
//  Implementation
// ════════════════════════════════════════════════════════════
class TripLocalDataSourceImpl implements TripLocalDataSource {
  Box<HiveBooking> get _box => Hive.box<HiveBooking>(HiveBoxNames.bookings);

  // ── Helpers ─────────────────────────────────────
  String _key(String bookingId) => 'booking_$bookingId';

  // ── Read ────────────────────────────────────────
  @override
  Future<List<LocalBooking>> getAllBookings(String userId) async {
    return _box.values
        .where((h) => h.userId == userId)
        .map((h) => h.toDomain())
        .toList()
      ..sort((a, b) => b.checkIn.compareTo(a.checkIn));
  }

  @override
  Future<LocalBooking?> getBookingById(String bookingId) async {
    final h = _box.get(_key(bookingId));
    return h?.toDomain();
  }

  @override
  Stream<List<LocalBooking>> watchBookings(String userId) {
    // Hive's built-in watch + map to domain
    final controller = StreamController<List<LocalBooking>>.broadcast();

    // Emit immediately
    Future.microtask(() async {
      if (!controller.isClosed) {
        controller.add(await getAllBookings(userId));
      }
    });

    // Listen to box changes
    final sub = _box.watch().listen((_) async {
      if (!controller.isClosed) {
        controller.add(await getAllBookings(userId));
      }
    });

    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  // ── Write ────────────────────────────────────────
  @override
  Future<void> saveBooking(LocalBooking booking) async {
    await _box.put(_key(booking.id), HiveBooking.fromDomain(booking));
  }

  @override
  Future<void> saveAllBookings(List<LocalBooking> bookings) async {
    final map = {
      for (final b in bookings) _key(b.id): HiveBooking.fromDomain(b)
    };
    await _box.putAll(map);
  }

  @override
  Future<void> updateStatus(
      String bookingId, BookingStatus status) async {
    final key = _key(bookingId);
    final existing = _box.get(key);
    if (existing != null) {
      existing.statusKey = status.name;
      existing.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
      await existing.save();
    }
  }

  @override
  Future<void> deleteBooking(String bookingId) async {
    await _box.delete(_key(bookingId));
  }

  @override
  Future<void> clearAll() async {
    await _box.clear();
  }

  @override
  Future<bool> hasBookings(String userId) async {
    return _box.values.any((h) => h.userId == userId);
  }
}

// ════════════════════════════════════════════════════════════
//  MOCK DATA SEED  –  Rich sample bookings for demo/offline
// ════════════════════════════════════════════════════════════
class TripMockDataSeeder {
  static List<LocalBooking> generateMockBookings(String userId) {
    final now = DateTime.now();

    return [
      // ── 1. Upcoming Hotel ──────────────────────────
      LocalBooking(
        id:               'booking_001',
        confirmationCode: 'TRV-2026-001234',
        userId:           userId,
        serviceId:        'hotel_burj_001',
        serviceName:      'Burj Al Arab Jumeirah',
        serviceNameAr:    'برج العرب جميرا',
        serviceType:      BookingServiceType.hotel,
        partnerName:      'Jumeirah Group',
        partnerNameAr:    'مجموعة جميرا',
        checkIn:          now.add(const Duration(days: 12)),
        checkOut:         now.add(const Duration(days: 17)),
        bookedAt:         now.subtract(const Duration(days: 2)),
        guest:            const BookingGuest(name: 'Ahmed Ali', adults: 2, children: 1),
        totalPrice:       6315.0,
        serviceFee:       300.71,
        currency:         'USD',
        city:             'Dubai',
        cityAr:           'دبي',
        address:          'Jumeirah St, Umm Suqeim 3, Dubai, UAE',
        latitude:         25.1412,
        longitude:        55.1852,
        coverImageUrl:    'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800',
        status:           BookingStatus.upcoming,
        qrData: LocalBooking.buildQrData(
          id:               'booking_001',
          confirmationCode: 'TRV-2026-001234',
          serviceName:      'Burj Al Arab Jumeirah',
          checkIn:          now.add(const Duration(days: 12)),
          checkOut:         now.add(const Duration(days: 17)),
          guests:           3,
          totalPrice:       6315.0,
          currency:         'USD',
        ),
        extras: {'stars': 7, 'room_type': 'Deluxe Suite', 'room_type_ar': 'جناح ديلوكس', 'floor': 25},
        isSyncedToCloud: true,
        lastSyncedAt:    now.subtract(const Duration(days: 2)),
        updatedAt:       now.subtract(const Duration(days: 2)),
      ),

      // ── 2. Ongoing Travel Package ──────────────────
      LocalBooking(
        id:               'booking_002',
        confirmationCode: 'TRV-2026-002891',
        userId:           userId,
        serviceId:        'pkg_maldives_001',
        serviceName:      'Maldives Paradise Package',
        serviceNameAr:    'باقة جنة المالديف',
        serviceType:      BookingServiceType.travelPackage,
        partnerName:      'Al Nujoom Travel Agency',
        partnerNameAr:    'وكالة النجوم للسفر',
        checkIn:          now.subtract(const Duration(days: 2)),
        checkOut:         now.add(const Duration(days: 5)),
        bookedAt:         now.subtract(const Duration(days: 14)),
        guest:            const BookingGuest(name: 'Sara Mohamed', adults: 2),
        totalPrice:       4998.0,
        serviceFee:       249.9,
        currency:         'USD',
        city:             'Malé',
        cityAr:           'ماليه',
        address:          'North Malé Atoll, Maldives',
        latitude:         4.1755,
        longitude:        73.5093,
        coverImageUrl:    'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?w=800',
        status:           BookingStatus.ongoing,
        qrData: LocalBooking.buildQrData(
          id:               'booking_002',
          confirmationCode: 'TRV-2026-002891',
          serviceName:      'Maldives Paradise Package',
          checkIn:          now.subtract(const Duration(days: 2)),
          checkOut:         now.add(const Duration(days: 5)),
          guests:           2,
          totalPrice:       4998.0,
          currency:         'USD',
        ),
        extras: {'duration_days': 7, 'includes': 'Flights, Hotel, Meals, Snorkeling', 'includes_ar': 'طيران وفندق ووجبات وغطس'},
        isSyncedToCloud: true,
        lastSyncedAt:    now.subtract(const Duration(days: 14)),
        updatedAt:       now.subtract(const Duration(days: 14)),
      ),

      // ── 3. Upcoming Tour Guide ─────────────────────
      LocalBooking(
        id:               'booking_003',
        confirmationCode: 'TRV-2026-003445',
        userId:           userId,
        serviceId:        'guide_japan_001',
        serviceName:      'Tokyo Hidden Gems Tour',
        serviceNameAr:    'جولة كنوز طوكيو الخفية',
        serviceType:      BookingServiceType.tourGuide,
        partnerName:      'Japan Explorer Guides',
        partnerNameAr:    'مرشدو اليابان المستكشفون',
        checkIn:          now.add(const Duration(days: 30)),
        checkOut:         now.add(const Duration(days: 33)),
        bookedAt:         now.subtract(const Duration(days: 5)),
        guest:            const BookingGuest(name: 'Omar Hassan', adults: 4, children: 2),
        totalPrice:       1280.0,
        serviceFee:       64.0,
        currency:         'USD',
        city:             'Tokyo',
        cityAr:           'طوكيو',
        address:          'Shinjuku, Tokyo, Japan',
        latitude:         35.6762,
        longitude:        139.6503,
        coverImageUrl:    'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800',
        status:           BookingStatus.upcoming,
        qrData: LocalBooking.buildQrData(
          id:               'booking_003',
          confirmationCode: 'TRV-2026-003445',
          serviceName:      'Tokyo Hidden Gems Tour',
          checkIn:          now.add(const Duration(days: 30)),
          checkOut:         now.add(const Duration(days: 33)),
          guests:           6,
          totalPrice:       1280.0,
          currency:         'USD',
        ),
        extras: {'guide_name': 'Yuki Tanaka', 'language': 'Arabic & English', 'meeting_point': 'Shinjuku Station West Exit'},
        isSyncedToCloud: false, // not synced - demo offline scenario
        lastSyncedAt:    now.subtract(const Duration(days: 5)),
        updatedAt:       now.subtract(const Duration(hours: 2)),
      ),

      // ── 4. Completed Hotel ─────────────────────────
      LocalBooking(
        id:               'booking_004',
        confirmationCode: 'TRV-2025-009871',
        userId:           userId,
        serviceId:        'hotel_paris_001',
        serviceName:      'Le Meurice Paris',
        serviceNameAr:    'لو موريس باريس',
        serviceType:      BookingServiceType.hotel,
        partnerName:      'Dorchester Collection',
        partnerNameAr:    'دورشستر كولكشن',
        checkIn:          now.subtract(const Duration(days: 45)),
        checkOut:         now.subtract(const Duration(days: 40)),
        bookedAt:         now.subtract(const Duration(days: 60)),
        guest:            const BookingGuest(name: 'Fatima Al-Rashid', adults: 2),
        totalPrice:       3900.0,
        serviceFee:       195.0,
        currency:         'EUR',
        city:             'Paris',
        cityAr:           'باريس',
        address:          '228 Rue de Rivoli, 75001 Paris, France',
        latitude:         48.8656,
        longitude:        2.3296,
        coverImageUrl:    'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=800',
        status:           BookingStatus.completed,
        qrData: LocalBooking.buildQrData(
          id:               'booking_004',
          confirmationCode: 'TRV-2025-009871',
          serviceName:      'Le Meurice Paris',
          checkIn:          now.subtract(const Duration(days: 45)),
          checkOut:         now.subtract(const Duration(days: 40)),
          guests:           2,
          totalPrice:       3900.0,
          currency:         'EUR',
        ),
        extras: {'stars': 5, 'room_type': 'Classic Room', 'room_type_ar': 'غرفة كلاسيك', 'review_submitted': true},
        isSyncedToCloud: true,
        lastSyncedAt:    now.subtract(const Duration(days: 40)),
        updatedAt:       now.subtract(const Duration(days: 40)),
      ),

      // ── 5. Completed Package ───────────────────────
      LocalBooking(
        id:               'booking_005',
        confirmationCode: 'TRV-2025-007632',
        userId:           userId,
        serviceId:        'pkg_bali_001',
        serviceName:      'Bali Spiritual Retreat',
        serviceNameAr:    'رحلة بالي الروحانية',
        serviceType:      BookingServiceType.travelPackage,
        partnerName:      'Island Dreams',
        partnerNameAr:    'أحلام الجزيرة',
        checkIn:          now.subtract(const Duration(days: 90)),
        checkOut:         now.subtract(const Duration(days: 83)),
        bookedAt:         now.subtract(const Duration(days: 110)),
        guest:            const BookingGuest(name: 'Ahmed Ali', adults: 2, children: 0),
        totalPrice:       3465.0,
        serviceFee:       173.25,
        currency:         'USD',
        city:             'Bali',
        cityAr:           'بالي',
        address:          'Ubud, Bali, Indonesia',
        latitude:         -8.5069,
        longitude:        115.2625,
        coverImageUrl:    'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800',
        status:           BookingStatus.completed,
        qrData: LocalBooking.buildQrData(
          id:               'booking_005',
          confirmationCode: 'TRV-2025-007632',
          serviceName:      'Bali Spiritual Retreat',
          checkIn:          now.subtract(const Duration(days: 90)),
          checkOut:         now.subtract(const Duration(days: 83)),
          guests:           2,
          totalPrice:       3465.0,
          currency:         'USD',
        ),
        extras: {'duration_days': 7, 'includes': 'Villa, Yoga, Cooking Class', 'includes_ar': 'فيلا ويوغا ودرس طبخ'},
        isSyncedToCloud: true,
        lastSyncedAt:    now.subtract(const Duration(days: 83)),
        updatedAt:       now.subtract(const Duration(days: 83)),
      ),
    ];
  }
}
