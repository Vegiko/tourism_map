import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_user.dart';

// ──────────────────────────────────────────────────────────────
//  PartnerInfo Model
// ──────────────────────────────────────────────────────────────
class PartnerInfoModel extends PartnerInfo {
  const PartnerInfoModel({
    required super.businessName,
    required super.businessNameAr,
    required super.partnerType,
    super.businessPhone,
    super.businessAddress,
    super.businessLogoUrl,
    super.isVerified,
    super.rating,
    super.reviewCount,
    super.totalBookings,
    super.isActive,
  });

  factory PartnerInfoModel.fromJson(Map<String, dynamic> json) {
    return PartnerInfoModel(
      businessName: json['business_name'] as String? ?? '',
      businessNameAr: json['business_name_ar'] as String? ?? '',
      partnerType: PartnerTypeX.fromString(
        json['partner_type'] as String? ?? 'hotel',
      ),
      businessPhone: json['business_phone'] as String?,
      businessAddress: json['business_address'] as String?,
      businessLogoUrl: json['business_logo_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      totalBookings: json['total_bookings'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'business_name': businessName,
        'business_name_ar': businessNameAr,
        'partner_type': partnerType.name,
        'business_phone': businessPhone,
        'business_address': businessAddress,
        'business_logo_url': businessLogoUrl,
        'is_verified': isVerified,
        'rating': rating,
        'review_count': reviewCount,
        'total_bookings': totalBookings,
        'is_active': isActive,
      };
}

// ──────────────────────────────────────────────────────────────
//  AppUser Model
// ──────────────────────────────────────────────────────────────
class AppUserModel extends AppUser {
  const AppUserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    super.photoUrl,
    required super.role,
    super.emailVerified,
    required super.createdAt,
    super.lastLoginAt,
    super.tripsCount,
    super.savedDestinations,
    super.partnerInfo,
  });

  // ── From Firestore DocumentSnapshot ───────────
  factory AppUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUserModel.fromJson({...data, 'uid': doc.id});
  }

  // ── From Map ───────────────────────────────────
  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      role: UserRoleX.fromString(json['role'] as String? ?? 'traveler'),
      emailVerified: json['email_verified'] as bool? ?? false,
      createdAt: _parseTimestamp(json['created_at']) ?? DateTime.now(),
      lastLoginAt: _parseTimestamp(json['last_login_at']),
      tripsCount: json['trips_count'] as int? ?? 0,
      savedDestinations: List<String>.from(
        json['saved_destinations'] as List? ?? [],
      ),
      partnerInfo: json['partner_info'] != null
          ? PartnerInfoModel.fromJson(
              json['partner_info'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  // ── To Firestore Map ───────────────────────────
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'role': role.name,
      'email_verified': emailVerified,
      'created_at': Timestamp.fromDate(createdAt),
      'last_login_at':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'trips_count': tripsCount,
      'saved_destinations': savedDestinations,
    };

    if (partnerInfo != null) {
      map['partner_info'] = (partnerInfo as PartnerInfoModel).toJson();
    }

    return map;
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
