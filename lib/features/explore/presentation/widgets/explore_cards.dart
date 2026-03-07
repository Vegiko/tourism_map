import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/explore_entities.dart';

// ════════════════════════════════════════════════════════════
//  Travel Package Card  –  بطاقة باقة الوكالة
// ════════════════════════════════════════════════════════════
class TravelPackageCard extends StatefulWidget {
  final TravelPackage package;
  final bool isSaved;
  final bool isArabic;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const TravelPackageCard({
    super.key,
    required this.package,
    required this.isSaved,
    required this.isArabic,
    required this.onTap,
    required this.onSave,
  });

  @override
  State<TravelPackageCard> createState() => _TravelPackageCardState();
}

class _TravelPackageCardState extends State<TravelPackageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;
    final title = widget.isArabic ? pkg.titleAr : pkg.title;
    final agency = widget.isArabic ? pkg.agencyNameAr : pkg.agencyName;
    final city = widget.isArabic ? pkg.destinationCityAr : pkg.destinationCity;
    final country = widget.isArabic ? pkg.countryAr : pkg.country;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image Section ──────────────────
              _buildImageSection(pkg),
              // ── Content ───────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Agency Row
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              agency.isNotEmpty ? agency[0] : 'A',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            agency,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (pkg.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.verified_rounded,
                                  size: 10, color: AppColors.success),
                              const SizedBox(width: 3),
                              Text(
                                widget.isArabic ? 'موثق' : 'Verified',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 9,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ]),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Location + Duration Row
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 13, color: AppColors.accent),
                        const SizedBox(width: 3),
                        Text(
                          '$city • $country',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 10, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              widget.isArabic
                                  ? '${pkg.durationDays} أيام'
                                  : '${pkg.durationDays} Days',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Includes chips
                    SizedBox(
                      height: 26,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: (widget.isArabic
                                ? pkg.includesAr
                                : pkg.includes)
                            .take(3)
                            .map((item) => Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 12),

                    // Price + Rating Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Rating
                        Row(children: [
                          const Icon(Icons.star_rounded,
                              size: 16, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            pkg.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${_formatCount(pkg.reviewCount)})',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ]),
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (pkg.hasDiscount)
                              Text(
                                '\$${pkg.originalPrice.toInt()}',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                  text: '\$${pkg.price.toInt()}',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                TextSpan(
                                  text: widget.isArabic
                                      ? ' /شخص'
                                      : ' /person',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 10,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(TravelPackage pkg) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(22)),
          child: SizedBox(
            height: 190,
            width: double.infinity,
            child: Image.network(
              pkg.imageUrls.first,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primarySurface,
                child: const Icon(Icons.image_not_supported_rounded,
                    color: AppColors.textHint, size: 40),
              ),
            ),
          ),
        ),
        // Gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
              ),
            ),
          ),
        ),
        // Top tags
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Package type badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: pkg.packageType == PackageType.luxury ||
                          pkg.packageType == PackageType.premium
                      ? AppColors.sunsetGradient
                      : AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    pkg.packageType == PackageType.luxury
                        ? '👑'
                        : pkg.packageType == PackageType.premium
                            ? '⭐'
                            : '✈️',
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.isArabic
                        ? pkg.packageType.nameAr
                        : pkg.packageType.nameEn,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
              ),
              // Save button
              GestureDetector(
                onTap: widget.onSave,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.isSaved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(widget.isSaved),
                      color:
                          widget.isSaved ? AppColors.accent : AppColors.textHint,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Discount badge
        if (pkg.hasDiscount)
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '-${pkg.discountPercent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        // Photo count
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.photo_library_rounded,
                  color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Text(
                '${pkg.imageUrls.length}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) =>
      count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count';
}

// ════════════════════════════════════════════════════════════
//  Hotel Card  –  بطاقة فندق أفقية
// ════════════════════════════════════════════════════════════
class HotelCard extends StatefulWidget {
  final Hotel hotel;
  final bool isSaved;
  final bool isArabic;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const HotelCard({
    super.key,
    required this.hotel,
    required this.isSaved,
    required this.isArabic,
    required this.onTap,
    required this.onSave,
  });

  @override
  State<HotelCard> createState() => _HotelCardState();
}

class _HotelCardState extends State<HotelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    final name = widget.isArabic ? hotel.nameAr : hotel.name;
    final city = widget.isArabic ? hotel.cityAr : hotel.city;
    final country = widget.isArabic ? hotel.countryAr : hotel.country;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Image ─────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    child: SizedBox(
                      width: 130,
                      height: 140,
                      child: Image.network(
                        hotel.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.primarySurface,
                          child: const Icon(Icons.hotel_rounded,
                              color: AppColors.textHint, size: 36),
                        ),
                      ),
                    ),
                  ),
                  // Save
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: widget.onSave,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            widget.isSaved
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(widget.isSaved),
                            color: widget.isSaved
                                ? AppColors.accent
                                : AppColors.textHint,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Stars
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          hotel.stars.clamp(0, 5),
                          (_) => const Icon(Icons.star_rounded,
                              size: 9, color: AppColors.secondary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // ── Info ──────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Name
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Location
                      Row(children: [
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: AppColors.accent),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '$city, $country',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      // Amenities mini icons
                      Row(children: [
                        if (hotel.hasWifi)
                          _AmenityIcon(Icons.wifi_rounded),
                        if (hotel.hasPool)
                          _AmenityIcon(Icons.pool_rounded),
                        if (hotel.hasGym)
                          _AmenityIcon(Icons.fitness_center_rounded),
                        if (hotel.hasSpa)
                          _AmenityIcon(Icons.spa_rounded),
                        if (hotel.hasRestaurant)
                          _AmenityIcon(Icons.restaurant_rounded),
                      ]),
                      // Rating + Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            const Icon(Icons.star_rounded,
                                size: 13, color: AppColors.secondary),
                            const SizedBox(width: 3),
                            Text(
                              hotel.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ]),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: '\$${hotel.pricePerNight.toInt()}',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              TextSpan(
                                text: widget.isArabic ? '/ليلة' : '/night',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 9,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmenityIcon extends StatelessWidget {
  final IconData icon;
  const _AmenityIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 11, color: AppColors.primaryLight),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Shimmer Skeletons
// ════════════════════════════════════════════════════════════
class _ShimmerBox extends StatefulWidget {
  final double width, height, radius;
  const _ShimmerBox({required this.width, required this.height, this.radius = 8});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1400))..repeat();
    _anim = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: const [Color(0xFFEEEEEE), Color(0xFFF8F8F8), Color(0xFFEEEEEE)],
          ),
        ),
      ),
    );
  }
}

class PackageCardSkeleton extends StatelessWidget {
  const PackageCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _ShimmerBox(width: double.infinity, height: 190, radius: 22),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _ShimmerBox(width: 100, height: 12, radius: 4),
              const SizedBox(height: 8),
              _ShimmerBox(width: double.infinity, height: 16, radius: 4),
              const SizedBox(height: 6),
              _ShimmerBox(width: 180, height: 12, radius: 4),
              const SizedBox(height: 12),
              Row(children: [
                _ShimmerBox(width: 60, height: 10, radius: 4),
                const SizedBox(width: 8),
                _ShimmerBox(width: 60, height: 10, radius: 4),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class HotelCardSkeleton extends StatelessWidget {
  const HotelCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _ShimmerBox(width: 130, height: 140, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ShimmerBox(width: double.infinity, height: 14, radius: 4),
                const SizedBox(height: 8),
                _ShimmerBox(width: 100, height: 11, radius: 4),
                const SizedBox(height: 10),
                _ShimmerBox(width: 80, height: 11, radius: 4),
              ],
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}
