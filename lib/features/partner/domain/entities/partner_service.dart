import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/app_user.dart';
import 'dart:ui' show Color;

// ════════════════════════════════════════════════════════════
//  ServiceType Enum  –  نوع الخدمة
// ════════════════════════════════════════════════════════════
enum ServiceType { hotel, travelAgency, tourGuide, restaurant, activity }

extension ServiceTypeX on ServiceType {
  String get nameAr {
    switch (this) {
      case ServiceType.hotel:        return 'فندق';
      case ServiceType.travelAgency: return 'وكالة سفر';
      case ServiceType.tourGuide:    return 'مرشد سياحي';
      case ServiceType.restaurant:   return 'مطعم';
      case ServiceType.activity:     return 'نشاط سياحي';
    }
  }
  String get nameEn {
    switch (this) {
      case ServiceType.hotel:        return 'Hotel';
      case ServiceType.travelAgency: return 'Travel Agency';
      case ServiceType.tourGuide:    return 'Tour Guide';
      case ServiceType.restaurant:   return 'Restaurant';
      case ServiceType.activity:     return 'Activity';
    }
  }
  String get emoji {
    switch (this) {
      case ServiceType.hotel:        return '🏨';
      case ServiceType.travelAgency: return '✈️';
      case ServiceType.tourGuide:    return '🧭';
      case ServiceType.restaurant:   return '🍽️';
      case ServiceType.activity:     return '🏄';
    }
  }
  String get firestoreKey {
    switch (this) {
      case ServiceType.hotel:        return 'hotel';
      case ServiceType.travelAgency: return 'travel_agency';
      case ServiceType.tourGuide:    return 'tour_guide';
      case ServiceType.restaurant:   return 'restaurant';
      case ServiceType.activity:     return 'activity';
    }
  }
  static ServiceType fromString(String v) {
    switch (v) {
      case 'travel_agency': return ServiceType.travelAgency;
      case 'tour_guide':    return ServiceType.tourGuide;
      case 'restaurant':    return ServiceType.restaurant;
      case 'activity':      return ServiceType.activity;
      default:              return ServiceType.hotel;
    }
  }
}

// ════════════════════════════════════════════════════════════
//  ServiceStatus Enum
// ════════════════════════════════════════════════════════════
enum ServiceStatus { active, pending, suspended, draft }

extension ServiceStatusX on ServiceStatus {
  String get nameAr {
    switch (this) {
      case ServiceStatus.active:    return 'نشط';
      case ServiceStatus.pending:   return 'قيد المراجعة';
      case ServiceStatus.suspended: return 'موقوف';
      case ServiceStatus.draft:     return 'مسودة';
    }
  }
  Color get color {
    switch (this) {
      case ServiceStatus.active:    return const Color(0xFF27AE60);
      case ServiceStatus.pending:   return const Color(0xFFF0A500);
      case ServiceStatus.suspended: return const Color(0xFFE74C3C);
      case ServiceStatus.draft:     return const Color(0xFF6B7A8D);
    }
  }
  static ServiceStatus fromString(String v) {
    switch (v) {
      case 'active':    return ServiceStatus.active;
      case 'suspended': return ServiceStatus.suspended;
      case 'draft':     return ServiceStatus.draft;
      default:          return ServiceStatus.pending;
    }
  }
}


// ════════════════════════════════════════════════════════════
//  ServiceLocation
// ════════════════════════════════════════════════════════════
class ServiceLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String address;
  final String addressAr;
  final String city;
  final String cityAr;
  final String country;

  const ServiceLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.addressAr = '',
    required this.city,
    this.cityAr = '',
    this.country = '',
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'address_ar': addressAr,
    'city': city,
    'city_ar': cityAr,
    'country': country,
  };

  factory ServiceLocation.fromJson(Map<String, dynamic> json) => ServiceLocation(
    latitude:  (json['latitude']  as num?)?.toDouble() ?? 0.0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    address:   json['address']    as String? ?? '',
    addressAr: json['address_ar'] as String? ?? '',
    city:      json['city']       as String? ?? '',
    cityAr:    json['city_ar']    as String? ?? '',
    country:   json['country']    as String? ?? '',
  );

  @override
  List<Object?> get props => [latitude, longitude];
}

// ════════════════════════════════════════════════════════════
//  PartnerService Entity  –  الخدمة الرئيسية
// ════════════════════════════════════════════════════════════
class PartnerService extends Equatable {
  final String id;
  final String partnerId;       // UID of the partner who owns this
  final String partnerName;
  final String partnerNameAr;
  final String name;
  final String nameAr;
  final String description;
  final String descriptionAr;
  final ServiceType serviceType;
  final ServiceStatus status;
  final double price;
  final String currency;
  final List<String> imageUrls;  // Firestore Storage URLs
  final List<String> localImagePaths; // temp paths before upload (not stored in Firestore)
  final ServiceLocation? location;
  final double rating;
  final int reviewCount;
  final int bookingCount;
  final double totalRevenue;
  final bool isFeatured;
  final Map<String, dynamic> extras; // flexible extra fields
  final DateTime createdAt;
  final DateTime updatedAt;

  const PartnerService({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    this.partnerNameAr = '',
    required this.name,
    this.nameAr = '',
    this.description = '',
    this.descriptionAr = '',
    required this.serviceType,
    this.status = ServiceStatus.pending,
    required this.price,
    this.currency = 'USD',
    this.imageUrls = const [],
    this.localImagePaths = const [],
    this.location,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.bookingCount = 0,
    this.totalRevenue = 0.0,
    this.isFeatured = false,
    this.extras = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasImages => imageUrls.isNotEmpty || localImagePaths.isNotEmpty;
  bool get isActive => status == ServiceStatus.active;

  PartnerService copyWith({
    String? name,
    String? nameAr,
    String? description,
    String? descriptionAr,
    ServiceType? serviceType,
    ServiceStatus? status,
    double? price,
    List<String>? imageUrls,
    List<String>? localImagePaths,
    ServiceLocation? location,
    double? rating,
    int? reviewCount,
    int? bookingCount,
    double? totalRevenue,
    bool? isFeatured,
    Map<String, dynamic>? extras,
  }) {
    return PartnerService(
      id: id,
      partnerId: partnerId,
      partnerName: partnerName,
      partnerNameAr: partnerNameAr,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      description: description ?? this.description,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      price: price ?? this.price,
      currency: currency,
      imageUrls: imageUrls ?? this.imageUrls,
      localImagePaths: localImagePaths ?? this.localImagePaths,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      bookingCount: bookingCount ?? this.bookingCount,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      isFeatured: isFeatured ?? this.isFeatured,
      extras: extras ?? this.extras,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, partnerId, name, serviceType, status];
}

// ════════════════════════════════════════════════════════════
//  PartnerStats  –  إحصائيات الشريك
// ════════════════════════════════════════════════════════════
class PartnerStats extends Equatable {
  final int totalServices;
  final int activeServices;
  final int totalBookings;
  final int pendingBookings;
  final int completedBookings;
  final double totalRevenue;
  final double monthlyRevenue;
  final double weeklyRevenue;
  final double averageRating;
  final int totalReviews;
  final int newCustomersThisMonth;
  final List<RevenuePoint> revenueChart;

  const PartnerStats({
    this.totalServices = 0,
    this.activeServices = 0,
    this.totalBookings = 0,
    this.pendingBookings = 0,
    this.completedBookings = 0,
    this.totalRevenue = 0,
    this.monthlyRevenue = 0,
    this.weeklyRevenue = 0,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.newCustomersThisMonth = 0,
    this.revenueChart = const [],
  });

  @override
  List<Object?> get props => [totalBookings, totalRevenue];
}

class RevenuePoint extends Equatable {
  final DateTime date;
  final double amount;
  const RevenuePoint({required this.date, required this.amount});
  @override
  List<Object?> get props => [date, amount];
}

// ════════════════════════════════════════════════════════════
//  Partner Failure
// ════════════════════════════════════════════════════════════
class PartnerFailure extends Equatable {
  final String message;
  const PartnerFailure(this.message);
  @override
  List<Object?> get props => [message];
}
