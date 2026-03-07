import '../models/destination_model.dart';
import '../../domain/entities/destination.dart';

abstract class HomeLocalDataSource {
  Future<List<DestinationModel>> getFeaturedDestinations();
  Future<List<DestinationModel>> getPopularDestinations();
  Future<List<DestinationModel>> getTrendingDestinations();
  Future<List<CategoryModel>> getCategories();
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  // ──────────────────────────────────────────────
  //  Mock Data
  // ──────────────────────────────────────────────
  static final List<DestinationModel> _mockDestinations = [
    const DestinationModel(
      id: '1',
      name: 'Maldives Paradise',
      nameAr: 'جنة المالديف',
      country: 'Maldives',
      countryAr: 'المالديف',
      imageUrl:
          'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?w=800',
      rating: 4.9,
      reviewCount: 2847,
      priceFrom: 1200,
      isFeatured: true,
      isTrending: true,
      category: DestinationCategory.hotel,
      description:
          'Experience paradise in the crystal clear waters of the Maldives.',
      descriptionAr: 'استمتع بالجنة في المياه الكريستالية الصافية للمالديف.',
    ),
    const DestinationModel(
      id: '2',
      name: 'Santorini Escape',
      nameAr: 'هروب سانتوريني',
      country: 'Greece',
      countryAr: 'اليونان',
      imageUrl:
          'https://images.unsplash.com/photo-1613395877344-13d4a8e0d49e?w=800',
      rating: 4.8,
      reviewCount: 3215,
      priceFrom: 890,
      isFeatured: true,
      isTrending: false,
      category: DestinationCategory.hotel,
      description: 'White-washed buildings and stunning sunsets await you.',
      descriptionAr:
          'تنتظرك المباني البيضاء وغروب الشمس الرائع في سانتوريني.',
    ),
    const DestinationModel(
      id: '3',
      name: 'Dubai Luxury',
      nameAr: 'دبي الفاخرة',
      country: 'UAE',
      countryAr: 'الإمارات',
      imageUrl:
          'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800',
      rating: 4.7,
      reviewCount: 5432,
      priceFrom: 650,
      isFeatured: false,
      isTrending: true,
      category: DestinationCategory.hotel,
      description: 'Experience luxury at its finest in the city of gold.',
      descriptionAr: 'استمتع بالرفاهية في أعلى مستوياتها في مدينة الذهب.',
    ),
    const DestinationModel(
      id: '4',
      name: 'Bali Serenity',
      nameAr: 'هدوء بالي',
      country: 'Indonesia',
      countryAr: 'إندونيسيا',
      imageUrl:
          'https://images.unsplash.com/photo-1537953773345-d172ccf13cf4?w=800',
      rating: 4.6,
      reviewCount: 1987,
      priceFrom: 420,
      isFeatured: false,
      isTrending: true,
      category: DestinationCategory.guide,
      description: 'Discover the spiritual heart of Southeast Asia.',
      descriptionAr: 'اكتشف الروح الروحانية لجنوب شرق آسيا.',
    ),
    const DestinationModel(
      id: '5',
      name: 'Paris Romance',
      nameAr: 'رومانسية باريس',
      country: 'France',
      countryAr: 'فرنسا',
      imageUrl:
          'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800',
      rating: 4.8,
      reviewCount: 8921,
      priceFrom: 780,
      isFeatured: true,
      isTrending: false,
      category: DestinationCategory.travelAgency,
      description: 'The city of love awaits with its timeless charm.',
      descriptionAr: 'مدينة الحب تنتظرك بسحرها الخالد.',
    ),
    const DestinationModel(
      id: '6',
      name: 'Tokyo Adventure',
      nameAr: 'مغامرة طوكيو',
      country: 'Japan',
      countryAr: 'اليابان',
      imageUrl:
          'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800',
      rating: 4.9,
      reviewCount: 4563,
      priceFrom: 950,
      isFeatured: true,
      isTrending: true,
      category: DestinationCategory.travelAgency,
      description: 'Where ancient tradition meets futuristic innovation.',
      descriptionAr: 'حيث يلتقي التراث العريق بالابتكار المستقبلي.',
    ),
  ];

  static final List<CategoryModel> _mockCategories = [
    const CategoryModel(
      id: 'c1',
      name: 'Hotels',
      nameAr: 'فنادق',
      iconName: 'hotel',
      type: DestinationCategory.hotel,
    ),
    const CategoryModel(
      id: 'c2',
      name: 'Travel Agencies',
      nameAr: 'وكالات سفر',
      iconName: 'travel',
      type: DestinationCategory.travelAgency,
    ),
    const CategoryModel(
      id: 'c3',
      name: 'Tour Guides',
      nameAr: 'مرشدون',
      iconName: 'guide',
      type: DestinationCategory.guide,
    ),
    const CategoryModel(
      id: 'c4',
      name: 'Restaurants',
      nameAr: 'مطاعم',
      iconName: 'restaurant',
      type: DestinationCategory.restaurant,
    ),
    const CategoryModel(
      id: 'c5',
      name: 'Activities',
      nameAr: 'أنشطة',
      iconName: 'activity',
      type: DestinationCategory.activity,
    ),
  ];

  @override
  Future<List<DestinationModel>> getFeaturedDestinations() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockDestinations.where((d) => d.isFeatured).toList();
  }

  @override
  Future<List<DestinationModel>> getPopularDestinations() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final sorted = List<DestinationModel>.from(_mockDestinations)
      ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    return sorted.take(4).toList();
  }

  @override
  Future<List<DestinationModel>> getTrendingDestinations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockDestinations.where((d) => d.isTrending).toList();
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockCategories;
  }
}
