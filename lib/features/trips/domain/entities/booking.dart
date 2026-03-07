import 'package:equatable/equatable.dart';
// استيراد من local_booking.dart — لا تعريف مكرر هنا
import 'local_booking.dart';

// ════════════════════════════════════════════════════════════
//  BookingLocation
// ════════════════════════════════════════════════════════════
class BookingLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String address;
  final String addressAr;
  final String city;
  final String cityAr;
  final String country;

  const BookingLocation({
    this.latitude = 0, this.longitude = 0,
    this.address = '', this.addressAr = '',
    this.city = '', this.cityAr = '', this.country = '',
  });

  Map<String, dynamic> toJson() => {
    'lat': latitude, 'lng': longitude,
    'address': address, 'address_ar': addressAr,
    'city': city, 'city_ar': cityAr, 'country': country,
  };

  factory BookingLocation.fromJson(Map<String, dynamic> j) => BookingLocation(
    latitude:  (j['lat'] as num?)?.toDouble() ?? 0,
    longitude: (j['lng'] as num?)?.toDouble() ?? 0,
    address:   j['address']    as String? ?? '',
    addressAr: j['address_ar'] as String? ?? '',
    city:      j['city']       as String? ?? '',
    cityAr:    j['city_ar']    as String? ?? '',
    country:   j['country']    as String? ?? '',
  );

  @override
  List<Object?> get props => [latitude, longitude];
}

// ════════════════════════════════════════════════════════════
//  Booking
// ════════════════════════════════════════════════════════════
class Booking extends Equatable {
  final String id;
  final String userId;
  final String partnerId;
  final String serviceId;
  final BookingServiceType serviceType;
  final BookingStatus status;
  final String serviceName;
  final String serviceNameAr;
  final String providerName;
  final String providerNameAr;
  final String primaryImageUrl;
  final List<String> imageUrls;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final int rooms;
  final double totalPrice;
  final String currency;
  final String confirmationCode;
  final String qrData;
  final BookingLocation location;
  final String notes;
  final String notesAr;
  final Map<String, dynamic> extras;
  final bool isOfflineCached;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  const Booking({
    required this.id,
    required this.userId,
    required this.partnerId,
    required this.serviceId,
    required this.serviceType,
    required this.status,
    required this.serviceName,
    this.serviceNameAr = '',
    this.providerName = '',
    this.providerNameAr = '',
    this.primaryImageUrl = '',
    this.imageUrls = const [],
    required this.checkIn,
    required this.checkOut,
    this.guests = 1,
    this.rooms = 1,
    required this.totalPrice,
    this.currency = 'USD',
    required this.confirmationCode,
    required this.qrData,
    required this.location,
    this.notes = '',
    this.notesAr = '',
    this.extras = const {},
    this.isOfflineCached = false,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
  });

  int get nights    => checkOut.difference(checkIn).inDays;
  bool get isUpcoming  => checkIn.isAfter(DateTime.now());
  bool get isPast      => checkOut.isBefore(DateTime.now());
  bool get isActive    => checkIn.isBefore(DateTime.now()) && checkOut.isAfter(DateTime.now());
  bool get isConfirmed => status == BookingStatus.confirmed || status == BookingStatus.checkedIn;

  Booking copyWith({
    BookingStatus? status,
    bool? isOfflineCached,
    DateTime? syncedAt,
  }) => Booking(
    id: id, userId: userId, partnerId: partnerId, serviceId: serviceId,
    serviceType: serviceType, status: status ?? this.status,
    serviceName: serviceName, serviceNameAr: serviceNameAr,
    providerName: providerName, providerNameAr: providerNameAr,
    primaryImageUrl: primaryImageUrl, imageUrls: imageUrls,
    checkIn: checkIn, checkOut: checkOut, guests: guests, rooms: rooms,
    totalPrice: totalPrice, currency: currency,
    confirmationCode: confirmationCode, qrData: qrData, location: location,
    notes: notes, notesAr: notesAr, extras: extras,
    isOfflineCached: isOfflineCached ?? this.isOfflineCached,
    createdAt: createdAt, updatedAt: updatedAt,
    syncedAt: syncedAt ?? this.syncedAt,
  );

  @override
  List<Object?> get props => [id, status, syncedAt];
}

// ════════════════════════════════════════════════════════════
//  TripDay
// ════════════════════════════════════════════════════════════
class TripDay extends Equatable {
  final DateTime date;
  final List<Booking> bookings;

  const TripDay({required this.date, required this.bookings});

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  bool get isPast => date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
  bool get hasActive => bookings.any((b) => b.isConfirmed);

  @override
  List<Object?> get props => [date, bookings.length];
}

// ════════════════════════════════════════════════════════════
//  TripSummary
// ════════════════════════════════════════════════════════════
class TripSummary extends Equatable {
  final int totalBookings;
  final int upcomingBookings;
  final int activeBookings;
  final int completedBookings;
  final double totalSpent;
  final int countriesVisited;

  const TripSummary({
    this.totalBookings = 0,
    this.upcomingBookings = 0,
    this.activeBookings = 0,
    this.completedBookings = 0,
    this.totalSpent = 0,
    this.countriesVisited = 0,
  });

  @override
  List<Object?> get props => [totalBookings, totalSpent];
}