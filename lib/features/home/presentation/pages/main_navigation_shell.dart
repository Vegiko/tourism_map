import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
// استيراد AppUser ضروري للتعرف على النوع الممرر من الراوتر
import '../../../auth/domain/entities/app_user.dart';

class MainNavigationShell extends StatefulWidget {
  // إضافة المعلمات التي يطلبها app_router.dart لحل مشكلة فشل البناء
  final Widget child; 
  final AppUser? initialAccountUser;

  const MainNavigationShell({
    super.key,
    required this.child, // استقبال الصفحة من GoRouter
    this.initialAccountUser, // استقبال بيانات المستخدم
  });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // عرض الصفحة القادمة من الراوتر مباشرة
      body: widget.child, 
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, _items[0]),
              _buildNavItem(1, _items[1]),
              const SizedBox(width: 40),
              _buildNavItem(2, _items[2]),
              _buildNavItem(3, _items[3]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavItem item) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        // هنا يمكنك إضافة context.go(item.route) مستقبلاً لربط التنقل فعلياً
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? Colors.white : AppColors.textHint,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  final List<_NavItem> _items = const [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'الرئيسية',
    ),
    _NavItem(
      icon: Icons.search,
      activeIcon: Icons.search,
      label: 'استكشف',
    ),
    _NavItem(
      icon: Icons.bookmark_border,
      activeIcon: Icons.bookmark,
      label: 'حجوزاتي',
    ),
    _NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'حسابي',
    ),
  ];
}

// حافظنا على الكلاسات المساعدة كما هي في ملفك الأصلي
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

class MyTripsScreen extends StatelessWidget {
  final bool isArabic;
  const MyTripsScreen({super.key, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('My Trips')));
  }
}
