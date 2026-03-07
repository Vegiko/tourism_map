import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/data/datasources/home_local_datasource.dart';
import '../../../home/data/repositories/home_repository_impl.dart';
import '../../../home/domain/usecases/home_usecases.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/pages/home_screen.dart';
import '../../../home/presentation/pages/other_screens.dart';
import '../../../map/presentation/pages/map_screen.dart';
import '../../../map/domain/entities/map_marker.dart';
import '../../../payment/presentation/pages/payment_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isArabic = true;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _toggleLanguage() {
    setState(() => _isArabic = !_isArabic);
  }

  // Navigation items labels
  List<_NavItem> get _navItems => [
        _NavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: _isArabic ? 'الرئيسية' : 'Home',
        ),
        _NavItem(
          icon: Icons.explore_outlined,
          activeIcon: Icons.explore_rounded,
          label: _isArabic ? 'استكشاف' : 'Explore',
        ),
        _NavItem(
          icon: Icons.map_outlined,
          activeIcon: Icons.map_rounded,
          label: _isArabic ? 'الخريطة' : 'Map',
        ),
        _NavItem(
          icon: Icons.luggage_outlined,
          activeIcon: Icons.luggage_rounded,
          label: _isArabic ? 'رحلاتي' : 'My Trips',
        ),
        _NavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: _isArabic ? 'الملف' : 'Profile',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    // Setup DI
    final dataSource = HomeLocalDataSourceImpl();
    final repository = HomeRepositoryImpl(localDataSource: dataSource);
    final getFeatured = GetFeaturedDestinations(repository);
    final getPopular = GetPopularDestinations(repository);
    final getTrending = GetTrendingDestinations(repository);
    final getCats = GetCategories(repository);
    final search = SearchDestinations(repository);

    return BlocProvider(
      create: (_) => HomeBloc(
        getFeaturedDestinations: getFeatured,
        getPopularDestinations: getPopular,
        getTrendingDestinations: getTrending,
        getCategories: getCats,
        searchDestinations: search,
      ),
      child: Directionality(
        textDirection:
            _isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildScreen(),
          ),
          bottomNavigationBar: _buildBottomNav(),
        ),
      ),
    );
  }

  Widget _buildScreen() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(
          key: const ValueKey('home'),
          isArabic: _isArabic,
          onToggleLanguage: _toggleLanguage,
        );
      case 1:
        return ExploreScreen(key: const ValueKey('explore'), isArabic: _isArabic);
      case 2:
        return MapExploreScreen(
          key: const ValueKey('map'),
          isArabic: _isArabic,
          onBookNow: (marker) => _openPaymentFromMap(marker),
        );
      case 3:
        return MyTripsScreen(key: const ValueKey('trips'), isArabic: _isArabic);
      case 4:
        return ProfileScreen(key: const ValueKey('profile'), isArabic: _isArabic);
      default:
        return HomeScreen(isArabic: _isArabic, onToggleLanguage: _toggleLanguage);
    }
  }

  void _openPaymentFromMap(MapMarkerData marker) {
    final now = DateTime.now();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          serviceId:   marker.id,
          serviceName: marker.name,
          serviceNameAr: marker.nameAr,
          serviceType: marker.type,
          amount:      marker.price,
          guests:      1,
          checkIn:     now.add(const Duration(days: 14)),
          checkOut:    now.add(Duration(days: 14 + (marker.durationDays > 0 ? marker.durationDays : 3))),
          isArabic:    _isArabic,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _navItems.length,
                (index) => _buildNavItem(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                key: ValueKey('${index}_$isSelected'),
                size: 22,
                color: isSelected ? Colors.white : AppColors.textHint,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: isSelected
                  ? Row(
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class MyTripsScreen extends StatelessWidget {
  final bool isArabic;
  const MyTripsScreen({Key? key, required this.isArabic}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('My Trips')));
  }
}


class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
