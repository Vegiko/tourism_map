import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/explore_entities.dart';
import '../../data/datasources/explore_datasource.dart';

class FilterBottomSheet extends StatefulWidget {
  final ExploreFilter initialFilter;
  final bool isArabic;
  final void Function(ExploreFilter) onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.isArabic,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet>
    with SingleTickerProviderStateMixin {
  late ExploreFilter _filter;
  late RangeValues _priceRange;
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;

  static const double _minPrice = 0;
  static const double _maxPrice = 5000;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _priceRange = RangeValues(
      widget.initialFilter.minPrice ?? _minPrice,
      widget.initialFilter.maxPrice ?? _maxPrice,
    );
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String _t(String ar, String en) => widget.isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              _buildHandle(),
              // Header
              _buildHeader(context),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Type
                      _buildSection(
                        _t('نوع الخدمة', 'Service Type'),
                        _buildServiceTypeRow(),
                      ),
                      const SizedBox(height: 24),
                      // City
                      _buildSection(
                        _t('المدينة', 'City'),
                        _buildCityGrid(),
                      ),
                      const SizedBox(height: 24),
                      // Price Range
                      _buildSection(
                        _t('نطاق السعر', 'Price Range'),
                        _buildPriceRange(),
                      ),
                      const SizedBox(height: 24),
                      // Rating
                      _buildSection(
                        _t('الحد الأدنى للتقييم', 'Minimum Rating'),
                        _buildRatingPicker(),
                      ),
                      const SizedBox(height: 24),
                      // Sort
                      _buildSection(
                        _t('الترتيب حسب', 'Sort By'),
                        _buildSortOptions(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              // Action Buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.textHint.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('تصفية النتائج', 'Filter Results'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (_filter.activeCount > 0)
                Text(
                  _t('${_filter.activeCount} فلاتر مفعّلة',
                      '${_filter.activeCount} active filters'),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _filter = const ExploreFilter();
                _priceRange = const RangeValues(_minPrice, _maxPrice);
              });
            },
            child: Text(
              _t('مسح الكل', 'Clear All'),
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  // ── Service Type Row ────────────────────────────
  Widget _buildServiceTypeRow() {
    return Row(
      children: ServiceType.values.map((type) {
        final isSelected = _filter.serviceType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(
              () => _filter = _filter.copyWith(serviceType: type),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Text(
                widget.isArabic ? type.nameAr : type.nameEn,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── City Grid ───────────────────────────────────
  Widget _buildCityGrid() {
    final cities = widget.isArabic
        ? ExploreDataSource.citiesAr
        : ExploreDataSource.cities;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "All" chip
        _CityChip(
          label: _t('كل المدن', 'All Cities'),
          isSelected: _filter.city == null,
          onTap: () => setState(
            () => _filter = _filter.copyWith(city: () => null),
          ),
        ),
        ...cities.asMap().entries.map((entry) {
          final cityEn = ExploreDataSource.cities[entry.key];
          final cityLabel = entry.value;
          final isSelected = _filter.city == cityEn ||
              _filter.city == ExploreDataSource.citiesAr[entry.key];

          return _CityChip(
            label: cityLabel,
            isSelected: isSelected,
            onTap: () => setState(
              () => _filter = _filter.copyWith(city: () => cityEn),
            ),
          );
        }),
      ],
    );
  }

  // ── Price Range ─────────────────────────────────
  Widget _buildPriceRange() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _PriceTag('\$${_priceRange.start.toInt()}'),
            _PriceTag('\$${_priceRange.end.toInt()}'),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primarySurface,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.15),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: RangeSlider(
            values: _priceRange,
            min: _minPrice,
            max: _maxPrice,
            divisions: 50,
            onChanged: (values) {
              setState(() {
                _priceRange = values;
                _filter = _filter.copyWith(
                  minPrice: () => values.start > _minPrice ? values.start : null,
                  maxPrice: () => values.end < _maxPrice ? values.end : null,
                );
              });
            },
          ),
        ),
      ],
    );
  }

  // ── Rating Picker ───────────────────────────────
  Widget _buildRatingPicker() {
    return Row(
      children: [null, 3.0, 3.5, 4.0, 4.5].map((rating) {
        final isSelected = _filter.minRating == rating;
        final label = rating == null
            ? _t('الكل', 'All')
            : '${rating.toString()}+ ⭐';

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(
              () => _filter = _filter.copyWith(minRating: () => rating),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.sunsetGradient : null,
                color: isSelected ? null : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Sort Options ────────────────────────────────
  Widget _buildSortOptions() {
    return Column(
      children: SortOption.values.map((option) {
        final isSelected = _filter.sortBy == option;
        return GestureDetector(
          onTap: () => setState(
            () => _filter = _filter.copyWith(sortBy: option),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primarySurface
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textHint,
                      width: 2,
                    ),
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 12)
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  option.nameAr,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Action Buttons ──────────────────────────────
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _t('إلغاء', 'Cancel'),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Apply
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                widget.onApply(_filter);
                Navigator.pop(context);
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _t('تطبيق الفلاتر', 'Apply Filters'),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CityChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final String value;
  const _PriceTag(this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          fontSize: 13,
        ),
      ),
    );
  }
}
