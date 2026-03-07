import 'dart:io';
import 'package:dartz/dartz.dart';
import '../entities/partner_service.dart';

abstract class PartnerRepository {
  // ── Services CRUD ──────────────────────────────
  Future<Either<PartnerFailure, PartnerService>> addService({
    required PartnerService service,
    required List<File> images,
  });

  Future<Either<PartnerFailure, PartnerService>> updateService({
    required PartnerService service,
    List<File>? newImages,
  });

  Future<Either<PartnerFailure, Unit>> deleteService(String serviceId);

  Stream<List<PartnerService>> watchPartnerServices(String partnerId);

  Future<Either<PartnerFailure, List<PartnerService>>> getPartnerServices(
    String partnerId,
  );

  Future<Either<PartnerFailure, PartnerService>> getService(String serviceId);

  // ── Stats ──────────────────────────────────────
  Future<Either<PartnerFailure, PartnerStats>> getPartnerStats(
    String partnerId,
  );

  Stream<PartnerStats> watchPartnerStats(String partnerId);

  // ── Image Upload ───────────────────────────────
  Future<Either<PartnerFailure, List<String>>> uploadServiceImages({
    required String serviceId,
    required String partnerId,
    required List<File> images,
  });

  Future<Either<PartnerFailure, Unit>> deleteServiceImage({
    required String serviceId,
    required String imageUrl,
  });
}
