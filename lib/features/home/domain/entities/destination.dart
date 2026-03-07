import 'package:equatable/equatable.dart';

// ──────────────────────────────────────────────
//  Destination Entity
// ──────────────────────────────────────────────
class Destination extends Equatable {
  final String id;
  final String name;
  final String nameAr;
  final String country;
  final String countryAr;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final double priceFrom;
  final bool isFeatured;
  final bool isTrending;
  final DestinationCategory category;
  final String description;
  final String descriptionAr;

  const Destination({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.country,
    required this.countryAr,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.priceFrom,
    this.isFeatured = false,
    this.isTrending = false,
    required this.category,
    required this.description,
    required this.descriptionAr,
  });

  @override
  List<Object?> get props => [id];
}

// ──────────────────────────────────────────────
//  Category Entity
// ──────────────────────────────────────────────
enum DestinationCategory { hotel, travelAgency, guide, restaurant, activity }

class Category extends Equatable {
  final String id;
  final String name;
  final String nameAr;
  final String iconName;
  final DestinationCategory type;

  const Category({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.iconName,
    required this.type,
  });

  @override
  List<Object?> get props => [id];
}

// ──────────────────────────────────────────────
//  User Entity
// ──────────────────────────────────────────────
class AppUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int tripsCount;
  final List<String> savedDestinations;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.tripsCount = 0,
    this.savedDestinations = const [],
  });

  @override
  List<Object?> get props => [id];
}

// ──────────────────────────────────────────────
//  Trip Entity
// ──────────────────────────────────────────────
class Trip extends Equatable {
  final String id;
  final String destinationId;
  final String destinationName;
  final String destinationNameAr;
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final TripStatus status;
  final double totalCost;

  const Trip({
    required this.id,
    required this.destinationId,
    required this.destinationName,
    required this.destinationNameAr,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalCost,
  });

  int get durationDays => endDate.difference(startDate).inDays;

  @override
  List<Object?> get props => [id];
}

enum TripStatus { upcoming, ongoing, completed, cancelled }
