import '../../domain/entities/destination.dart';

// ──────────────────────────────────────────────
//  Destination Model
// ──────────────────────────────────────────────
class DestinationModel extends Destination {
  const DestinationModel({
    required super.id,
    required super.name,
    required super.nameAr,
    required super.country,
    required super.countryAr,
    required super.imageUrl,
    required super.rating,
    required super.reviewCount,
    required super.priceFrom,
    super.isFeatured,
    super.isTrending,
    required super.category,
    required super.description,
    required super.descriptionAr,
  });

  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    return DestinationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String,
      country: json['country'] as String,
      countryAr: json['country_ar'] as String,
      imageUrl: json['image_url'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['review_count'] as int,
      priceFrom: (json['price_from'] as num).toDouble(),
      isFeatured: json['is_featured'] as bool? ?? false,
      isTrending: json['is_trending'] as bool? ?? false,
      category: DestinationCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => DestinationCategory.hotel,
      ),
      description: json['description'] as String? ?? '',
      descriptionAr: json['description_ar'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'name_ar': nameAr,
        'country': country,
        'country_ar': countryAr,
        'image_url': imageUrl,
        'rating': rating,
        'review_count': reviewCount,
        'price_from': priceFrom,
        'is_featured': isFeatured,
        'is_trending': isTrending,
        'category': category.name,
        'description': description,
        'description_ar': descriptionAr,
      };
}

// ──────────────────────────────────────────────
//  Category Model
// ──────────────────────────────────────────────
class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.nameAr,
    required super.iconName,
    required super.type,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String,
      iconName: json['icon_name'] as String,
      type: DestinationCategory.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DestinationCategory.hotel,
      ),
    );
  }
}
