import 'package:equatable/equatable.dart';

// ════════════════════════════════════════════════════════════
//  TravelPackage  –  عروض الوكالات
// ════════════════════════════════════════════════════════════
class TravelPackage extends Equatable {
  final String id;
  final String agencyName;
  final String agencyNameAr;
  final String agencyLogoUrl;
  final String title;
  final String titleAr;
  final String destinationCity;
  final String destinationCityAr;
  final String country;
  final String countryAr;
  final List<String> imageUrls;
  final int durationDays;
  final int durationNights;
  final double price;
  final double originalPrice;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final List<String> includes;
  final List<String> includesAr;
  final String description;
  final String descriptionAr;
  final double latitude;
  final double longitude;
  final PackageType packageType;
  final bool isPopular;
  final DateTime? availableFrom;

  const TravelPackage({
    required this.id,
    required this.agencyName,
    required this.agencyNameAr,
    required this.agencyLogoUrl,
    required this.title,
    required this.titleAr,
    required this.destinationCity,
    required this.destinationCityAr,
    required this.country,
    required this.countryAr,
    required this.imageUrls,
    required this.durationDays,
    required this.durationNights,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.reviewCount,
    this.isVerified = false,
    required this.includes,
    required this.includesAr,
    required this.description,
    required this.descriptionAr,
    required this.latitude,
    required this.longitude,
    this.packageType = PackageType.standard,
    this.isPopular = false,
    this.availableFrom,
  });

  double get discountPercent =>
      originalPrice > price ? ((originalPrice - price) / originalPrice * 100) : 0;

  bool get hasDiscount => originalPrice > price;

  @override
  List<Object?> get props => [id];
}

enum PackageType { economy, standard, premium, luxury }

extension PackageTypeX on PackageType {
  String get nameAr {
    switch (this) {
      case PackageType.economy: return 'اقتصادي';
      case PackageType.standard: return 'قياسي';
      case PackageType.premium: return 'مميز';
      case PackageType.luxury: return 'فاخر';
    }
  }
  String get nameEn {
    switch (this) {
      case PackageType.economy: return 'Economy';
      case PackageType.standard: return 'Standard';
      case PackageType.premium: return 'Premium';
      case PackageType.luxury: return 'Luxury';
    }
  }
}

// ════════════════════════════════════════════════════════════
//  Hotel  –  الفنادق الموصى بها
// ════════════════════════════════════════════════════════════
class Hotel extends Equatable {
  final String id;
  final String name;
  final String nameAr;
  final String city;
  final String cityAr;
  final String country;
  final String countryAr;
  final List<String> imageUrls;
  final double rating;
  final int reviewCount;
  final double pricePerNight;
  final int stars;
  final List<String> amenities;
  final List<String> amenitiesAr;
  final String description;
  final String descriptionAr;
  final double latitude;
  final double longitude;
  final String address;
  final String addressAr;
  final bool isFeatured;
  final bool hasPool;
  final bool hasWifi;
  final bool hasGym;
  final bool hasRestaurant;
  final bool hasSpa;

  const Hotel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.city,
    required this.cityAr,
    required this.country,
    required this.countryAr,
    required this.imageUrls,
    required this.rating,
    required this.reviewCount,
    required this.pricePerNight,
    required this.stars,
    required this.amenities,
    required this.amenitiesAr,
    required this.description,
    required this.descriptionAr,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.addressAr,
    this.isFeatured = false,
    this.hasPool = false,
    this.hasWifi = true,
    this.hasGym = false,
    this.hasRestaurant = false,
    this.hasSpa = false,
  });

  @override
  List<Object?> get props => [id];
}

// ════════════════════════════════════════════════════════════
//  ExploreFilter  –  نموذج الفلتر
// ════════════════════════════════════════════════════════════
enum ServiceType { all, hotel, travelAgency }

extension ServiceTypeX on ServiceType {
  String get nameAr {
    switch (this) {
      case ServiceType.all: return 'الكل';
      case ServiceType.hotel: return 'فنادق';
      case ServiceType.travelAgency: return 'وكالات';
    }
  }
  String get nameEn {
    switch (this) {
      case ServiceType.all: return 'All';
      case ServiceType.hotel: return 'Hotels';
      case ServiceType.travelAgency: return 'Agencies';
    }
  }
}

class ExploreFilter extends Equatable {
  final ServiceType serviceType;
  final String? city;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final List<String> selectedAmenities;
  final SortOption sortBy;

  const ExploreFilter({
    this.serviceType = ServiceType.all,
    this.city,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.selectedAmenities = const [],
    this.sortBy = SortOption.recommended,
  });

  bool get isActive =>
      serviceType != ServiceType.all ||
      city != null ||
      minPrice != null ||
      maxPrice != null ||
      minRating != null ||
      selectedAmenities.isNotEmpty ||
      sortBy != SortOption.recommended;

  int get activeCount {
    int count = 0;
    if (serviceType != ServiceType.all) count++;
    if (city != null) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (minRating != null) count++;
    if (selectedAmenities.isNotEmpty) count++;
    return count;
  }

  ExploreFilter copyWith({
    ServiceType? serviceType,
    String? Function()? city,
    double? Function()? minPrice,
    double? Function()? maxPrice,
    double? Function()? minRating,
    List<String>? selectedAmenities,
    SortOption? sortBy,
  }) {
    return ExploreFilter(
      serviceType: serviceType ?? this.serviceType,
      city: city != null ? city() : this.city,
      minPrice: minPrice != null ? minPrice() : this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
      minRating: minRating != null ? minRating() : this.minRating,
      selectedAmenities: selectedAmenities ?? this.selectedAmenities,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  ExploreFilter reset() => const ExploreFilter();

  @override
  List<Object?> get props =>
      [serviceType, city, minPrice, maxPrice, minRating, selectedAmenities, sortBy];
}

enum SortOption { recommended, priceLowHigh, priceHighLow, rating, newest }

extension SortOptionX on SortOption {
  String get nameAr {
    switch (this) {
      case SortOption.recommended: return 'موصى به';
      case SortOption.priceLowHigh: return 'السعر: الأقل أولاً';
      case SortOption.priceHighLow: return 'السعر: الأعلى أولاً';
      case SortOption.rating: return 'الأعلى تقييماً';
      case SortOption.newest: return 'الأحدث';
    }
  }
}

// ════════════════════════════════════════════════════════════
//  ExploreItem  –  Union type for mixed feed
// ════════════════════════════════════════════════════════════
sealed class ExploreItem extends Equatable {
  const ExploreItem();
}

class PackageItem extends ExploreItem {
  final TravelPackage package;
  const PackageItem(this.package);
  @override
  List<Object?> get props => [package.id];
}

class HotelItem extends ExploreItem {
  final Hotel hotel;
  const HotelItem(this.hotel);
  @override
  List<Object?> get props => [hotel.id];
}
