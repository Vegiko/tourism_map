import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ════════════════════════════════════════════════════════════
//  MarkerType
// ════════════════════════════════════════════════════════════
enum MarkerType { hotel, travelAgency, tourGuide, activity }

extension MarkerTypeX on MarkerType {
  String get nameAr {
    switch (this) {
      case MarkerType.hotel:         return 'فندق';
      case MarkerType.travelAgency:  return 'وكالة سفر';
      case MarkerType.tourGuide:     return 'مرشد سياحي';
      case MarkerType.activity:      return 'نشاط';
    }
  }
  String get nameEn {
    switch (this) {
      case MarkerType.hotel:         return 'Hotel';
      case MarkerType.travelAgency:  return 'Travel Package';
      case MarkerType.tourGuide:     return 'Tour Guide';
      case MarkerType.activity:      return 'Activity';
    }
  }
  String get emoji {
    switch (this) {
      case MarkerType.hotel:         return '🏨';
      case MarkerType.travelAgency:  return '✈️';
      case MarkerType.tourGuide:     return '🧭';
      case MarkerType.activity:      return '🏄';
    }
  }
}

// ════════════════════════════════════════════════════════════
//  MapMarkerData  –  data attached to each pin
// ════════════════════════════════════════════════════════════
class MapMarkerData extends Equatable {
  final String id;
  final String name;
  final String nameAr;
  final String description;
  final String descriptionAr;
  final MarkerType type;
  final LatLng position;
  final double price;
  final String currency;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String city;
  final String cityAr;
  final String address;
  final bool isVerified;
  final bool isFeatured;
  final int stars;           // for hotels
  final int durationDays;    // for packages

  const MapMarkerData({
    required this.id,
    required this.name,
    this.nameAr = '',
    this.description = '',
    this.descriptionAr = '',
    required this.type,
    required this.position,
    required this.price,
    this.currency = 'USD',
    this.rating = 0,
    this.reviewCount = 0,
    this.imageUrl = '',
    this.city = '',
    this.cityAr = '',
    this.address = '',
    this.isVerified = false,
    this.isFeatured = false,
    this.stars = 0,
    this.durationDays = 0,
  });

  String get priceLabel => '\$$price';

  @override
  List<Object?> get props => [id, position];
}

// ════════════════════════════════════════════════════════════
//  MapFilter
// ════════════════════════════════════════════════════════════
class MapFilter extends Equatable {
  final Set<MarkerType> enabledTypes;
  final double maxPrice;
  final double minRating;
  final bool showVerifiedOnly;

  const MapFilter({
    this.enabledTypes = const {
      MarkerType.hotel,
      MarkerType.travelAgency,
      MarkerType.tourGuide,
    },
    this.maxPrice = 5000,
    this.minRating = 0,
    this.showVerifiedOnly = false,
  });

  bool get isDefault =>
      enabledTypes.length == 3 &&
      maxPrice == 5000 &&
      minRating == 0 &&
      !showVerifiedOnly;

  MapFilter copyWith({
    Set<MarkerType>? enabledTypes,
    double? maxPrice,
    double? minRating,
    bool? showVerifiedOnly,
  }) =>
      MapFilter(
        enabledTypes:     enabledTypes     ?? this.enabledTypes,
        maxPrice:         maxPrice         ?? this.maxPrice,
        minRating:        minRating        ?? this.minRating,
        showVerifiedOnly: showVerifiedOnly ?? this.showVerifiedOnly,
      );

  @override
  List<Object?> get props =>
      [enabledTypes, maxPrice, minRating, showVerifiedOnly];
}

// ════════════════════════════════════════════════════════════
//  MapFailure
// ════════════════════════════════════════════════════════════
class MapFailure extends Equatable {
  final String message;
  const MapFailure(this.message);
  @override
  List<Object?> get props => [message];
}
