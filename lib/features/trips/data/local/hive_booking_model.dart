import 'package:hive/hive.dart';
import 'package:tourism_app/features/trips/domain/entities/local_booking.dart';
import '../../domain/entities/booking.dart';

// ════════════════════════════════════════════════════════════
//  Hive Type IDs  (must be globally unique across the app)
// ════════════════════════════════════════════════════════════
//  0 → BookingHiveModel
//  1 → BookingLocationHiveModel

// ════════════════════════════════════════════════════════════
//  BookingLocationHiveModel
// ════════════════════════════════════════════════════════════
class BookingLocationHiveModel {
  final double latitude;
  final double longitude;
  final String address;
  final String addressAr;
  final String city;
  final String cityAr;
  final String country;

  const BookingLocationHiveModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.addressAr,
    required this.city,
    required this.cityAr,
    required this.country,
  });

  BookingLocation toDomain() => BookingLocation(
    latitude: latitude, longitude: longitude,
    address: address, addressAr: addressAr,
    city: city, cityAr: cityAr, country: country,
  );

  factory BookingLocationHiveModel.fromDomain(BookingLocation l) =>
      BookingLocationHiveModel(
        latitude: l.latitude, longitude: l.longitude,
        address: l.address, addressAr: l.addressAr,
        city: l.city, cityAr: l.cityAr, country: l.country,
      );
}

// ── TypeAdapter ─────────────────────────────────
class BookingLocationAdapter extends TypeAdapter<BookingLocationHiveModel> {
  @override
  final typeId = 1;

  @override
  BookingLocationHiveModel read(BinaryReader reader) {
    return BookingLocationHiveModel(
      latitude:  reader.readDouble(),
      longitude: reader.readDouble(),
      address:   reader.readString(),
      addressAr: reader.readString(),
      city:      reader.readString(),
      cityAr:    reader.readString(),
      country:   reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, BookingLocationHiveModel obj) {
    writer.writeDouble(obj.latitude);
    writer.writeDouble(obj.longitude);
    writer.writeString(obj.address);
    writer.writeString(obj.addressAr);
    writer.writeString(obj.city);
    writer.writeString(obj.cityAr);
    writer.writeString(obj.country);
  }
}

// ════════════════════════════════════════════════════════════
//  BookingHiveModel
// ════════════════════════════════════════════════════════════
class BookingHiveModel {
  final String id;
  final String userId;
  final String partnerId;
  final String serviceId;
  final int serviceTypeIndex;   // BookingServiceType.index
  final int statusIndex;        // BookingStatus.index
  final String serviceName;
  final String serviceNameAr;
  final String providerName;
  final String providerNameAr;
  final String primaryImageUrl;
  final List<String> imageUrls;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final int rooms;
  final double totalPrice;
  final String currency;
  final String confirmationCode;
  final String qrData;
  final BookingLocationHiveModel location;
  final String notes;
  final String notesAr;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  const BookingHiveModel({
    required this.id,
    required this.userId,
    required this.partnerId,
    required this.serviceId,
    required this.serviceTypeIndex,
    required this.statusIndex,
    required this.serviceName,
    required this.serviceNameAr,
    required this.providerName,
    required this.providerNameAr,
    required this.primaryImageUrl,
    required this.imageUrls,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.rooms,
    required this.totalPrice,
    required this.currency,
    required this.confirmationCode,
    required this.qrData,
    required this.location,
    required this.notes,
    required this.notesAr,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
  });

  // ── Domain ↔ Hive conversions ──────────────────
  Booking toDomain() => Booking(
    id: id, userId: userId, partnerId: partnerId, serviceId: serviceId,
    serviceType: BookingServiceType.values[serviceTypeIndex],
    status: BookingStatus.values[statusIndex],
    serviceName: serviceName, serviceNameAr: serviceNameAr,
    providerName: providerName, providerNameAr: providerNameAr,
    primaryImageUrl: primaryImageUrl, imageUrls: imageUrls,
    checkIn: checkIn, checkOut: checkOut, guests: guests, rooms: rooms,
    totalPrice: totalPrice, currency: currency,
    confirmationCode: confirmationCode, qrData: qrData,
    location: location.toDomain(),
    notes: notes, notesAr: notesAr,
    isOfflineCached: true,
    createdAt: createdAt, updatedAt: updatedAt, syncedAt: syncedAt,
  );

  factory BookingHiveModel.fromDomain(Booking b) => BookingHiveModel(
    id: b.id, userId: b.userId, partnerId: b.partnerId, serviceId: b.serviceId,
    serviceTypeIndex: b.serviceType.index,
    statusIndex: b.status.index,
    serviceName: b.serviceName, serviceNameAr: b.serviceNameAr,
    providerName: b.providerName, providerNameAr: b.providerNameAr,
    primaryImageUrl: b.primaryImageUrl, imageUrls: b.imageUrls,
    checkIn: b.checkIn, checkOut: b.checkOut, guests: b.guests, rooms: b.rooms,
    totalPrice: b.totalPrice, currency: b.currency,
    confirmationCode: b.confirmationCode, qrData: b.qrData,
    location: BookingLocationHiveModel.fromDomain(b.location),
    notes: b.notes, notesAr: b.notesAr,
    createdAt: b.createdAt, updatedAt: b.updatedAt, syncedAt: b.syncedAt,
  );
}

// ── TypeAdapter ─────────────────────────────────
class BookingHiveAdapter extends TypeAdapter<BookingHiveModel> {
  @override
  final typeId = 0;

  @override
  BookingHiveModel read(BinaryReader reader) {
    return BookingHiveModel(
      id:                reader.readString(),
      userId:            reader.readString(),
      partnerId:         reader.readString(),
      serviceId:         reader.readString(),
      serviceTypeIndex:  reader.readInt(),
      statusIndex:       reader.readInt(),
      serviceName:       reader.readString(),
      serviceNameAr:     reader.readString(),
      providerName:      reader.readString(),
      providerNameAr:    reader.readString(),
      primaryImageUrl:   reader.readString(),
      imageUrls:         List<String>.from(reader.readList()),
      checkIn:           DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      checkOut:          DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      guests:            reader.readInt(),
      rooms:             reader.readInt(),
      totalPrice:        reader.readDouble(),
      currency:          reader.readString(),
      confirmationCode:  reader.readString(),
      qrData:            reader.readString(),
      location:          reader.read() as BookingLocationHiveModel,
      notes:             reader.readString(),
      notesAr:           reader.readString(),
      createdAt:         DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt:         DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      syncedAt:          reader.readBool()
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, BookingHiveModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.userId);
    writer.writeString(obj.partnerId);
    writer.writeString(obj.serviceId);
    writer.writeInt(obj.serviceTypeIndex);
    writer.writeInt(obj.statusIndex);
    writer.writeString(obj.serviceName);
    writer.writeString(obj.serviceNameAr);
    writer.writeString(obj.providerName);
    writer.writeString(obj.providerNameAr);
    writer.writeString(obj.primaryImageUrl);
    writer.writeList(obj.imageUrls);
    writer.writeInt(obj.checkIn.millisecondsSinceEpoch);
    writer.writeInt(obj.checkOut.millisecondsSinceEpoch);
    writer.writeInt(obj.guests);
    writer.writeInt(obj.rooms);
    writer.writeDouble(obj.totalPrice);
    writer.writeString(obj.currency);
    writer.writeString(obj.confirmationCode);
    writer.writeString(obj.qrData);
    writer.write(obj.location);
    writer.writeString(obj.notes);
    writer.writeString(obj.notesAr);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
    if (obj.syncedAt != null) {
      writer.writeBool(true);
      writer.writeInt(obj.syncedAt!.millisecondsSinceEpoch);
    } else {
      writer.writeBool(false);
    }
  }
}
