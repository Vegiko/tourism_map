import 'package:equatable/equatable.dart';

// ──────────────────────────────────────────────────────────────
//  UserRole Enum
// ──────────────────────────────────────────────────────────────
enum UserRole {
  admin,
  traveler,  // مسافر
  partner,   // شريك (فندق / وكالة)
}

extension UserRoleX on UserRole {
  String get nameAr {
    switch (this) {
      case UserRole.admin:
        return 'مسؤول';
      case UserRole.traveler:
        return 'مسافر';
      case UserRole.partner:
        return 'شريك أعمال';
    }
  }

  String get nameEn {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.traveler:
        return 'Traveler';
      case UserRole.partner:
        return 'Partner';
    }
  }

  String get descriptionAr {
    switch (this) {
      case UserRole.admin:
        return 'إدارة النظام والمستخدمين';
      case UserRole.traveler:
        return 'ابحث عن وجهات رائعة واحجز رحلاتك بسهولة';
      case UserRole.partner:
        return 'أدر فندقك أو وكالتك وصل إلى آلاف المسافرين';
    }
  }

  String get descriptionEn {
    switch (this) {
      case UserRole.admin:
        return 'Manage system and users';
      case UserRole.traveler:
        return 'Discover amazing destinations and book trips easily';
      case UserRole.partner:
        return 'Manage your hotel or agency and reach thousands of travelers';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'partner':
        return UserRole.partner;
      default:
        return UserRole.traveler;
    }
  }
}

// ──────────────────────────────────────────────────────────────
//  PartnerType Enum
// ──────────────────────────────────────────────────────────────
enum PartnerType { hotel, travelAgency, tourGuide, restaurant }

extension PartnerTypeX on PartnerType {
  String get nameAr {
    switch (this) {
      case PartnerType.hotel:
        return 'فندق';
      case PartnerType.travelAgency:
        return 'وكالة سفر';
      case PartnerType.tourGuide:
        return 'مرشد سياحي';
      case PartnerType.restaurant:
        return 'مطعم';
    }
  }

  String get nameEn {
    switch (this) {
      case PartnerType.hotel:
        return 'Hotel';
      case PartnerType.travelAgency:
        return 'Travel Agency';
      case PartnerType.tourGuide:
        return 'Tour Guide';
      case PartnerType.restaurant:
        return 'Restaurant';
    }
  }

  static PartnerType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'travel_agency':
        return PartnerType.travelAgency;
      case 'tour_guide':
        return PartnerType.tourGuide;
      case 'restaurant':
        return PartnerType.restaurant;
      default:
        return PartnerType.hotel;
    }
  }
}

// ──────────────────────────────────────────────────────────────
//  AppUser Entity
// ──────────────────────────────────────────────────────────────
class AppUser extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  // Traveler-specific
  final int tripsCount;
  final List<String> savedDestinations;

  // Partner-specific
  final PartnerInfo? partnerInfo;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    this.emailVerified = false,
    required this.createdAt,
    this.lastLoginAt,
    this.tripsCount = 0,
    this.savedDestinations = const [],
    this.partnerInfo,
  });
  
  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        photoUrl,
        role,
        emailVerified,
        createdAt,
        lastLoginAt,
        tripsCount,
        savedDestinations,
        partnerInfo,
      ];
  
  bool get isPartner => role == UserRole.partner;
  bool get isTraveler => role == UserRole.traveler;
  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
    DateTime? lastLoginAt,
    int? tripsCount,
    List<String>? savedDestinations,
    PartnerInfo? partnerInfo,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      tripsCount: tripsCount ?? this.tripsCount,
      savedDestinations: savedDestinations ?? this.savedDestinations,
      partnerInfo: partnerInfo ?? this.partnerInfo,
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  PartnerInfo  (nested entity for partners only)
// ──────────────────────────────────────────────────────────────
class PartnerInfo extends Equatable {
  final String businessName;
  final String businessNameAr;
  final PartnerType partnerType;
  final String? businessPhone;
  final String? businessAddress;
  final String? businessLogoUrl;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final int totalBookings;
  final bool isActive;

  const PartnerInfo({
    required this.businessName,
    required this.businessNameAr,
    required this.partnerType,
    this.businessPhone,
    this.businessAddress,
    this.businessLogoUrl,
    this.isVerified = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.totalBookings = 0,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [businessName, partnerType];
}

// ──────────────────────────────────────────────────────────────
//  Auth Failure
// ──────────────────────────────────────────────────────────────
class AuthFailure extends Equatable {
  final String message;
  final String? code;

  const AuthFailure({required this.message, this.code});

  factory AuthFailure.fromFirebaseCode(String code) {
    final messages = {
      'user-not-found': 'لا يوجد حساب بهذا البريد الإلكتروني',
      'wrong-password': 'كلمة المرور غير صحيحة',
      'email-already-in-use': 'هذا البريد الإلكتروني مستخدم بالفعل',
      'weak-password': 'كلمة المرور ضعيفة، استخدم 6 أحرف على الأقل',
      'invalid-email': 'البريد الإلكتروني غير صحيح',
      'too-many-requests': 'محاولات كثيرة، يرجى المحاولة لاحقاً',
      'network-request-failed': 'تحقق من اتصالك بالإنترنت',
      'user-disabled': 'هذا الحساب معطل، تواصل مع الدعم',
      'operation-not-allowed': 'هذه العملية غير مسموح بها',
      'requires-recent-login': 'يرجى إعادة تسجيل الدخول للمتابعة',
    };
    return AuthFailure(
      message: messages[code] ?? 'حدث خطأ غير متوقع، يرجى المحاولة مجدداً',
      code: code,
    );
  }

  @override
  List<Object?> get props => [message, code];
}
