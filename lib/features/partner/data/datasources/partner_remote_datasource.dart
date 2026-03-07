import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/partner_service.dart';
import '../models/partner_service_model.dart';

// ════════════════════════════════════════════════════════════
//  Abstract Interface
// ════════════════════════════════════════════════════════════
abstract class PartnerRemoteDataSource {
  Future<PartnerServiceModel> addService({
    required PartnerServiceModel service,
    required List<File> images,
  });

  Future<PartnerServiceModel> updateService({
    required PartnerServiceModel service,
    List<File>? newImages,
  });

  Future<void> deleteService(String serviceId);

  Stream<List<PartnerServiceModel>> watchPartnerServices(String partnerId);

  Future<List<PartnerServiceModel>> getPartnerServices(String partnerId);

  Future<PartnerServiceModel> getService(String serviceId);

  Future<Map<String, dynamic>> getPartnerRawStats(String partnerId);

  Future<List<String>> uploadImages({
    required String serviceId,
    required String partnerId,
    required List<File> images,
  });

  Future<void> deleteImage({
    required String serviceId,
    required String imageUrl,
  });
}

// ════════════════════════════════════════════════════════════
//  Implementation
// ════════════════════════════════════════════════════════════
class PartnerRemoteDataSourceImpl implements PartnerRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const _uuid = Uuid();

  // Firestore paths
  static const _servicesCollection = 'services';
  static const _bookingsCollection = 'bookings';

  CollectionReference get _services =>
      _firestore.collection(_servicesCollection);

  PartnerRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore  = firestore ?? FirebaseFirestore.instance,
        _storage    = storage   ?? FirebaseStorage.instance;

  // ─────────────────────────────────────────────────────────
  //  Add Service
  // ─────────────────────────────────────────────────────────
  @override
  Future<PartnerServiceModel> addService({
    required PartnerServiceModel service,
    required List<File> images,
  }) async {
    // 1. Generate ID
    final docRef = _services.doc();
    final id = docRef.id;

    // 2. Upload images to Storage
    final imageUrls = images.isEmpty
        ? <String>[]
        : await uploadImages(
            serviceId: id,
            partnerId: service.partnerId,
            images: images,
          );

    // 3. Build final model with id + image URLs
    final finalService = PartnerServiceModel(
      id:            id,
      partnerId:     service.partnerId,
      partnerName:   service.partnerName,
      partnerNameAr: service.partnerNameAr,
      name:          service.name,
      nameAr:        service.nameAr,
      description:   service.description,
      descriptionAr: service.descriptionAr,
      serviceType:   service.serviceType,
      status:        ServiceStatus.pending, // always starts as pending
      price:         service.price,
      currency:      service.currency,
      imageUrls:     imageUrls,
      location:      service.location,
      extras:        service.extras,
      createdAt:     DateTime.now(),
      updatedAt:     DateTime.now(),
    );

    // 4. Save to Firestore: services/{id}
    await docRef.set(finalService.toFirestore());

    // 5. Also update partner stats counter
    await _incrementPartnerServiceCount(service.partnerId);

    return finalService;
  }

  // ─────────────────────────────────────────────────────────
  //  Update Service
  // ─────────────────────────────────────────────────────────
  @override
  Future<PartnerServiceModel> updateService({
    required PartnerServiceModel service,
    List<File>? newImages,
  }) async {
    List<String> updatedImageUrls = List.from(service.imageUrls);

    // Upload any new images
    if (newImages != null && newImages.isNotEmpty) {
      final newUrls = await uploadImages(
        serviceId: service.id,
        partnerId: service.partnerId,
        images: newImages,
      );
      updatedImageUrls.addAll(newUrls);
    }

    final updated = PartnerServiceModel(
      id:            service.id,
      partnerId:     service.partnerId,
      partnerName:   service.partnerName,
      partnerNameAr: service.partnerNameAr,
      name:          service.name,
      nameAr:        service.nameAr,
      description:   service.description,
      descriptionAr: service.descriptionAr,
      serviceType:   service.serviceType,
      status:        service.status,
      price:         service.price,
      currency:      service.currency,
      imageUrls:     updatedImageUrls,
      location:      service.location,
      rating:        service.rating,
      reviewCount:   service.reviewCount,
      bookingCount:  service.bookingCount,
      totalRevenue:  service.totalRevenue,
      isFeatured:    service.isFeatured,
      extras:        service.extras,
      createdAt:     service.createdAt,
      updatedAt:     DateTime.now(),
    );

    await _services.doc(service.id).update(updated.toFirestore());
    return updated;
  }

  // ─────────────────────────────────────────────────────────
  //  Delete Service
  // ─────────────────────────────────────────────────────────
  @override
  Future<void> deleteService(String serviceId) async {
    // Get service to find partner ID
    final doc = await _services.doc(serviceId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final partnerId = data['partner_id'] as String? ?? '';

      // Delete all images from Storage
      final imageUrls = List<String>.from(data['image_urls'] as List? ?? []);
      for (final url in imageUrls) {
        try {
          await _storage.refFromURL(url).delete();
        } catch (_) {} // ignore if already deleted
      }

      // Delete Firestore document
      await _services.doc(serviceId).delete();

      // Decrement partner service count
      if (partnerId.isNotEmpty) {
        await _decrementPartnerServiceCount(partnerId);
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Watch Services (real-time stream)
  // ─────────────────────────────────────────────────────────
  @override
  Stream<List<PartnerServiceModel>> watchPartnerServices(String partnerId) {
    return _services
        .where('partner_id', isEqualTo: partnerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PartnerServiceModel.fromFirestore(doc))
            .toList());
  }

  // ─────────────────────────────────────────────────────────
  //  Get Services Once
  // ─────────────────────────────────────────────────────────
  @override
  Future<List<PartnerServiceModel>> getPartnerServices(String partnerId) async {
    final snap = await _services
        .where('partner_id', isEqualTo: partnerId)
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs
        .map((doc) => PartnerServiceModel.fromFirestore(doc))
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  //  Get Single Service
  // ─────────────────────────────────────────────────────────
  @override
  Future<PartnerServiceModel> getService(String serviceId) async {
    final doc = await _services.doc(serviceId).get();
    if (!doc.exists) throw Exception('service-not-found');
    return PartnerServiceModel.fromFirestore(doc);
  }

  // ─────────────────────────────────────────────────────────
  //  Get Partner Stats
  // ─────────────────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> getPartnerRawStats(String partnerId) async {
    // Aggregate from services collection
    final servicesSnap = await _services
        .where('partner_id', isEqualTo: partnerId)
        .get();

    int totalBookings = 0;
    int pendingBookings = 0;
    double totalRevenue = 0;
    double totalRating = 0;
    int ratedServices = 0;
    int activeServices = 0;

    for (final doc in servicesSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalBookings  += (data['booking_count'] as int? ?? 0);
      totalRevenue   += (data['total_revenue'] as num? ?? 0).toDouble();
      final rating    = (data['rating'] as num? ?? 0).toDouble();
      if (rating > 0) { totalRating += rating; ratedServices++; }
      if (data['status'] == 'active') activeServices++;
    }

    // Get pending bookings from bookings collection
    try {
      final bookSnap = await _firestore
          .collection(_bookingsCollection)
          .where('partner_id', isEqualTo: partnerId)
          .where('status', isEqualTo: 'pending')
          .get();
      pendingBookings = bookSnap.docs.length;
    } catch (_) {}

    return {
      'total_services':       servicesSnap.docs.length,
      'active_services':      activeServices,
      'total_bookings':       totalBookings,
      'pending_bookings':     pendingBookings,
      'total_revenue':        totalRevenue,
      'average_rating':       ratedServices > 0 ? totalRating / ratedServices : 0.0,
    };
  }

  // ─────────────────────────────────────────────────────────
  //  Upload Images to Firebase Storage
  // ─────────────────────────────────────────────────────────
  @override
  Future<List<String>> uploadImages({
    required String serviceId,
    required String partnerId,
    required List<File> images,
  }) async {
    final List<String> urls = [];

    for (final image in images) {
      final imageId = _uuid.v4();
      // Path: services/{partnerId}/{serviceId}/{imageId}.jpg
      final ref = _storage
          .ref()
          .child('services')
          .child(partnerId)
          .child(serviceId)
          .child('$imageId.jpg');

      final task = await ref.putFile(
        image,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await task.ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  // ─────────────────────────────────────────────────────────
  //  Delete Single Image from Storage
  // ─────────────────────────────────────────────────────────
  @override
  Future<void> deleteImage({
    required String serviceId,
    required String imageUrl,
  }) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
      await _services.doc(serviceId).update({
        'image_urls': FieldValue.arrayRemove([imageUrl]),
      });
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Helper: Update partner stats counter in users collection
  // ─────────────────────────────────────────────────────────
  Future<void> _incrementPartnerServiceCount(String partnerId) async {
    try {
      await _firestore.collection('users').doc(partnerId).update({
        'partner_info.total_services': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  Future<void> _decrementPartnerServiceCount(String partnerId) async {
    try {
      await _firestore.collection('users').doc(partnerId).update({
        'partner_info.total_services': FieldValue.increment(-1),
      });
    } catch (_) {}
  }
}
