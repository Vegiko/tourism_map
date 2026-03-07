import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../domain/entities/destination.dart';
import '../bloc/home_bloc.dart';
import '../widgets/home_widgets.dart';

class HomeScreen extends StatefulWidget {
  final bool isArabic;
  final VoidCallback? onToggleLanguage;

  const HomeScreen({
    super.key,
    required this.isArabic,
    this.onToggleLanguage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showElevation = false;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const LoadHomeDataEvent());
    _scrollController.addListener(() {
      final shouldElevate = _scrollController.offset > 10;
      if (shouldElevate != _showElevation) {
        setState(() => _showElevation = shouldElevate);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────
  //  Localized Strings
  // ────────────────────────────────────────────
  String get _greeting =>
      widget.isArabic ? 'مرحباً بعودتك 👋' : 'Welcome Back 👋';
  String get _subtitle =>
      widget.isArabic ? 'إلى أين تريد الذهاب؟' : 'Where do you want to go?';
  String get _searchHint =>
      widget.isArabic ? 'ابحث عن وجهتك...' : 'Search your destination...';
  String get _categoriesLabel =>
      widget.isArabic ? 'الفئات' : 'Categories';
  String get _featuredLabel =>
      widget.isArabic ? 'وجهات مميزة' : 'Featured Destinations';
  String get _popularLabel =>
      widget.isArabic ? 'الوجهات الشائعة' : 'Popular Destinations';
  String get _trendingLabel =>
      widget.isArabic ? 'الأكثر رواجاً' : 'Trending Now';
  String get _seeAll => widget.isArabic ? 'عرض الكل' : 'See All';
  String get _perNight => widget.isArabic ? '/ ليلة' : '/ night';
  String get _username => widget.isArabic ? 'سارة' : 'Sarah';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── App Bar ──────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  expandedHeight: 0,
                  backgroundColor: _showElevation
                      ? AppColors.surface
                      : AppColors.background,
                  elevation: _showElevation ? 1 : 0,
                  shadowColor: Colors.black12,
                  surfaceTintColor: Colors.transparent,
                  leading: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        _username[0],
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _greeting,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _username,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    // Language Toggle
                    GestureDetector(
                      onTap: widget.onToggleLanguage,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          widget.isArabic ? 'EN' : 'ع',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    // Notification Bell
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: AppColors.textPrimary,
                            size: 24,
                          ),
                          onPressed: () {},
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                  ],
                ),

                // ── Content ──────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        _subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(height: 1.3),
                      ),
                      const SizedBox(height: 20),

                      // Search Bar
                      SearchBarWidget(
                        hintText: _searchHint,
                        onChanged: (q) => context
                            .read<HomeBloc>()
                            .add(SearchDestinationsEvent(q)),
                        onFilterTap: () {},
                      ),
                      const SizedBox(height: 28),

                      // Categories
                      Text(
                        _categoriesLabel,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ]),
                  ),
                ),

                // ── Categories Horizontal List ─────────────
                SliverToBoxAdapter(
                  child: _buildCategoriesSection(state),
                ),

                // ── Featured Destinations ─────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 28, bottom: 16),
                      child: SectionHeader(
                        title: _featuredLabel,
                        actionLabel: _seeAll,
                        onAction: () {},
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildFeaturedSection(state),
                ),

                // ── Trending Section ──────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: SectionHeader(
                      title: _trendingLabel,
                      actionLabel: _seeAll,
                      onAction: () {},
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildTrendingSection(state),
                ),

                // ── Popular Destinations Grid ─────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: SectionHeader(
                      title: _popularLabel,
                      actionLabel: _seeAll,
                      onAction: () {},
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: _buildPopularGrid(state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Categories Builder
  // ──────────────────────────────────────────────
  Widget _buildCategoriesSection(HomeState state) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 92,
        child: state is HomeLoaded
            ? ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: state.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final category = state.categories[index];
                  return CategoryCircleItem(
                    category: category,
                    isSelected: state.selectedCategory == category.type,
                    isArabic: widget.isArabic,
                    onTap: () {
                      context.read<HomeBloc>().add(
                            FilterByCategoryEvent(
                              state.selectedCategory == category.type
                                  ? null
                                  : category.type,
                            ),
                          );
                    },
                  );
                },
              )
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (_, __) => Column(
                  children: [
                    ShimmerBox(width: 64, height: 64, radius: 32),
                    const SizedBox(height: 8),
                    ShimmerBox(width: 50, height: 10, radius: 4),
                  ],
                ),
              ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Featured Section Builder
  // ──────────────────────────────────────────────
  Widget _buildFeaturedSection(HomeState state) {
    return SizedBox(
      height: 330,
      child: state is HomeLoaded
          ? state.featuredDestinations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isArabic
                            ? 'لا توجد نتائج'
                            : 'No results found',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: state.featuredDestinations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final dest = state.featuredDestinations[index];
                    return FeaturedDestinationCard(
                      destination: dest,
                      isSaved: state.savedDestinationIds.contains(dest.id),
                      isArabic: widget.isArabic,
                      onSave: () => context.read<HomeBloc>().add(
                            ToggleSaveDestinationEvent(dest.id),
                          ),
                      onTap: () {},
                    );
                  },
                )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, __) => const FeaturedCardSkeleton(),
            ),
    );
  }

  // ──────────────────────────────────────────────
  //  Trending Section Builder
  // ──────────────────────────────────────────────
  Widget _buildTrendingSection(HomeState state) {
    return SizedBox(
      height: 90,
      child: state is HomeLoaded
          ? ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: state.trendingDestinations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final dest = state.trendingDestinations[index];
                final name =
                    widget.isArabic ? dest.nameAr : dest.name;
                return GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child: Image.network(
                              dest.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.primarySurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  dest.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) =>
                  ShimmerBox(width: 160, height: 72, radius: 16),
            ),
    );
  }

  // ──────────────────────────────────────────────
  //  Popular Grid Builder
  // ──────────────────────────────────────────────
  Widget _buildPopularGrid(HomeState state) {
    if (state is HomeLoading) {
      return SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const PopularCardSkeleton(),
          childCount: 4,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
      );
    }

    if (state is! HomeLoaded) return const SliverToBoxAdapter();

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final dest = state.popularDestinations[index];
          return PopularDestinationCard(
            destination: dest,
            isSaved: state.savedDestinationIds.contains(dest.id),
            isArabic: widget.isArabic,
            perNightLabel: _perNight,
            onSave: () => context.read<HomeBloc>().add(
                  ToggleSaveDestinationEvent(dest.id),
                ),
            onTap: () {},
          );
        },
        childCount: state.popularDestinations.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
    );
  }
}
