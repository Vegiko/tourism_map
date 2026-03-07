import 'dart:convert';
import 'package:hive/hive.dart';
import '../../domain/entities/local_booking.dart';

// ════════════════════════════════════════════════════════════
//  Hive Box Names
// ════════════════════════════════════════════════════════════
class HiveBoxNames {
  static const String bookings = 'bookings_box';
  static const String settings = 'settings_box';
  static const String offlineQueue = 'offline_queue_box';
}

// ════════════════════════════════════════════════════════════
//  HiveBooking Model (flat structure for fast I/O)
//  TypeId = 0
// ════════════════════════════════════════════════════════════
class HiveBooking extends HiveObject {
  // ── Required fields ───────────────────────────
  late String id;
  late String confirmationCode;
  late String userId;
  late String serviceId;
  late String serviceName;
  late String serviceNameAr;
  late String serviceTypeKey;
  late String partnerName;
  late String partnerNameAr;

  // ── Dates stored as ms since epoch ────────────
  late int checkInMs;
  late int checkOutMs;
  late int bookedAtMs;

  // ── Guest (stored as JSON string) ─────────────
  late String guestJson;

  // ── Pricing ───────────────────────────────────
  late double totalPrice;
  late double serviceFee;
  late String currency;

  // ── Location ──────────────────────────────────
  late String city;
  late String cityAr;
  late String address;
  late double latitude;
  late double longitude;

  // ── Media ─────────────────────────────────────
  late String coverImageUrl;

  // ── Status ────────────────────────────────────
  late String statusKey;

  // ── QR ────────────────────────────────────────
  late String qrData;

  // ── Extras ────────────────────────────────────
  late String extrasJson;

  // ── Sync ──────────────────────────────────────
  late bool isSyncedToCloud;
  late int lastSyncedAtMs;
  late int updatedAtMs;

  HiveBooking({
    required this.id,
    required this.confirmationCode,
    required this.userId,
    required this.serviceId,
    required this.serviceName,
    required this.serviceNameAr,
    required this.serviceTypeKey,
    required this.partnerName,
    required this.partnerNameAr,
    required this.checkInMs,
    required this.checkOutMs,
    required this.bookedAtMs,
    required this.guestJson,
    required this.totalPrice,
    required this.serviceFee,
    required this.currency,
    required this.city,
    required this.cityAr,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.coverImageUrl,
    required this.statusKey,
    required this.qrData,
    required this.extrasJson,
    required this.isSyncedToCloud,
    required this.lastSyncedAtMs,
    required this.updatedAtMs,
  });

  // ─────────────────────────────────────────────
  //  Convert to/from domain entity
  // ─────────────────────────────────────────────
  LocalBooking toDomain() {
    Map<String, dynamic> guestMap = {};
    Map<String, dynamic> extrasMap = {};
    try { guestMap  = jsonDecode(guestJson)  as Map<String, dynamic>; } catch (_) {}
    try { extrasMap = jsonDecode(extrasJson) as Map<String, dynamic>; } catch (_) {}

    return LocalBooking(
      id:               id,
      confirmationCode: confirmationCode,
      userId:           userId,
      serviceId:        serviceId,
      serviceName:      serviceName,
      serviceNameAr:    serviceNameAr,
      serviceType:      BookingServiceTypeX.fromString(serviceTypeKey),
      partnerName:      partnerName,
      partnerNameAr:    partnerNameAr,
      checkIn:          DateTime.fromMillisecondsSinceEpoch(checkInMs),
      checkOut:         DateTime.fromMillisecondsSinceEpoch(checkOutMs),
      bookedAt:         DateTime.fromMillisecondsSinceEpoch(bookedAtMs),
      guest:            BookingGuest.fromJson(guestMap),
      totalPrice:       totalPrice,
      serviceFee:       serviceFee,
      currency:         currency,
      city:             city,
      cityAr:           cityAr,
      address:          address,
      latitude:         latitude,
      longitude:        longitude,
      coverImageUrl:    coverImageUrl,
      status:           BookingStatusX.fromString(statusKey),
      qrData:           qrData,
      extras:           extrasMap,
      isSyncedToCloud:  isSyncedToCloud,
      lastSyncedAt:     DateTime.fromMillisecondsSinceEpoch(lastSyncedAtMs),
      updatedAt:        DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
    );
  }

  factory HiveBooking.fromDomain(LocalBooking b) => HiveBooking(
    id:               b.id,
    confirmationCode: b.confirmationCode,
    userId:           b.userId,
    serviceId:        b.serviceId,
    serviceName:      b.serviceName,
    serviceNameAr:    b.serviceNameAr,
    serviceTypeKey:   b.serviceType.storageKey,
    partnerName:      b.partnerName,
    partnerNameAr:    b.partnerNameAr,
    checkInMs:        b.checkIn.millisecondsSinceEpoch,
    checkOutMs:       b.checkOut.millisecondsSinceEpoch,
    bookedAtMs:       b.bookedAt.millisecondsSinceEpoch,
    guestJson:        jsonEncode(b.guest.toJson()),
    totalPrice:       b.totalPrice,
    serviceFee:       b.serviceFee,
    currency:         b.currency,
    city:             b.city,
    cityAr:           b.cityAr,
    address:          b.address,
    latitude:         b.latitude,
    longitude:        b.longitude,
    coverImageUrl:    b.coverImageUrl,
    statusKey:        b.status.name,
    qrData:           b.qrData,
    extrasJson:       jsonEncode(b.extras),
    isSyncedToCloud:  b.isSyncedToCloud,
    lastSyncedAtMs:   b.lastSyncedAt.millisecondsSinceEpoch,
    updatedAtMs:      b.updatedAt.millisecondsSinceEpoch,
  );
}

// ════════════════════════════════════════════════════════════
//  Manual TypeAdapter (avoids build_runner dependency)
// ════════════════════════════════════════════════════════════
class HiveBookingAdapter extends TypeAdapter<HiveBooking> {
  @override
  final int typeId = 0;

  @override
  HiveBooking read(BinaryReader reader) {
    return HiveBooking(
      id:               reader.readString(),
      confirmationCode: reader.readString(),
      userId:           reader.readString(),
      serviceId:        reader.readString(),
      serviceName:      reader.readString(),
      serviceNameAr:    reader.readString(),
      serviceTypeKey:   reader.readString(),
      partnerName:      reader.readString(),
      partnerNameAr:    reader.readString(),
      checkInMs:        reader.readInt(),
      checkOutMs:       reader.readInt(),
      bookedAtMs:       reader.readInt(),
      guestJson:        reader.readString(),
      totalPrice:       reader.readDouble(),
      serviceFee:       reader.readDouble(),
      currency:         reader.readString(),
      city:             reader.readString(),
      cityAr:           reader.readString(),
      address:          reader.readString(),
      latitude:         reader.readDouble(),
      longitude:        reader.readDouble(),
      coverImageUrl:    reader.readString(),
      statusKey:        reader.readString(),
      qrData:           reader.readString(),
      extrasJson:       reader.readString(),
      isSyncedToCloud:  reader.readBool(),
      lastSyncedAtMs:   reader.readInt(),
      updatedAtMs:      reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveBooking obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.confirmationCode);
    writer.writeString(obj.userId);
    writer.writeString(obj.serviceId);
    writer.writeString(obj.serviceName);
    writer.writeString(obj.serviceNameAr);
    writer.writeString(obj.serviceTypeKey);
    writer.writeString(obj.partnerName);
    writer.writeString(obj.partnerNameAr);
    writer.writeInt(obj.checkInMs);
    writer.writeInt(obj.checkOutMs);
    writer.writeInt(obj.bookedAtMs);
    writer.writeString(obj.guestJson);
    writer.writeDouble(obj.totalPrice);
    writer.writeDouble(obj.serviceFee);
    writer.writeString(obj.currency);
    writer.writeString(obj.city);
    writer.writeString(obj.cityAr);
    writer.writeString(obj.address);
    writer.writeDouble(obj.latitude);
    writer.writeDouble(obj.longitude);
    writer.writeString(obj.coverImageUrl);
    writer.writeString(obj.statusKey);
    writer.writeString(obj.qrData);
    writer.writeString(obj.extrasJson);
    writer.writeBool(obj.isSyncedToCloud);
    writer.writeInt(obj.lastSyncedAtMs);
    writer.writeInt(obj.updatedAtMs);
  }
}
