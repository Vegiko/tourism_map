import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../domain/entities/destination.dart';

// ──────────────────────────────────────────────
//  Animated Search Bar
// ──────────────────────────────────────────────
class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  const SearchBarWidget({
    super.key,
    required this.hintText,
    this.onChanged,
    this.onFilterTap,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _isFocused
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.black.withOpacity(0.06),
              blurRadius: _isFocused ? 16 : 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _isFocused
                ? AppColors.primary.withOpacity(0.4)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search_rounded,
              color: _isFocused ? AppColors.primary : AppColors.textHint,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: widget.onChanged,
                onTap: () {
                  setState(() => _isFocused = true);
                  _controller.forward();
                },
                onEditingComplete: () {
                  setState(() => _isFocused = false);
                  _controller.reverse();
                },
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: false,
                  hintStyle: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                textInputAction: TextInputAction.search,
              ),
            ),
            GestureDetector(
              onTap: widget.onFilterTap,
              child: Container(
                margin: const EdgeInsets.all(8),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Category Circle Item
// ──────────────────────────────────────────────
class CategoryCircleItem extends StatefulWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isArabic;

  const CategoryCircleItem({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
    required this.isArabic,
  });

  @override
  State<CategoryCircleItem> createState() => _CategoryCircleItemState();
}

class _CategoryCircleItemState extends State<CategoryCircleItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    switch (widget.category.iconName) {
      case 'hotel':
        return Icons.hotel_rounded;
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'guide':
        return Icons.record_voice_over_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'activity':
        return Icons.paragliding_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.isSelected
                    ? AppColors.primaryGradient
                    : null,
                color: widget.isSelected ? null : AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: widget.isSelected
                        ? AppColors.primary.withOpacity(0.35)
                        : Colors.black.withOpacity(0.07),
                    blurRadius: widget.isSelected ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _getIcon(),
                size: 26,
                color: widget.isSelected
                    ? Colors.white
                    : AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: widget.isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: widget.isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              child: Text(
                widget.isArabic
                    ? widget.category.nameAr
                    : widget.category.name,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Featured Destination Card (Large horizontal card)
// ──────────────────────────────────────────────
class FeaturedDestinationCard extends StatefulWidget {
  final Destination destination;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onTap;
  final bool isArabic;

  const FeaturedDestinationCard({
    super.key,
    required this.destination,
    required this.isSaved,
    required this.onSave,
    required this.onTap,
    required this.isArabic,
  });

  @override
  State<FeaturedDestinationCard> createState() =>
      _FeaturedDestinationCardState();
}

class _FeaturedDestinationCardState extends State<FeaturedDestinationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevationAnim;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _elevationAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.isArabic
        ? widget.destination.nameAr
        : widget.destination.name;
    final country = widget.isArabic
        ? widget.destination.countryAr
        : widget.destination.country;

    return GestureDetector(
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) {
        _hoverController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _hoverController.reverse(),
      child: ScaleTransition(
        scale: _elevationAnim,
        child: Container(
          width: 260,
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                Image.network(
                  widget.destination.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primarySurface,
                    child: const Icon(
                      Icons.image_not_supported_rounded,
                      color: AppColors.textHint,
                      size: 48,
                    ),
                  ),
                ),

                // Gradient Overlay
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.cardOverlay,
                  ),
                ),

                // Top Row: Badge + Save Button
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.destination.isTrending)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.sunsetGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Trending',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox(),
                      GestureDetector(
                        onTap: widget.onSave,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              widget.isSaved
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              key: ValueKey(widget.isSaved),
                              color: widget.isSaved
                                  ? AppColors.accent
                                  : Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Info
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.accent,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              country,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Rating
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: AppColors.secondary,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.destination.rating
                                      .toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${_formatCount(widget.destination.reviewCount)})',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            // Price
                            Text(
                              '\$${widget.destination.priceFrom.toInt()}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: AppColors.accent,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
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
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

// ──────────────────────────────────────────────
//  Popular Destination Card (Compact vertical card)
// ──────────────────────────────────────────────
class PopularDestinationCard extends StatelessWidget {
  final Destination destination;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onTap;
  final bool isArabic;
  final String perNightLabel;

  const PopularDestinationCard({
    super.key,
    required this.destination,
    required this.isSaved,
    required this.onSave,
    required this.onTap,
    required this.isArabic,
    required this.perNightLabel,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        isArabic ? destination.nameAr : destination.name;
    final country =
        isArabic ? destination.countryAr : destination.country;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: Image.network(
                      destination.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primarySurface,
                        child: const Icon(
                          Icons.image_not_supported_rounded,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: onSave,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSaved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          key: ValueKey(isSaved),
                          color: isSaved
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          country,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            destination.rating.toStringAsFixed(1),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        ],
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '\$${destination.priceFrom.toInt()}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: perNightLabel,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: AppColors.textHint,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Loading Skeleton for Featured Cards
// ──────────────────────────────────────────────
class FeaturedCardSkeleton extends StatelessWidget {
  const FeaturedCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ShimmerBox(width: 260, height: 320, radius: 24),
    );
  }
}

class MainNavigationShell extends StatelessWidget {
  final AppUser? initialAccountUser; // أضف هذا الحقل

  const MainNavigationShell({
    super.key,
    this.initialAccountUser, // أضفه هنا في الـ Constructor
  });

  @override
  Widget build(BuildContext context) {
    // الآن يمكنك استخدام initialAccountUser هنا إذا كنت تحتاجه
    return Scaffold(
    );
  }
}

class PopularCardSkeleton extends StatelessWidget {
  const PopularCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(
          width: double.infinity,
          height: 140,
          radius: 20,
        ),
        const SizedBox(height: 8),
        ShimmerBox(width: 120, height: 14, radius: 4),
        const SizedBox(height: 4),
        ShimmerBox(width: 80, height: 12, radius: 4),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShimmerBox(width: 50, height: 12, radius: 4),
            ShimmerBox(width: 60, height: 12, radius: 4),
          ],
        ),
      ],
    );
  }
}
