import '../../domain/entities/explore_entities.dart';

class ExploreDataSource {
  // ══════════════════════════════════════════════
  //  Travel Packages Mock Data
  // ══════════════════════════════════════════════
  static final List<TravelPackage> packages = [
    TravelPackage(
      id: 'pkg_001',
      agencyName: 'Horizon Travel',
      agencyNameAr: 'وكالة أفق للسفر',
      agencyLogoUrl: 'https://ui-avatars.com/api/?name=Horizon&background=0B4F6C&color=fff',
      title: 'Maldives Dream Package',
      titleAr: 'باقة أحلام المالديف',
      destinationCity: 'Malé',
      destinationCityAr: 'ماليه',
      country: 'Maldives',
      countryAr: 'المالديف',
      imageUrls: [
        'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?w=800',
        'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?w=800',
        'https://images.unsplash.com/photo-1602002418082-a4443e081dd1?w=800',
        'https://images.unsplash.com/photo-1540202404-a2f29797e646?w=800',
      ],
      durationDays: 7,
      durationNights: 6,
      price: 2499,
      originalPrice: 3200,
      rating: 4.9,
      reviewCount: 847,
      isVerified: true,
      includes: ['Flights', 'Water Villa', 'All Meals', 'Snorkeling', 'Airport Transfer'],
      includesAr: ['تذاكر طيران', 'فيلا مائية', 'جميع الوجبات', 'الغطس', 'نقل المطار'],
      description:
          'Experience the ultimate island paradise in the Maldives. This all-inclusive package includes stay in an overwater villa, world-class dining, snorkeling adventures, and unforgettable sunsets.',
      descriptionAr:
          'استمتع بجنة الجزيرة المثالية في المالديف. تشمل هذه الباقة الشاملة الإقامة في فيلا مائية، تناول الطعام على مستوى عالمي، مغامرات الغطس وغروب شمس لا يُنسى.',
      latitude: 4.1755,
      longitude: 73.5093,
      packageType: PackageType.luxury,
      isPopular: true,
      availableFrom: DateTime(2026, 4, 1),
    ),
    TravelPackage(
      id: 'pkg_002',
      agencyName: 'Desert Rose Tours',
      agencyNameAr: 'جولات وردة الصحراء',
      agencyLogoUrl: 'https://ui-avatars.com/api/?name=Desert&background=FF6B47&color=fff',
      title: 'Dubai Luxury Experience',
      titleAr: 'تجربة دبي الفاخرة',
      destinationCity: 'Dubai',
      destinationCityAr: 'دبي',
      country: 'UAE',
      countryAr: 'الإمارات',
      imageUrls: [
        'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800',
        'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800',
        'https://images.unsplash.com/photo-1606046604972-77cc76aee944?w=800',
        'https://images.unsplash.com/photo-1561361513-2d000a50f0dc?w=800',
      ],
      durationDays: 5,
      durationNights: 4,
      price: 1299,
      originalPrice: 1299,
      rating: 4.7,
      reviewCount: 1243,
      isVerified: true,
      includes: ['5-Star Hotel', 'City Tour', 'Desert Safari', 'Dhow Cruise', 'Burj Khalifa'],
      includesAr: ['فندق 5 نجوم', 'جولة المدينة', 'سفاري الصحراء', 'رحلة دهو', 'برج خليفة'],
      description:
          'Discover the golden city of Dubai with this curated luxury package. Visit the world-famous Burj Khalifa, experience a thrilling desert safari, and enjoy a romantic evening cruise on the Dubai Creek.',
      descriptionAr:
          'اكتشف مدينة الذهب دبي مع هذه الباقة الفاخرة المنتقاة. قم بزيارة برج خليفة الشهير عالمياً، استمتع بسفاري الصحراء المثيرة وأمضِ أمسية رومانسية في رحلة بحرية على دبي كريك.',
      latitude: 25.2048,
      longitude: 55.2708,
      packageType: PackageType.premium,
      isPopular: true,
    ),
    TravelPackage(
      id: 'pkg_003',
      agencyName: 'Sakura Journeys',
      agencyNameAr: 'رحلات ساكورا',
      agencyLogoUrl: 'https://ui-avatars.com/api/?name=Sakura&background=E83E8C&color=fff',
      title: 'Japan Cherry Blossom',
      titleAr: 'أزهار الكرز في اليابان',
      destinationCity: 'Tokyo',
      destinationCityAr: 'طوكيو',
      country: 'Japan',
      countryAr: 'اليابان',
      imageUrls: [
        'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800',
        'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=800',
        'https://images.unsplash.com/photo-1580420376099-b7b0bc5db67e?w=800',
        'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=800',
      ],
      durationDays: 10,
      durationNights: 9,
      price: 3200,
      originalPrice: 4100,
      rating: 4.8,
      reviewCount: 562,
      isVerified: true,
      includes: ['Return Flights', '4-Star Hotel', 'Bullet Train', 'Guide', 'Cultural Tour'],
      includesAr: ['رحلة ذهاب وإياب', 'فندق 4 نجوم', 'قطار الرصاصة', 'مرشد', 'جولة ثقافية'],
      description:
          'Witness Japan\'s most breathtaking natural phenomenon — cherry blossom season. Explore Tokyo, Kyoto, and Hiroshima, ride the iconic Shinkansen bullet train, and immerse yourself in ancient temples and modern culture.',
      descriptionAr:
          'شاهد الظاهرة الطبيعية الأكثر روعة في اليابان - موسم أزهار الكرز. استكشف طوكيو وكيوتو وهيروشيما، اركب قطار الرصاصة الشهير وانغمس في المعابد القديمة والثقافة الحديثة.',
      latitude: 35.6762,
      longitude: 139.6503,
      packageType: PackageType.premium,
      isPopular: false,
      availableFrom: DateTime(2026, 3, 20),
    ),
    TravelPackage(
      id: 'pkg_004',
      agencyName: 'Blue Horizon',
      agencyNameAr: 'الأفق الأزرق',
      agencyLogoUrl: 'https://ui-avatars.com/api/?name=Blue&background=1A7FA8&color=fff',
      title: 'Santorini Romance',
      titleAr: 'رومانسية سانتوريني',
      destinationCity: 'Santorini',
      destinationCityAr: 'سانتوريني',
      country: 'Greece',
      countryAr: 'اليونان',
      imageUrls: [
        'https://images.unsplash.com/photo-1613395877344-13d4a8e0d49e?w=800',
        'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=800',
        'https://images.unsplash.com/photo-1601581875039-e899893d520c?w=800',
        'https://images.unsplash.com/photo-1554254464-7d0b3cc05de3?w=800',
      ],
      durationDays: 6,
      durationNights: 5,
      price: 1850,
      originalPrice: 2200,
      rating: 4.9,
      reviewCount: 1089,
      isVerified: true,
      includes: ['Cave Hotel', 'Wine Tasting', 'Sunset Cruise', 'Breakfast', 'ATV Tour'],
      includesAr: ['فندق الكهف', 'تذوق النبيذ', 'رحلة غروب الشمس', 'إفطار', 'جولة ATV'],
      description:
          'Fall in love with the iconic white-washed buildings, blue-domed churches, and stunning caldera views of Santorini. This romantic escape is perfect for couples seeking unforgettable Mediterranean magic.',
      descriptionAr:
          'اقع في حب المباني البيضاء الأيقونية والكنائس ذات القباب الزرقاء والمناظر المذهلة للكالديرا في سانتوريني. هذا المفر الرومانسي مثالي للأزواج.',
      latitude: 36.3932,
      longitude: 25.4615,
      packageType: PackageType.luxury,
      isPopular: true,
    ),
    TravelPackage(
      id: 'pkg_005',
      agencyName: 'Safari Quest',
      agencyNameAr: 'سفاري كويست',
      agencyLogoUrl: 'https://ui-avatars.com/api/?name=Safari&background=27AE60&color=fff',
      title: 'Kenya Safari Adventure',
      titleAr: 'مغامرة سفاري كينيا',
      destinationCity: 'Nairobi',
      destinationCityAr: 'نيروبي',
      country: 'Kenya',
      countryAr: 'كينيا',
      imageUrls: [
        'https://images.unsplash.com/photo-1516426122078-c23e76319801?w=800',
        'https://images.unsplash.com/photo-1547471080-7cc2caa01a7e?w=800',
        'https://images.unsplash.com/photo-1523805009345-7448845a9e53?w=800',
        'https://images.unsplash.com/photo-1549366021-9f761d040a94?w=800',
      ],
      durationDays: 8,
      durationNights: 7,
      price: 2100,
      originalPrice: 2100,
      rating: 4.8,
      reviewCount: 378,
      isVerified: false,
      includes: ['Safari Lodge', 'Game Drives', 'Maasai Village', 'All Meals', 'Guide'],
      includesAr: ['لودج سفاري', 'جولات مشاهدة الحيوانات', 'قرية ماساي', 'جميع الوجبات', 'مرشد'],
      description:
          'Witness the spectacular Great Migration and encounter the Big Five in their natural habitat. This immersive safari experience includes luxury lodge accommodation and expert guided game drives.',
      descriptionAr:
          'شاهد الهجرة الكبرى الرائعة والتقِ بالخمسة الكبار في موطنهم الطبيعي. تتضمن هذه التجربة الغامرة إقامة في لودج فاخر وجولات مرشدة خبيرة.',
      latitude: -1.2921,
      longitude: 36.8219,
      packageType: PackageType.premium,
      isPopular: false,
    ),
    TravelPackage(
      id: 'pkg_006',
      agencyName: 'Bali Bliss',
      agencyNameAr: 'نعيم بالي',
      agencyLogoUrl: 'https://ui-avatars.com/api/?name=Bali&background=F0A500&color=fff',
      title: 'Bali Wellness Retreat',
      titleAr: 'ريترات العافية في بالي',
      destinationCity: 'Ubud',
      destinationCityAr: 'أوبود',
      country: 'Indonesia',
      countryAr: 'إندونيسيا',
      imageUrls: [
        'https://images.unsplash.com/photo-1537953773345-d172ccf13cf4?w=800',
        'https://images.unsplash.com/photo-1555400038-63f5ba517a47?w=800',
        'https://images.unsplash.com/photo-1591017403286-fd8493524e1e?w=800',
        'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?w=800',
      ],
      durationDays: 9,
      durationNights: 8,
      price: 1650,
      originalPrice: 2000,
      rating: 4.7,
      reviewCount: 692,
      isVerified: true,
      includes: ['Villa Pool', 'Yoga Classes', 'Spa Treatments', 'Rice Terrace', 'Temple Visit'],
      includesAr: ['فيلا مع مسبح', 'دروس يوغا', 'علاجات سبا', 'تراسات الأرز', 'زيارة معبد'],
      description:
          'Reconnect with your inner self in the spiritual heart of Bali. This wellness retreat combines luxury villa accommodation, daily yoga, ancient temple visits, and traditional Balinese spa treatments.',
      descriptionAr:
          'تواصل مع ذاتك الداخلية في القلب الروحي لبالي. يجمع هذا الريترات إقامة فيلا فاخرة ويوغا يومية وزيارات معابد قديمة وعلاجات سبا بالينيزية تقليدية.',
      latitude: -8.5069,
      longitude: 115.2625,
      packageType: PackageType.standard,
      isPopular: true,
    ),
  ];

  // ══════════════════════════════════════════════
  //  Hotels Mock Data
  // ══════════════════════════════════════════════
  static final List<Hotel> hotels = [
    Hotel(
      id: 'htl_001',
      name: 'Burj Al Arab',
      nameAr: 'برج العرب',
      city: 'Dubai',
      cityAr: 'دبي',
      country: 'UAE',
      countryAr: 'الإمارات',
      imageUrls: [
        'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800',
        'https://images.unsplash.com/photo-1606046604972-77cc76aee944?w=800',
        'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800',
        'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?w=800',
      ],
      rating: 4.9,
      reviewCount: 5234,
      pricePerNight: 1200,
      stars: 7,
      amenities: ['Infinity Pool', 'Helipad', 'Private Beach', 'Butler Service', 'Spa'],
      amenitiesAr: ['مسبح لا نهائي', 'حوامة خاصة', 'شاطئ خاص', 'خدمة باتلر', 'سبا'],
      description:
          'The world\'s most luxurious hotel standing on its own artificial island, offering breathtaking views of the Arabian Gulf. Each suite is uniquely designed with opulent décor and world-class amenities.',
      descriptionAr:
          'الفندق الأكثر فخامة في العالم يقف على جزيرته الاصطناعية الخاصة، يقدم إطلالات خلابة على الخليج العربي. كل جناح مصمم بشكل فريد مع ديكور فخم ومرافق عالمية المستوى.',
      latitude: 25.1412,
      longitude: 55.1853,
      address: 'Jumeirah Beach Road, Dubai',
      addressAr: 'طريق شاطئ الجميرا، دبي',
      isFeatured: true,
      hasPool: true,
      hasWifi: true,
      hasGym: true,
      hasRestaurant: true,
      hasSpa: true,
    ),
    Hotel(
      id: 'htl_002',
      name: 'Four Seasons Bali',
      nameAr: 'فور سيزونز بالي',
      city: 'Ubud',
      cityAr: 'أوبود',
      country: 'Indonesia',
      countryAr: 'إندونيسيا',
      imageUrls: [
        'https://images.unsplash.com/photo-1555400038-63f5ba517a47?w=800',
        'https://images.unsplash.com/photo-1537953773345-d172ccf13cf4?w=800',
        'https://images.unsplash.com/photo-1591017403286-fd8493524e1e?w=800',
        'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?w=800',
      ],
      rating: 4.8,
      reviewCount: 2187,
      pricePerNight: 680,
      stars: 5,
      amenities: ['Jungle Pool', 'Yoga Pavilion', 'Rice Terrace', 'Spa', 'Fine Dining'],
      amenitiesAr: ['مسبح الغابة', 'جناح يوغا', 'تراسات الأرز', 'سبا', 'مطعم فاخر'],
      description:
          'Nestled among the verdant rice paddies and tropical forests of Ubud, this resort offers a sanctuary of serenity. Villas with private plunge pools overlook the sacred Ayung River gorge.',
      descriptionAr:
          'متناثر بين حقول الأرز الخضراء والغابات الاستوائية في أوبود، يوفر هذا المنتجع ملاذاً من الهدوء. الفيلات ذات المسابح الخاصة تطل على وادي نهر أيونج المقدس.',
      latitude: -8.5069,
      longitude: 115.2625,
      address: 'Sayan, Ubud, Bali 80571',
      addressAr: 'ساين، أوبود، بالي',
      isFeatured: true,
      hasPool: true,
      hasWifi: true,
      hasGym: true,
      hasRestaurant: true,
      hasSpa: true,
    ),
    Hotel(
      id: 'htl_003',
      name: 'Oia Castle Hotel',
      nameAr: 'فندق قلعة أويا',
      city: 'Santorini',
      cityAr: 'سانتوريني',
      country: 'Greece',
      countryAr: 'اليونان',
      imageUrls: [
        'https://images.unsplash.com/photo-1601581875039-e899893d520c?w=800',
        'https://images.unsplash.com/photo-1613395877344-13d4a8e0d49e?w=800',
        'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=800',
        'https://images.unsplash.com/photo-1554254464-7d0b3cc05de3?w=800',
      ],
      rating: 4.9,
      reviewCount: 1456,
      pricePerNight: 550,
      stars: 5,
      amenities: ['Caldera View', 'Cave Pool', 'Sunset Terrace', 'Wine Cellar', 'Spa'],
      amenitiesAr: ['إطلالة كالديرا', 'مسبح الكهف', 'تراس الغروب', 'قبو النبيذ', 'سبا'],
      description:
          'Perched dramatically on the rim of the Santorini caldera, this boutique hotel offers some of the most spectacular sunset views in the world. Each suite is carved into the volcanic rock.',
      descriptionAr:
          'متربع بشكل درامي على حافة كالديرا سانتوريني، يقدم هذا الفندق الفاخر بعضاً من أكثر مناظر غروب الشمس إثارة في العالم. كل جناح محفور في الصخر البركاني.',
      latitude: 36.4619,
      longitude: 25.3753,
      address: 'Oia, Santorini 847 02, Greece',
      addressAr: 'أويا، سانتوريني، اليونان',
      isFeatured: false,
      hasPool: true,
      hasWifi: true,
      hasGym: false,
      hasRestaurant: true,
      hasSpa: true,
    ),
    Hotel(
      id: 'htl_004',
      name: 'Overwater Paradise Resort',
      nameAr: 'منتجع الجنة المائية',
      city: 'Malé',
      cityAr: 'ماليه',
      country: 'Maldives',
      countryAr: 'المالديف',
      imageUrls: [
        'https://images.unsplash.com/photo-1602002418082-a4443e081dd1?w=800',
        'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?w=800',
        'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?w=800',
        'https://images.unsplash.com/photo-1540202404-a2f29797e646?w=800',
      ],
      rating: 4.9,
      reviewCount: 3012,
      pricePerNight: 890,
      stars: 5,
      amenities: ['Glass Floor Villa', 'House Reef', 'Seaplane Transfer', 'Spa', 'Dive Center'],
      amenitiesAr: ['فيلا بأرضية زجاجية', 'الحيد البحري', 'نقل بالطائرة المائية', 'سبا', 'مركز غوص'],
      description:
          'Wake up to the sound of the ocean in your own private overwater villa. Featuring a glass floor panel to observe the marine life beneath you and direct ladder access to the crystal lagoon.',
      descriptionAr:
          'استيقظ على صوت المحيط في فيلتك المائية الخاصة. تحتوي على لوح أرضية زجاجية لمشاهدة الحياة البحرية تحتك وسلم مباشر للدخول إلى البحيرة الكريستالية.',
      latitude: 4.1755,
      longitude: 73.5093,
      address: 'North Malé Atoll, Maldives',
      addressAr: 'شعاب مالي الشمالية، المالديف',
      isFeatured: true,
      hasPool: true,
      hasWifi: true,
      hasGym: true,
      hasRestaurant: true,
      hasSpa: true,
    ),
    Hotel(
      id: 'htl_005',
      name: 'Mandarin Oriental Paris',
      nameAr: 'ماندرين أورينتال باريس',
      city: 'Paris',
      cityAr: 'باريس',
      country: 'France',
      countryAr: 'فرنسا',
      imageUrls: [
        'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800',
        'https://images.unsplash.com/photo-1549144511-f099e773c147?w=800',
        'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800',
        'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=800',
      ],
      rating: 4.8,
      reviewCount: 2897,
      pricePerNight: 780,
      stars: 5,
      amenities: ['Eiffel View', 'Michelin Restaurant', 'Rooftop Pool', 'Spa', 'Concierge'],
      amenitiesAr: ['إطلالة برج إيفل', 'مطعم ميشلان', 'مسبح السطح', 'سبا', 'خدمة كونسيرج'],
      description:
          'Situated in the heart of Paris on Rue Saint-Honoré, this legendary hotel offers a perfect blend of French elegance and modern luxury. Wake up to views of the Eiffel Tower from your private terrace.',
      descriptionAr:
          'يقع في قلب باريس على شارع سانت أونوريه، يقدم هذا الفندق الأسطوري مزيجاً مثالياً من الأناقة الفرنسية والرفاهية الحديثة. استيقظ على مناظر برج إيفل من شرفتك الخاصة.',
      latitude: 48.8566,
      longitude: 2.3522,
      address: '251 Rue Saint-Honoré, 75001 Paris',
      addressAr: '251 شارع سانت أونوريه، باريس',
      isFeatured: false,
      hasPool: true,
      hasWifi: true,
      hasGym: true,
      hasRestaurant: true,
      hasSpa: true,
    ),
    Hotel(
      id: 'htl_006',
      name: 'Park Hyatt Tokyo',
      nameAr: 'بارك حياة طوكيو',
      city: 'Tokyo',
      cityAr: 'طوكيو',
      country: 'Japan',
      countryAr: 'اليابان',
      imageUrls: [
        'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800',
        'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=800',
        'https://images.unsplash.com/photo-1589307004125-b43e09c63b1a?w=800',
        'https://images.unsplash.com/photo-1580420376099-b7b0bc5db67e?w=800',
      ],
      rating: 4.8,
      reviewCount: 1673,
      pricePerNight: 620,
      stars: 5,
      amenities: ['Mt. Fuji View', 'Infinity Pool', 'Japanese Garden', 'Spa', 'Sake Bar'],
      amenitiesAr: ['إطلالة جبل فوجي', 'مسبح لا نهائي', 'حديقة يابانية', 'سبا', 'بار الساكي'],
      description:
          'Occupying the top 14 floors of the Shinjuku Park Tower, this iconic hotel offers spectacular panoramic views of Tokyo and, on clear days, majestic Mount Fuji. The indoor swimming pool features floor-to-ceiling windows.',
      descriptionAr:
          'يشغل الطوابق الـ14 الأخيرة من برج شينجوكو بارك، يوفر هذا الفندق الأيقوني إطلالات بانورامية مذهلة على طوكيو وجبل فوجي. يتميز المسبح الداخلي بنوافذ من الأرضية إلى السقف.',
      latitude: 35.6762,
      longitude: 139.6917,
      address: '3-7-1-2 Nishi-Shinjuku, Tokyo',
      addressAr: '3-7-1-2 نيشي شينجوكو، طوكيو',
      isFeatured: true,
      hasPool: true,
      hasWifi: true,
      hasGym: true,
      hasRestaurant: true,
      hasSpa: true,
    ),
  ];

  // ── Available cities for filter ──────────────────
  static const List<String> cities = [
    'Dubai', 'Maldives', 'Tokyo', 'Santorini', 'Bali', 'Paris', 'Nairobi', 'Kyoto'
  ];

  static const List<String> citiesAr = [
    'دبي', 'المالديف', 'طوكيو', 'سانتوريني', 'بالي', 'باريس', 'نيروبي', 'كيوتو'
  ];

  // ── Filter & sort methods ────────────────────────
  static List<TravelPackage> filterPackages(ExploreFilter filter) {
    var result = List<TravelPackage>.from(packages);

    if (filter.city != null) {
      result = result.where((p) =>
          p.destinationCity.toLowerCase().contains(filter.city!.toLowerCase()) ||
          p.destinationCityAr.contains(filter.city!)).toList();
    }
    if (filter.minPrice != null) {
      result = result.where((p) => p.price >= filter.minPrice!).toList();
    }
    if (filter.maxPrice != null) {
      result = result.where((p) => p.price <= filter.maxPrice!).toList();
    }
    if (filter.minRating != null) {
      result = result.where((p) => p.rating >= filter.minRating!).toList();
    }

    switch (filter.sortBy) {
      case SortOption.priceLowHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
      case SortOption.priceHighLow:
        result.sort((a, b) => b.price.compareTo(a.price));
      case SortOption.rating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
      case SortOption.newest:
        result.sort((a, b) => (b.availableFrom ?? DateTime.now())
            .compareTo(a.availableFrom ?? DateTime.now()));
      default:
        break;
    }

    return result;
  }

  static List<Hotel> filterHotels(ExploreFilter filter) {
    var result = List<Hotel>.from(hotels);

    if (filter.city != null) {
      result = result.where((h) =>
          h.city.toLowerCase().contains(filter.city!.toLowerCase()) ||
          h.cityAr.contains(filter.city!)).toList();
    }
    if (filter.minPrice != null) {
      result = result.where((h) => h.pricePerNight >= filter.minPrice!).toList();
    }
    if (filter.maxPrice != null) {
      result = result.where((h) => h.pricePerNight <= filter.maxPrice!).toList();
    }
    if (filter.minRating != null) {
      result = result.where((h) => h.rating >= filter.minRating!).toList();
    }

    switch (filter.sortBy) {
      case SortOption.priceLowHigh:
        result.sort((a, b) => a.pricePerNight.compareTo(b.pricePerNight));
      case SortOption.priceHighLow:
        result.sort((a, b) => b.pricePerNight.compareTo(a.pricePerNight));
      case SortOption.rating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
      default:
        break;
    }

    return result;
  }
}
