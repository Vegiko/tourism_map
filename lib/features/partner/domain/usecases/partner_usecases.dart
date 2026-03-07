import 'dart:io';
import 'package:dartz/dartz.dart';
import '../entities/partner_service.dart';
import '../repositories/partner_repository.dart';

// ── Add Service ────────────────────────────────────────────
class AddServiceParams {
  final PartnerService service;
  final List<File> images;
  const AddServiceParams({required this.service, required this.images});
}

class AddService {
  final PartnerRepository repository;
  AddService(this.repository);

  Future<Either<PartnerFailure, PartnerService>> call(AddServiceParams p) =>
      repository.addService(service: p.service, images: p.images);
}

// ── Update Service ─────────────────────────────────────────
class UpdateServiceParams {
  final PartnerService service;
  final List<File>? newImages;
  const UpdateServiceParams({required this.service, this.newImages});
}

class UpdateService {
  final PartnerRepository repository;
  UpdateService(this.repository);

  Future<Either<PartnerFailure, PartnerService>> call(UpdateServiceParams p) =>
      repository.updateService(service: p.service, newImages: p.newImages);
}

// ── Delete Service ─────────────────────────────────────────
class DeleteService {
  final PartnerRepository repository;
  DeleteService(this.repository);

  Future<Either<PartnerFailure, Unit>> call(String serviceId) =>
      repository.deleteService(serviceId);
}

// ── Watch Services Stream ──────────────────────────────────
class WatchPartnerServices {
  final PartnerRepository repository;
  WatchPartnerServices(this.repository);

  Stream<List<PartnerService>> call(String partnerId) =>
      repository.watchPartnerServices(partnerId);
}

// ── Get Services Once ──────────────────────────────────────
class GetPartnerServices {
  final PartnerRepository repository;
  GetPartnerServices(this.repository);

  Future<Either<PartnerFailure, List<PartnerService>>> call(String partnerId) =>
      repository.getPartnerServices(partnerId);
}

// ── Watch Stats ────────────────────────────────────────────
class WatchPartnerStats {
  final PartnerRepository repository;
  WatchPartnerStats(this.repository);

  Stream<PartnerStats> call(String partnerId) =>
      repository.watchPartnerStats(partnerId);
}

// ── Upload Images ──────────────────────────────────────────
class UploadServiceImagesParams {
  final String serviceId;
  final String partnerId;
  final List<File> images;
  const UploadServiceImagesParams({
    required this.serviceId,
    required this.partnerId,
    required this.images,
  });
}

class UploadServiceImages {
  final PartnerRepository repository;
  UploadServiceImages(this.repository);

  Future<Either<PartnerFailure, List<String>>> call(
    UploadServiceImagesParams p,
  ) => repository.uploadServiceImages(
        serviceId: p.serviceId,
        partnerId: p.partnerId,
        images: p.images,
      );
}
