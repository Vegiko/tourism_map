import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../domain/entities/partner_service.dart';
import '../../domain/repositories/partner_repository.dart';
import '../datasources/partner_remote_datasource.dart';
import '../models/partner_service_model.dart';

class PartnerRepositoryImpl implements PartnerRepository {
  final PartnerRemoteDataSource _remote;

  PartnerRepositoryImpl(this._remote);

  // ── Add ────────────────────────────────────────
  @override
  Future<Either<PartnerFailure, PartnerService>> addService({
    required PartnerService service,
    required List<File> images,
  }) async {
    try {
      final model = _toModel(service);
      final result = await _remote.addService(service: model, images: images);
      return Right(result);
    } catch (e) {
      return Left(PartnerFailure(_mapError(e)));
    }
  }

  // ── Update ─────────────────────────────────────
  @override
  Future<Either<PartnerFailure, PartnerService>> updateService({
    required PartnerService service,
    List<File>? newImages,
  }) async {
    try {
      final model = _toModel(service);
      final result = await _remote.updateService(
          service: model, newImages: newImages);
      return Right(result);
    } catch (e) {
      return Left(PartnerFailure(_mapError(e)));
    }
  }

  // ── Delete ─────────────────────────────────────
  @override
  Future<Either<PartnerFailure, Unit>> deleteService(
      String serviceId) async {
    try {
      await _remote.deleteService(serviceId);
      return const Right(unit);
    } catch (e) {
      return Left(PartnerFailure(_mapError(e)));
    }
  }

  // ── Watch Stream ───────────────────────────────
  @override
  Stream<List<PartnerService>> watchPartnerServices(String partnerId) {
    return _remote
        .watchPartnerServices(partnerId)
        .map((list) => list.cast<PartnerService>());
  }

  // ── Get Once ───────────────────────────────────
  @override
  Future<Either<PartnerFailure, List<PartnerService>>> getPartnerServices(
      String partnerId) async {
    try {
      final list = await _remote.getPartnerServices(partnerId);
      return Right(list.cast<PartnerService>());
    } catch (e) {
      return Left(PartnerFailure(_mapError(e)));
    }
  }

  // ── Get Single ─────────────────────────────────
  @override
  Future<Either<PartnerFailure, PartnerService>> getService(
      String serviceId) async {
    try {
      final s = await _remote.getService(serviceId);
      return Right(s);
    } catch (e) {
      return Left(PartnerFailure(_mapError(e)));
    }
  }

  // ── Stats ──────────────────────────────────────
  @override
  Future<Either<PartnerFailure, PartnerStats>> getPartnerStats(
      String partnerId) async {
    try {
      final raw = await _remote.getPartnerRawStats(partnerId);
      return Right(_parseStats(raw));
    } catch (e) {
      return Left(PartnerFailure(_mapError(e)));
    }
  }

  @override
  Stream<PartnerStats> watchPartnerStats(String partnerId) {
    return _remote.watchPartnerServices(partnerId).map((services) {
      int totalBookings = 0;
      double totalRevenue = 0;
      double totalRating = 0;
      int ratedCount = 0;
      int activeCount = 0;

      for (final s in services) {
        totalBookings += s.bookingCount;
        totalRevenue  += s.totalRevenue;
        if (s.rating > 0) { totalRating += s.rating; ratedCount++; }
        if (s.isActive) activeCount++;
      }

      return PartnerStats(
        totalServices:   services.length,
        activeServices:  activeCount,
        totalBookings:   totalBookings,
        totalRevenue:    totalRevenue,
        monthlyRevenue:  totalRevenue * 0.12, // approximation
        averageRating:   ratedCount > 0 ? totalRating / ratedCount : 0,
        totalReviews:    services.fold(0, (sum, s) => sum + s.reviewCount),
      );
    });
  }

  // ── Images ─────────────────────────────────────
  @override
  Future<Either<PartnerFailure, List<String>>> uploadServiceImages({
    required String serviceId,
    required String partnerId,
    required List<File> images,
  }) async {
    try {
      final urls = await _remote.uploadImages(
        serviceId: serviceId,
        partnerId: partnerId,
        images: images,
      );
      return Right(urls);
    } catch (e) {
      return Left(PartnerFailure(_mapError(e)));
    }
  }

  @override
  Future<Either<PartnerFailure, Unit>> deleteServiceImage({
    required String serviceId,
    required String imageUrl,
  }) async {
    try {
      await _remote.deleteImage(serviceId: serviceId, imageUrl: imageUrl);
      return const Right(unit);
    } catch (e) {
      return Left(PartnerFailure(_mapError(e)));
    }
  }

  // ── Helpers ────────────────────────────────────
  PartnerServiceModel _toModel(PartnerService s) => PartnerServiceModel(
    id:            s.id,
    partnerId:     s.partnerId,
    partnerName:   s.partnerName,
    partnerNameAr: s.partnerNameAr,
    name:          s.name,
    nameAr:        s.nameAr,
    description:   s.description,
    descriptionAr: s.descriptionAr,
    serviceType:   s.serviceType,
    status:        s.status,
    price:         s.price,
    currency:      s.currency,
    imageUrls:     s.imageUrls,
    location:      s.location != null
        ? ServiceLocationModel(
            latitude:  s.location!.latitude,
            longitude: s.location!.longitude,
            address:   s.location!.address,
            addressAr: s.location!.addressAr,
            city:      s.location!.city,
            cityAr:    s.location!.cityAr,
            country:   s.location!.country,
          )
        : null,
    rating:       s.rating,
    reviewCount:  s.reviewCount,
    bookingCount: s.bookingCount,
    totalRevenue: s.totalRevenue,
    isFeatured:   s.isFeatured,
    extras:       s.extras,
    createdAt:    s.createdAt,
    updatedAt:    s.updatedAt,
  );

  PartnerStats _parseStats(Map<String, dynamic> raw) => PartnerStats(
    totalServices:   raw['total_services']   as int?    ?? 0,
    activeServices:  raw['active_services']  as int?    ?? 0,
    totalBookings:   raw['total_bookings']   as int?    ?? 0,
    pendingBookings: raw['pending_bookings'] as int?    ?? 0,
    totalRevenue:   (raw['total_revenue']    as num?)?.toDouble() ?? 0,
    averageRating:  (raw['average_rating']   as num?)?.toDouble() ?? 0,
  );

  String _mapError(Object e) {
    final msg = e.toString();
    if (msg.contains('permission-denied'))   return 'ليس لديك صلاحية لهذا الإجراء';
    if (msg.contains('not-found'))           return 'الخدمة غير موجودة';
    if (msg.contains('network'))             return 'تحقق من اتصالك بالإنترنت';
    if (msg.contains('storage'))             return 'فشل رفع الصور، حاول مرة أخرى';
    return 'حدث خطأ غير متوقع، حاول مرة أخرى';
  }
}
