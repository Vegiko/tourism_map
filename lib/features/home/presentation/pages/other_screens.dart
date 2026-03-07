import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../explore/presentation/bloc/explore_bloc.dart';
import '../../../explore/presentation/pages/explore_screen.dart' as explore;
import '../../../trips/presentation/pages/my_trips_screen.dart';
export '../../../trips/presentation/pages/my_trips_screen.dart' show MyTripsScreen;

// ──────────────────────────────────────────────
//  Explore Screen
// ──────────────────────────────────────────────
class ExploreScreen extends StatelessWidget {
  final bool isArabic;
  const ExploreScreen({super.key, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExploreBloc()..add(const LoadExploreDataEvent()),
      child: explore.ExploreScreen(isArabic: isArabic),
    );
  }
}

// ──────────────────────────────────────────────
//  My Trips Screen — now fully powered with Hive
// ──────────────────────────────────────────────
// Re-exported from trips feature

// ──────────────────────────────────────────────
//  Profile Screen
// ──────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  final bool isArabic;
  const ProfileScreen({super.key, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft:  Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      gradient: AppColors.sunsetGradient,
                    ),
                    child: const Center(child: Text('س', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(height: 12),
                  Text(isArabic ? 'سارة محمد' : 'Sarah Mohamed',
                      style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('sarah@tourism.com', style: TextStyle(fontFamily: 'Cairo', color: Colors.white.withOpacity(0.7), fontSize: 14)),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _StatItem(value: '12', label: isArabic ? 'رحلة' : 'Trips'),
                    _Divider(), _StatItem(value: '48', label: isArabic ? 'محفوظ' : 'Saved'),
                    _Divider(), _StatItem(value: '4.8', label: isArabic ? 'تقييم' : 'Rating'),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: AppSpacing.pagePadding,
                child: Column(children: [
                  _ProfileMenuItem(icon: Icons.bookmark_rounded, label: isArabic ? 'الوجهات المحفوظة' : 'Saved Destinations', onTap: () {}),
                  _ProfileMenuItem(icon: Icons.payment_rounded, label: isArabic ? 'طرق الدفع' : 'Payment Methods', onTap: () {}),
                  _ProfileMenuItem(icon: Icons.notifications_outlined, label: isArabic ? 'الإشعارات' : 'Notifications', onTap: () {}),
                  _ProfileMenuItem(
                    icon: Icons.language_rounded,
                    label: isArabic ? 'اللغة' : 'Language',
                    trailing: Text(isArabic ? 'العربية' : 'English',
                        style: const TextStyle(fontFamily: 'Cairo', color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                    onTap: () {},
                  ),
                  _ProfileMenuItem(icon: Icons.help_outline_rounded, label: isArabic ? 'المساعدة' : 'Help & Support', onTap: () {}),
                  _ProfileMenuItem(
                    icon: Icons.logout_rounded,
                    label: isArabic ? 'تسجيل الخروج' : 'Sign Out',
                    iconColor: AppColors.error,
                    textColor: AppColors.error,
                    onTap: () => context.read<AuthBloc>().add(const SignOutRequested()),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(children: [
      Text(value, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
      Text(label, style: TextStyle(fontFamily: 'Cairo', color: Colors.white.withOpacity(0.7), fontSize: 12)),
    ]),
  );
}
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(height: 30, width: 1, color: Colors.white.withOpacity(0.3));
}
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  final Widget? trailing; final Color iconColor; final Color textColor;
  const _ProfileMenuItem({required this.icon, required this.label, required this.onTap, this.trailing, this.iconColor = AppColors.primary, this.textColor = AppColors.textPrimary});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
    child: ListTile(
      onTap: onTap,
      leading: Container(width: 42, height: 42,
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 20)),
      title: Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
  );
}
