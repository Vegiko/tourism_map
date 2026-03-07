import 'package:equatable/equatable.dart';
import 'dart:convert';

// ════════════════════════════════════════════════════════════
//  BookingStatus  —  مصدر الحقيقة الوحيد
// ════════════════════════════════════════════════════════════
enum BookingStatus {
  upcoming,
  ongoing,
  confirmed,
  completed,
  cancelled,
  pending,
  checkedIn,
}

extension BookingStatusX on BookingStatus {
  String get nameAr {
    switch (this) {
      case BookingStatus.upcoming:   return 'قادمة';
      case BookingStatus.ongoing:    return 'جارية';
      case BookingStatus.confirmed:  return 'مؤكد';
      case BookingStatus.completed:  return 'مكتملة';
      case BookingStatus.cancelled:  return 'ملغاة';
      case BookingStatus.pending:    return 'معلقة';
      case BookingStatus.checkedIn:  return 'تم تسجيل الدخول';
    }
  }

  String get nameEn {
    switch (this) {
      case BookingStatus.upcoming:   return 'Upcoming';
      case BookingStatus.ongoing:    return 'Ongoing';
      case BookingStatus.confirmed:  return 'Confirmed';
      case BookingStatus.completed:  return 'Completed';
      case BookingStatus.cancelled:  return 'Cancelled';
      case BookingStatus.pending:    return 'Pending';
      case BookingStatus.checkedIn:  return 'Checked In';
    }
  }

  String get emoji {
    switch (this) {
      case BookingStatus.upcoming:   return '🗓️';
      case BookingStatus.ongoing:    return '✈️';
      case BookingStatus.confirmed:  return '✅';
      case BookingStatus.completed:  return '🏁';
      case BookingStatus.cancelled:  return '❌';
      case BookingStatus.pending:    return '⏳';
      case BookingStatus.checkedIn:  return '🏨';
    }
  }

  String get firestoreKey {
    switch (this) {
      case BookingStatus.checkedIn: return 'checked_in';
      default: return name;
    }
  }

  static BookingStatus fromString(String v) {
    switch (v.toLowerCase()) {
      case 'ongoing':    return BookingStatus.ongoing;
      case 'confirmed':  return BookingStatus.confirmed;
      case 'completed':  return BookingStatus.completed;
      case 'cancelled':  return BookingStatus.cancelled;
      case 'checked_in': return BookingStatus.checkedIn;
      case 'pending':    return BookingStatus.pending;
      default:           return BookingStatus.upcoming;
    }
  }
}

// ════════════════════════════════════════════════════════════
//  BookingServiceType
// ════════════════════════════════════════════════════════════
enum BookingServiceType { hotel, travelPackage, tourGuide, activity, flight, restaurant, tour }

extension BookingServiceTypeX on BookingServiceType {
  String get nameAr {
    switch (this) {
      case BookingServiceType.hotel:         return 'فندق';
      case BookingServiceType.travelPackage: return 'باقة سياحية';
      case BookingServiceType.tourGuide:     return 'مرشد سياحي';
      case BookingServiceType.activity:      return 'نشاط';
      case BookingServiceType.flight:        return 'رحلة طيران';
      case BookingServiceType.restaurant:    return 'مطعم';
      case BookingServiceType.tour:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  String get nameEn {
    switch (this) {
      case BookingServiceType.hotel:         return 'Hotel';
      case BookingServiceType.travelPackage: return 'Travel Package';
      case BookingServiceType.tourGuide:     return 'Tour Guide';
      case BookingServiceType.activity:      return 'Activity';
      case BookingServiceType.flight:        return 'Flight';
      case BookingServiceType.restaurant:    return 'Restaurant';
      case BookingServiceType.tour:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  String get emoji {
    switch (this) {
      case BookingServiceType.hotel:         return '🏨';
      case BookingServiceType.travelPackage: return '✈️';
      case BookingServiceType.tourGuide:     return '🧭';
      case BookingServiceType.activity:      return '🏄';
      case BookingServiceType.flight:        return '✈️';
      case BookingServiceType.restaurant:    return '🍽️';
      case BookingServiceType.tour:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  String get storageKey {
    switch (this) {
      case BookingServiceType.hotel:         return 'hotel';
      case BookingServiceType.travelPackage: return 'travel_package';
      case BookingServiceType.tourGuide:     return 'tour_guide';
      case BookingServiceType.activity:      return 'activity';
      case BookingServiceType.flight:        return 'flight';
      case BookingServiceType.restaurant:    return 'restaurant';
      case BookingServiceType.tour:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  static BookingServiceType fromString(String v) {
    switch (v) {
      case 'travel_package': return BookingServiceType.travelPackage;
      case 'tour_guide':     return BookingServiceType.tourGuide;
      case 'activity':       return BookingServiceType.activity;
      case 'flight':         return BookingServiceType.flight;
      case 'restaurant':     return BookingServiceType.restaurant;
      default:               return BookingServiceType.hotel;
    }
  }
}

// ════════════════════════════════════════════════════════════
//  BookingGuest
// ════════════════════════════════════════════════════════════
class BookingGuest extends Equatable {
  final String name;
  final int adults;
  final int children;

  const BookingGuest({required this.name, this.adults = 1, this.children = 0});

  int get totalGuests => adults + children;

  Map<String, dynamic> toJson() =>
      {'name': name, 'adults': adults, 'children': children};

  factory BookingGuest.fromJson(Map<String, dynamic> j) => BookingGuest(
    name:     j['name']     as String? ?? '',
    adults:   j['adults']   as int?    ?? 1,
    children: j['children'] as int?    ?? 0,
  );

  @override
  List<Object?> get props => [name, adults, children];
}

// ════════════════════════════════════════════════════════════
//  LocalBooking
// ════════════════════════════════════════════════════════════
class LocalBooking extends Equatable {
  final String id;
  final String confirmationCode;
  final String userId;
  final String serviceId;
  final String serviceName;
  final String serviceNameAr;
  final BookingServiceType serviceType;
  final String partnerName;
  final String partnerNameAr;
  final DateTime checkIn;
  final DateTime checkOut;
  final DateTime bookedAt;
  final BookingGuest guest;
  final double totalPrice;
  final double serviceFee;
  final String currency;
  final String city;
  final String cityAr;
  final String address;
  final double latitude;
  final double longitude;
  final String coverImageUrl;
  final BookingStatus status;
  final String qrData;
  final Map<String, dynamic> extras;
  final bool isSyncedToCloud;
  final DateTime lastSyncedAt;
  final DateTime updatedAt;

  const LocalBooking({
    required this.id,
    required this.confirmationCode,
    required this.userId,
    required this.serviceId,
    required this.serviceName,
    this.serviceNameAr = '',
    required this.serviceType,
    this.partnerName = '',
    this.partnerNameAr = '',
    required this.checkIn,
    required this.checkOut,
    required this.bookedAt,
    required this.guest,
    required this.totalPrice,
    this.serviceFee = 0,
    this.currency = 'USD',
    this.city = '',
    this.cityAr = '',
    this.address = '',
    this.latitude = 0,
    this.longitude = 0,
    this.coverImageUrl = '',
    required this.status,
    required this.qrData,
    this.extras = const {},
    this.isSyncedToCloud = true,
    required this.lastSyncedAt,
    required this.updatedAt,
  });

  int get nights      => checkOut.difference(checkIn).inDays;
  bool get isUpcoming  => status == BookingStatus.upcoming;
  bool get isOngoing   => status == BookingStatus.ongoing;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isCancelled => status == BookingStatus.cancelled;
  bool get isConfirmed => status == BookingStatus.confirmed || status == BookingStatus.checkedIn;

  static String buildQrData({
    required String id,
    required String confirmationCode,
    required String serviceName,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required double totalPrice,
    required String currency,
  }) {
    return jsonEncode({
      'id':           id,
      'ref':          confirmationCode,
      'service':      serviceName,
      'check_in':     checkIn.toIso8601String().substring(0, 10),
      'check_out':    checkOut.toIso8601String().substring(0, 10),
      'guests':       guests,
      'total':        '\$$totalPrice $currency',
      'app':          'TravelApp',
      'generated_at': DateTime.now().toIso8601String(),
    });
  }

  LocalBooking copyWith({
    BookingStatus? status,
    bool? isSyncedToCloud,
    DateTime? lastSyncedAt,
  }) =>
      LocalBooking(
        id: id, confirmationCode: confirmationCode, userId: userId,
        serviceId: serviceId, serviceName: serviceName, serviceNameAr: serviceNameAr,
        serviceType: serviceType, partnerName: partnerName, partnerNameAr: partnerNameAr,
        checkIn: checkIn, checkOut: checkOut, bookedAt: bookedAt,
        guest: guest, totalPrice: totalPrice, serviceFee: serviceFee, currency: currency,
        city: city, cityAr: cityAr, address: address,
        latitude: latitude, longitude: longitude, coverImageUrl: coverImageUrl,
        status: status ?? this.status, qrData: qrData, extras: extras,
        isSyncedToCloud: isSyncedToCloud ?? this.isSyncedToCloud,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        updatedAt: DateTime.now(),
      );

  @override
  List<Object?> get props => [id, confirmationCode, status, checkIn, checkOut, isSyncedToCloud];
}

// ════════════════════════════════════════════════════════════
//  TripStats
// ════════════════════════════════════════════════════════════
class TripStats extends Equatable {
  final int totalTrips;
  final int upcomingCount;
  final int completedCount;
  final double totalSpent;
  final int totalDestinations;
  final int totalNights;

  const TripStats({
    this.totalTrips       = 0,
    this.upcomingCount    = 0,
    this.completedCount   = 0,
    this.totalSpent       = 0,
    this.totalDestinations = 0,
    this.totalNights      = 0,
  });

  factory TripStats.fromBookings(List<LocalBooking> bookings) {
    return TripStats(
      totalTrips:        bookings.length,
      upcomingCount:     bookings.where((b) => b.isUpcoming).length,
      completedCount:    bookings.where((b) => b.isCompleted).length,
      totalSpent:        bookings.fold(0, (s, b) => s + b.totalPrice),
      totalDestinations: bookings.map((b) => b.city).toSet().length,
      totalNights:       bookings.fold(0, (s, b) => s + b.nights),
    );
  }

  @override
  List<Object?> get props => [totalTrips, upcomingCount, completedCount, totalSpent];
}

// ════════════════════════════════════════════════════════════
//  TripFailure  —  مصدر الحقيقة الوحيد
// ════════════════════════════════════════════════════════════
class TripFailure extends Equatable {
  final String message;
  final bool isOfflineError;
  const TripFailure(this.message, {this.isOfflineError = false});
  @override
  List<Object?> get props => [message];
}
