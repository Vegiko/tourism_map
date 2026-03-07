import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourism_app/features/trips/domain/entities/local_booking.dart';
import '../../domain/entities/booking.dart';

// ════════════════════════════════════════════════════════════
//  Interface
// ════════════════════════════════════════════════════════════
abstract class TripRemoteDataSource {
  Future<List<Booking>> getBookings(String userId);
  Stream<List<Booking>> watchBookings(String userId);
  Future<Booking?> getBookingById(String bookingId);
}

// ════════════════════════════════════════════════════════════
//  Firestore Implementation
// ════════════════════════════════════════════════════════════
class TripRemoteDataSourceImpl implements TripRemoteDataSource {
  final FirebaseFirestore _firestore;

  static const _collection = 'bookings';

  TripRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _bookings => _firestore.collection(_collection);

  @override
  Future<List<Booking>> getBookings(String userId) async {
    final snap = await _bookings
        .where('traveler_id', isEqualTo: userId)
        .orderBy('check_in', descending: false)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Stream<List<Booking>> watchBookings(String userId) {
    return _bookings
        .where('traveler_id', isEqualTo: userId)
        .orderBy('check_in', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  @override
  Future<Booking?> getBookingById(String bookingId) async {
    final doc = await _bookings.doc(bookingId).get();
    if (!doc.exists) return null;
    return _fromDoc(doc);
  }

  Booking _fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // Parse location
    final locData = d['location'] as Map<String, dynamic>? ?? {};
    final location = BookingLocation.fromJson(locData);

    // Parse image URLs
    final imageUrls = List<String>.from(d['image_urls'] as List? ?? []);

    // QR data — encode booking essentials as JSON
    final qrData = d['qr_data'] as String? ??
        jsonEncode({
          'id': doc.id,
          'code': d['confirmation_code'] ?? doc.id.substring(0, 8).toUpperCase(),
          'service': d['service_name'] ?? '',
          'check_in': _parseTs(d['check_in']).toIso8601String(),
          'check_out': _parseTs(d['check_out']).toIso8601String(),
          'guests': d['guests'] ?? 1,
        });

    return Booking(
      id: doc.id,
      userId: d['traveler_id'] as String? ?? '',
      partnerId: d['partner_id'] as String? ?? '',
      serviceId: d['service_id'] as String? ?? '',
      serviceType: BookingServiceTypeX.fromString(d['service_type'] as String? ?? 'hotel'),
      status: BookingStatusX.fromString(d['status'] as String? ?? 'confirmed'),
      serviceName: d['service_name'] as String? ?? '',
      serviceNameAr: d['service_name_ar'] as String? ?? '',
      providerName: d['provider_name'] as String? ?? '',
      providerNameAr: d['provider_name_ar'] as String? ?? '',
      primaryImageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
      imageUrls: imageUrls,
      checkIn: _parseTs(d['check_in']),
      checkOut: _parseTs(d['check_out']),
      guests: d['guests'] as int? ?? 1,
      rooms: d['rooms'] as int? ?? 1,
      totalPrice: (d['total_price'] as num?)?.toDouble() ?? 0,
      currency: d['currency'] as String? ?? 'USD',
      confirmationCode: d['confirmation_code'] as String? ??
          doc.id.substring(0, 8).toUpperCase(),
      qrData: qrData,
      location: location,
      notes: d['notes'] as String? ?? '',
      notesAr: d['notes_ar'] as String? ?? '',
      extras: d['extras'] as Map<String, dynamic>? ?? {},
      createdAt: _parseTs(d['created_at']),
      updatedAt: _parseTs(d['updated_at']),
      syncedAt: DateTime.now(),
    );
  }

  static DateTime _parseTs(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}

// ════════════════════════════════════════════════════════════
//  Mock Datasource  –  rich demo data (used when Firestore
//  is unavailable or for testing the offline UI)
// ════════════════════════════════════════════════════════════
class MockTripDataSource implements TripRemoteDataSource {
  static List<Booking> _buildMockBookings(String userId) {
    final now = DateTime.now();

    String _qr(String id, String code, String name, DateTime ci, DateTime co, int guests) =>
        jsonEncode({'id': id, 'code': code, 'service': name,
          'check_in': ci.toIso8601String(), 'check_out': co.toIso8601String(),
          'guests': guests, 'traveler_id': userId});

    return [
      // ── 1. UPCOMING Hotel – Maldives ─────────────
      Booking(
        id: 'bk_maldives_001',
        userId: userId,
        partnerId: 'partner_001',
        serviceId: 'svc_burj_001',
        serviceType: BookingServiceType.hotel,
        status: BookingStatus.confirmed,
        serviceName: 'Overwater Bungalows Maldives',
        serviceNameAr: 'بنغالوز فوق الماء - المالديف',
        providerName: 'Maldives Luxury Resorts',
        providerNameAr: 'منتجعات المالديف الفاخرة',
        primaryImageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800',
        imageUrls: [
          'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800',
          'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?w=800',
          'https://images.unsplash.com/photo-1439130490301-25e322d88054?w=800',
        ],
        checkIn: now.add(const Duration(days: 12)),
        checkOut: now.add(const Duration(days: 19)),
        guests: 2,
        rooms: 1,
        totalPrice: 6230,
        currency: 'USD',
        confirmationCode: 'MLV-2024-8821',
        qrData: _qr('bk_maldives_001', 'MLV-2024-8821', 'Overwater Bungalows Maldives',
            now.add(const Duration(days: 12)), now.add(const Duration(days: 19)), 2),
        location: const BookingLocation(
          latitude: 4.1755, longitude: 73.5093,
          address: 'North Male Atoll, Maldives',
          addressAr: 'شعاب مالي الشمالية، المالديف',
          city: 'Malé', cityAr: 'ماليه', country: 'Maldives',
        ),
        notes: 'Early check-in requested at 10:00 AM. Airport transfer included.',
        notesAr: 'طلب تسجيل وصول مبكر الساعة 10 صباحاً. خدمة نقل من المطار مشمولة.',
        extras: {
          'amenities': ['Infinity Pool', 'Overwater Spa', 'Snorkeling', 'Sunset Cruise'],
          'meal_plan': 'All Inclusive',
          'stars': 5,
        },
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
        syncedAt: now,
      ),

      // ── 2. UPCOMING Tour – Japan ────────────────
      Booking(
        id: 'bk_japan_002',
        userId: userId,
        partnerId: 'partner_002',
        serviceId: 'svc_japan_002',
        serviceType: BookingServiceType.tour,
        status: BookingStatus.confirmed,
        serviceName: 'Cherry Blossom Tokyo Tour',
        serviceNameAr: 'جولة أزهار الكرز في طوكيو',
        providerName: 'Japan Discovery Tours',
        providerNameAr: 'جولات اكتشاف اليابان',
        primaryImageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=800',
        imageUrls: [
          'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=800',
          'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=800',
        ],
        checkIn: now.add(const Duration(days: 25)),
        checkOut: now.add(const Duration(days: 32)),
        guests: 2,
        rooms: 1,
        totalPrice: 3200,
        currency: 'USD',
        confirmationCode: 'JPN-2024-4417',
        qrData: _qr('bk_japan_002', 'JPN-2024-4417', 'Cherry Blossom Tokyo Tour',
            now.add(const Duration(days: 25)), now.add(const Duration(days: 32)), 2),
        location: const BookingLocation(
          latitude: 35.6762, longitude: 139.6503,
          address: 'Shinjuku, Tokyo, Japan',
          addressAr: 'شينجوكو، طوكيو، اليابان',
          city: 'Tokyo', cityAr: 'طوكيو', country: 'Japan',
        ),
        notes: 'Guide speaks Arabic & English. Group size: 8 people.',
        notesAr: 'المرشد يتحدث العربية والإنجليزية. حجم المجموعة: 8 أشخاص.',
        extras: {
          'includes': ['Bullet train tickets', 'Traditional tea ceremony', '4 hotel nights', 'Airport transfers'],
          'guide_name': 'Yuki Tanaka',
          'meeting_point': 'Narita Airport, Terminal 2, Gate B',
        },
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
        syncedAt: now,
      ),

      // ── 3. ACTIVE TODAY – Hotel Dubai ──────────
      Booking(
        id: 'bk_dubai_003',
        userId: userId,
        partnerId: 'partner_003',
        serviceId: 'svc_dubai_003',
        serviceType: BookingServiceType.hotel,
        status: BookingStatus.checkedIn,
        serviceName: 'Atlantis The Palm Dubai',
        serviceNameAr: 'أتلانتس النخلة دبي',
        providerName: 'Atlantis Hospitality',
        providerNameAr: 'ضيافة أتلانتس',
        primaryImageUrl: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800',
        imageUrls: [
          'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800',
          'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800',
          'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800',
        ],
        checkIn: now.subtract(const Duration(days: 1)),
        checkOut: now.add(const Duration(days: 3)),
        guests: 2,
        rooms: 1,
        totalPrice: 2850,
        currency: 'USD',
        confirmationCode: 'ATL-2024-7723',
        qrData: _qr('bk_dubai_003', 'ATL-2024-7723', 'Atlantis The Palm Dubai',
            now.subtract(const Duration(days: 1)), now.add(const Duration(days: 3)), 2),
        location: const BookingLocation(
          latitude: 25.1304, longitude: 55.1173,
          address: 'Crescent Road, The Palm Jumeirah, Dubai',
          addressAr: 'طريق الهلال، نخلة جميرا، دبي',
          city: 'Dubai', cityAr: 'دبي', country: 'UAE',
        ),
        notes: 'Room 1847 – Ocean View Suite. Aquaventure access included.',
        notesAr: 'الغرفة 1847 – جناح إطلالة بحرية. يشمل الوصول إلى أكوافنتشر.',
        extras: {
          'amenities': ['Aquaventure Waterpark', 'Private Beach', 'Spa', 'Multiple Restaurants'],
          'room_number': '1847',
          'floor': 18,
          'stars': 5,
        },
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(days: 1)),
        syncedAt: now,
      ),

      // ── 4. COMPLETED – Santorini ────────────────
      Booking(
        id: 'bk_santorini_004',
        userId: userId,
        partnerId: 'partner_004',
        serviceId: 'svc_santorini_004',
        serviceType: BookingServiceType.hotel,
        status: BookingStatus.completed,
        serviceName: 'Oia Castle Suites Santorini',
        serviceNameAr: 'أجنحة قلعة أويا سانتوريني',
        providerName: 'Greek Island Escapes',
        providerNameAr: 'إفلات الجزر اليونانية',
        primaryImageUrl: 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=800',
        imageUrls: [
          'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=800',
          'https://images.unsplash.com/photo-1613395877344-13d4a8e0d49e?w=800',
        ],
        checkIn: now.subtract(const Duration(days: 45)),
        checkOut: now.subtract(const Duration(days: 40)),
        guests: 2,
        rooms: 1,
        totalPrice: 1850,
        currency: 'USD',
        confirmationCode: 'SAN-2024-3301',
        qrData: _qr('bk_santorini_004', 'SAN-2024-3301', 'Oia Castle Suites Santorini',
            now.subtract(const Duration(days: 45)), now.subtract(const Duration(days: 40)), 2),
        location: const BookingLocation(
          latitude: 36.4618, longitude: 25.3753,
          address: 'Oia Village, Santorini, Greece',
          addressAr: 'قرية أويا، سانتوريني، اليونان',
          city: 'Santorini', cityAr: 'سانتوريني', country: 'Greece',
        ),
        notes: 'Complimentary sunset dinner included.',
        notesAr: 'عشاء غروب الشمس مجاني مشمول.',
        extras: {
          'amenities': ['Caldera View', 'Infinity Pool', 'Sunset Terrace'],
          'stars': 5,
        },
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 40)),
        syncedAt: now,
      ),

      // ── 5. UPCOMING Activity ────────────────────
      Booking(
        id: 'bk_safari_005',
        userId: userId,
        partnerId: 'partner_005',
        serviceId: 'svc_kenya_005',
        serviceType: BookingServiceType.activity,
        status: BookingStatus.confirmed,
        serviceName: 'Masai Mara Safari Adventure',
        serviceNameAr: 'مغامرة سفاري ماساي مارا',
        providerName: 'Wild Kenya Expeditions',
        providerNameAr: 'رحلات كينيا البرية',
        primaryImageUrl: 'https://images.unsplash.com/photo-1523805009345-7448845a9e53?w=800',
        imageUrls: [
          'https://images.unsplash.com/photo-1523805009345-7448845a9e53?w=800',
          'https://images.unsplash.com/photo-1549366021-9f761d450615?w=800',
        ],
        checkIn: now.add(const Duration(days: 40)),
        checkOut: now.add(const Duration(days: 45)),
        guests: 2,
        rooms: 1,
        totalPrice: 2100,
        currency: 'USD',
        confirmationCode: 'KNY-2024-9951',
        qrData: _qr('bk_safari_005', 'KNY-2024-9951', 'Masai Mara Safari Adventure',
            now.add(const Duration(days: 40)), now.add(const Duration(days: 45)), 2),
        location: const BookingLocation(
          latitude: -1.4832, longitude: 35.1014,
          address: 'Masai Mara National Reserve, Narok, Kenya',
          addressAr: 'محمية ماساي مارا الوطنية، نيروك، كينيا',
          city: 'Narok', cityAr: 'نيروك', country: 'Kenya',
        ),
        notes: 'Morning and evening game drives. Balloon safari on day 3.',
        notesAr: 'جولات صيد صباحية ومسائية. رحلة بالون في اليوم الثالث.',
        extras: {
          'includes': ['Game drives', 'Bush meals', 'Balloon safari', 'Park fees'],
          'transport': 'Shared 4WD (max 6 pax)',
        },
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 10)),
        syncedAt: now,
      ),
    ];
  }

  @override
  Future<List<Booking>> getBookings(String userId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _buildMockBookings(userId);
  }

  @override
  Stream<List<Booking>> watchBookings(String userId) async* {
    await Future.delayed(const Duration(milliseconds: 600));
    yield _buildMockBookings(userId);
  }

  @override
  Future<Booking?> getBookingById(String bookingId) async {
    return null; // mock returns null for single lookups
  }
}
