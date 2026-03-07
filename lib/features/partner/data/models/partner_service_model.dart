import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/partner_service.dart';

// ════════════════════════════════════════════════════════════
//  ServiceLocation Model
// ════════════════════════════════════════════════════════════
class ServiceLocationModel extends ServiceLocation {
  const ServiceLocationModel({
    required super.latitude,
    required super.longitude,
    required super.address,
    super.addressAr,
    required super.city,
    super.cityAr,
    super.country,
  });

  factory ServiceLocationModel.fromJson(Map<String, dynamic> json) =>
      ServiceLocationModel(
        latitude:  (json['latitude']  as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        address:   json['address']    as String? ?? '',
        addressAr: json['address_ar'] as String? ?? '',
        city:      json['city']       as String? ?? '',
        cityAr:    json['city_ar']    as String? ?? '',
        country:   json['country']    as String? ?? '',
      );

  @override
  Map<String, dynamic> toJson() => {
    'latitude':  latitude,
    'longitude': longitude,
    'address':   address,
    'address_ar': addressAr,
    'city':      city,
    'city_ar':   cityAr,
    'country':   country,
    // GeoPoint for Firestore geo-queries
    'geopoint':  GeoPoint(latitude, longitude),
  };
}

// ════════════════════════════════════════════════════════════
//  PartnerService Model
// ════════════════════════════════════════════════════════════
class PartnerServiceModel extends PartnerService {
  const PartnerServiceModel({
    required super.id,
    required super.partnerId,
    required super.partnerName,
    super.partnerNameAr,
    required super.name,
    super.nameAr,
    super.description,
    super.descriptionAr,
    required super.serviceType,
    super.status,
    required super.price,
    super.currency,
    super.imageUrls,
    super.localImagePaths,
    super.location,
    super.rating,
    super.reviewCount,
    super.bookingCount,
    super.totalRevenue,
    super.isFeatured,
    super.extras,
    required super.createdAt,
    required super.updatedAt,
  });

  // ── From Firestore DocumentSnapshot ──────────────
  factory PartnerServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PartnerServiceModel.fromJson({...data, 'id': doc.id});
  }

  // ── From JSON Map ─────────────────────────────────
  factory PartnerServiceModel.fromJson(Map<String, dynamic> json) {
    ServiceLocationModel? loc;
    if (json['location'] != null) {
      loc = ServiceLocationModel.fromJson(
          json['location'] as Map<String, dynamic>);
    }

    return PartnerServiceModel(
      id:            json['id']              as String? ?? '',
      partnerId:     json['partner_id']      as String? ?? '',
      partnerName:   json['partner_name']    as String? ?? '',
      partnerNameAr: json['partner_name_ar'] as String? ?? '',
      name:          json['name']            as String? ?? '',
      nameAr:        json['name_ar']         as String? ?? '',
      description:   json['description']     as String? ?? '',
      descriptionAr: json['description_ar']  as String? ?? '',
      serviceType: ServiceTypeX.fromString(
        json['service_type'] as String? ?? 'hotel',
      ),
      status: ServiceStatusX.fromString(
        json['status'] as String? ?? 'pending',
      ),
      price:        (json['price']         as num?)?.toDouble() ?? 0.0,
      currency:      json['currency']      as String? ?? 'USD',
      imageUrls:     List<String>.from(json['image_urls'] as List? ?? []),
      rating:       (json['rating']        as num?)?.toDouble() ?? 0.0,
      reviewCount:   json['review_count']  as int? ?? 0,
      bookingCount:  json['booking_count'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      isFeatured:    json['is_featured']   as bool? ?? false,
      extras:       (json['extras']        as Map<String, dynamic>?) ?? {},
      location:     loc,
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  // ── To Firestore JSON ─────────────────────────────
  Map<String, dynamic> toFirestore() => {
    'id':              id,
    'partner_id':      partnerId,
    'partner_name':    partnerName,
    'partner_name_ar': partnerNameAr,
    'name':            name,
    'name_ar':         nameAr,
    'description':     description,
    'description_ar':  descriptionAr,
    'service_type':    serviceType.firestoreKey,
    'status':          status.name,
    'price':           price,
    'currency':        currency,
    'image_urls':      imageUrls,
    'rating':          rating,
    'review_count':    reviewCount,
    'booking_count':   bookingCount,
    'total_revenue':   totalRevenue,
    'is_featured':     isFeatured,
    'extras':          extras,
    'location':        location != null
        ? (location as ServiceLocationModel).toJson()
        : null,
    'created_at':      Timestamp.fromDate(createdAt),
    'updated_at':      Timestamp.fromDate(updatedAt),
    // denormalized search fields for Firestore queries
    'search_terms': [
      name.toLowerCase(),
      nameAr,
      serviceType.firestoreKey,
      partnerId,
    ],
  };

  static DateTime _parseTimestamp(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}
