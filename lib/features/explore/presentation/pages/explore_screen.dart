import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/explore_entities.dart';
import '../bloc/explore_bloc.dart';
import '../widgets/explore_cards.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  final bool isArabic;
  const ExploreScreen({super.key, required this.isArabic});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  bool _showSearchBar = false;
  final ScrollController _scrollCtrl = ScrollController();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerCtrl.forward();

    _scrollCtrl.addListener(() {
      final s = _scrollCtrl.offset > 20;
      if (s != _scrolled) setState(() => _scrolled = s);
    });

    context.read<ExploreBloc>().add(const LoadExploreDataEvent());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _headerCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _t(String ar, String en) => widget.isArabic ? ar : en;

  void _openFilter(ExploreFilter current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        initialFilter: current,
        isArabic: widget.isArabic,
        onApply: (filter) =>
            context.read<ExploreBloc>().add(ApplyFilterEvent(filter)),
      ),
    );
  }

  void _openDetail(BuildContext ctx, {TravelPackage? pkg, Hotel? hotel}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: DetailScreen(
            isArabic: widget.isArabic,
            package: pkg,
            hotel: hotel,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: BlocProvider(
        create: (_) => ExploreBloc()..add(const LoadExploreDataEvent()),
        child: Builder(builder: (blocCtx) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: BlocBuilder<ExploreBloc, ExploreState>(
              builder: (context, state) {
                return CustomScrollView(
                  controller: _scrollCtrl,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Sticky Header ──────────────────────────
                    SliverAppBar(
                      pinned: true,
                      floating: false,
                      expandedHeight: 0,
                      backgroundColor: _scrolled
                          ? AppColors.surface
                          : AppColors.background,
                      elevation: _scrolled ? 1 : 0,
                      shadowColor: Colors.black12,
                      surfaceTintColor: Colors.transparent,
                      title: _scrolled
                          ? Text(
                              _t('استكشف', 'Explore'),
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontSize: 18,
                              ),
                            )
                          : null,
                      actions: [
                        IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _showSearchBar
                                  ? Icons.close_rounded
                                  : Icons.search_rounded,
                              key: ValueKey(_showSearchBar),
                              color: AppColors.textPrimary,
                            ),
                          ),
                          onPressed: () =>
                              setState(() => _showSearchBar = !_showSearchBar),
                        ),
                        if (state is ExploreLoaded)
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.tune_rounded,
                                    color: AppColors.textPrimary),
                                onPressed: () =>
                                    _openFilter(state.activeFilter),
                              ),
                              if (state.activeFilter.isActive)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.sunsetGradient,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${state.activeFilter.activeCount}',
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        const SizedBox(width: 4),
                      ],
                    ),

                    // ── Header Section ─────────────────────────
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _headerFade,
                        child: _buildPageHeader(state),
                      ),
                    ),

                    // ── Content ────────────────────────────────
                    if (state is ExploreLoading)
                      _buildLoadingSkeleton()
                    else if (state is ExploreLoaded)
                      ..._buildLoadedContent(context, state)
                    else if (state is ExploreError)
                      SliverToBoxAdapter(
                        child: _buildError(state.message),
                      ),
                  ],
                );
              },
            ),
          );
        }),
      ),
    );
  }

  // ── Page Header ──────────────────────────────────
  Widget _buildPageHeader(ExploreState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('🌍 استكشف العالم', '🌍 Explore the World'),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t('اعثر على باقتك المثالية وفندقك الأمثل',
                'Find your perfect package and ideal hotel'),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          // Search bar (animated)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: _showSearchBar ? _buildSearchBar(state) : const SizedBox.shrink(),
          ),
          // Active filter chips
          if (state is ExploreLoaded && state.activeFilter.isActive)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildActiveFilterChips(state),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ExploreState state) {
    return Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        onChanged: (q) =>
            context.read<ExploreBloc>().add(SearchExploreEvent(q)),
        decoration: InputDecoration(
          hintText: _t('ابحث عن باقة أو فندق...', 'Search packages or hotels...'),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.primary, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textHint, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    context
                        .read<ExploreBloc>()
                        .add(const SearchExploreEvent(''));
                  },
                )
              : null,
          border: InputBorder.none,
          fillColor: Colors.transparent,
          filled: true,
          hintStyle: const TextStyle(
            fontFamily: 'Cairo',
            color: AppColors.textHint,
            fontSize: 13,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips(ExploreLoaded state) {
    final chips = <Widget>[];
    final f = state.activeFilter;

    if (f.serviceType != ServiceType.all) {
      chips.add(_ActiveChip(
        label: widget.isArabic
            ? f.serviceType.nameAr
            : f.serviceType.nameEn,
        onRemove: () => context.read<ExploreBloc>().add(
              ApplyFilterEvent(
                  f.copyWith(serviceType: ServiceType.all)),
            ),
      ));
    }
    if (f.city != null) {
      chips.add(_ActiveChip(
        label: f.city!,
        onRemove: () => context.read<ExploreBloc>().add(
              ApplyFilterEvent(f.copyWith(city: () => null)),
            ),
      ));
    }
    if (f.minPrice != null || f.maxPrice != null) {
      chips.add(_ActiveChip(
        label:
            '\$${f.minPrice?.toInt() ?? 0} - \$${f.maxPrice?.toInt() ?? 5000}',
        onRemove: () => context.read<ExploreBloc>().add(
              ApplyFilterEvent(
                  f.copyWith(minPrice: () => null, maxPrice: () => null)),
            ),
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(children: [
        ...chips,
        TextButton.icon(
          onPressed: () =>
              context.read<ExploreBloc>().add(const ResetFilterEvent()),
          icon: const Icon(Icons.refresh_rounded, size: 14),
          label: Text(
            _t('مسح الكل', 'Clear All'),
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
          ),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
        ),
      ]),
    );
  }

  // ── Loaded Content ───────────────────────────────
  List<Widget> _buildLoadedContent(BuildContext ctx, ExploreLoaded state) {
    if (state.isEmpty) {
      return [
        SliverFillRemaining(
          child: _buildEmptyState(),
        ),
      ];
    }

    return [
      // ── Packages Section ──────────────────────
      if (state.visiblePackages.isNotEmpty) ...[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(
              title: _t('عروض الوكالات', 'Travel Packages'),
              subtitle: _t(
                  '${state.visiblePackages.length} باقة متاحة',
                  '${state.visiblePackages.length} available'),
              icon: '✈️',
              isArabic: widget.isArabic,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final pkg = state.visiblePackages[i];
                return TravelPackageCard(
                  package: pkg,
                  isSaved: state.savedIds.contains(pkg.id),
                  isArabic: widget.isArabic,
                  onSave: () => context
                      .read<ExploreBloc>()
                      .add(ToggleSaveItemEvent(pkg.id)),
                  onTap: () => _openDetail(ctx, pkg: pkg),
                );
              },
              childCount: state.visiblePackages.length,
            ),
          ),
        ),
      ],

      // ── Hotels Section ────────────────────────
      if (state.visibleHotels.isNotEmpty) ...[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(
              title: _t('الفنادق الموصى بها', 'Recommended Hotels'),
              subtitle: _t(
                  '${state.visibleHotels.length} فندق',
                  '${state.visibleHotels.length} hotels'),
              icon: '🏨',
              isArabic: widget.isArabic,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final hotel = state.visibleHotels[i];
                return HotelCard(
                  hotel: hotel,
                  isSaved: state.savedIds.contains(hotel.id),
                  isArabic: widget.isArabic,
                  onSave: () => context
                      .read<ExploreBloc>()
                      .add(ToggleSaveItemEvent(hotel.id)),
                  onTap: () => _openDetail(ctx, hotel: hotel),
                );
              },
              childCount: state.visibleHotels.length,
            ),
          ),
        ),
      ],
    ];
  }

  // ── Loading ──────────────────────────────────────
  Widget _buildLoadingSkeleton() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => i < 3
              ? const PackageCardSkeleton()
              : const HotelCardSkeleton(),
          childCount: 6,
        ),
      ),
    );
  }

  // ── Empty State ──────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            _t('لا توجد نتائج', 'No results found'),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t('جرّب تغيير الفلاتر أو البحث',
                'Try changing your filters or search'),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () =>
                context.read<ExploreBloc>().add(const ResetFilterEvent()),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _t('إعادة ضبط', 'Reset Filters'),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error ────────────────────────────────────────
  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Section Header
// ════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final bool isArabic;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Colored left border
        Container(
          width: 4,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ]),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // See all
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isArabic ? 'عرض الكل' : 'See All',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Active Filter Chip
// ════════════════════════════════════════════════════════════
class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded,
                color: Colors.white, size: 10),
          ),
        ),
      ]),
    );
  }
}
