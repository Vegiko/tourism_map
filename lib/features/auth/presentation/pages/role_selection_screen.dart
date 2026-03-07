import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/app_user.dart';

class RoleSelectionScreen extends StatefulWidget {
  final void Function(UserRole role) onRoleSelected;

  const RoleSelectionScreen({super.key, required this.onRoleSelected});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  UserRole? _selectedRole;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardScales;
  late List<Animation<double>> _cardOpacities;
  late AnimationController _bgController;
  late Animation<double> _bgAnimation;
  late AnimationController _buttonController;
  late Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bgAnimation = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeOut,
    );

    _cardControllers = List.generate(
      2,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _cardScales = _cardControllers.map((ctrl) {
      return Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.elasticOut),
      );
    }).toList();

    _cardOpacities = _cardControllers.map((ctrl) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: ctrl,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ),
      );
    }).toList();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _buttonController, curve: Curves.easeOut));

    // Staggered entrance
    _bgController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _cardControllers[0].forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _cardControllers[1].forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _buttonController.dispose();
    for (final ctrl in _cardControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _selectRole(UserRole role) {
    setState(() => _selectedRole = role);
    if (_selectedRole != null) {
      _buttonController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // Animated background
            _buildBackground(),
            // Content
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Header
                  FadeTransition(
                    opacity: _bgAnimation,
                    child: _buildHeader(),
                  ),
                  const SizedBox(height: 48),
                  // Role Cards
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Traveler Card
                          ScaleTransition(
                            scale: _cardScales[0],
                            child: FadeTransition(
                              opacity: _cardOpacities[0],
                              child: _RoleCard(
                                role: UserRole.traveler,
                                isSelected: _selectedRole == UserRole.traveler,
                                onTap: () => _selectRole(UserRole.traveler),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Partner Card
                          ScaleTransition(
                            scale: _cardScales[1],
                            child: FadeTransition(
                              opacity: _cardOpacities[1],
                              child: _RoleCard(
                                role: UserRole.partner,
                                isSelected: _selectedRole == UserRole.partner,
                                onTap: () => _selectRole(UserRole.partner),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Continue Button
                  SlideTransition(
                    position: _buttonSlide,
                    child: _buildContinueButton(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE8F4F9), Color(0xFFF7F9FC)],
            ),
          ),
        ),
        // Top decorative blob
        Positioned(
          top: -80,
          right: -60,
          child: AnimatedBuilder(
            animation: _bgAnimation,
            builder: (_, child) => Transform.scale(
              scale: _bgAnimation.value,
              child: child,
            ),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryLight.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          left: -30,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(0.06),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Logo
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.flight_takeoff_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'أهلاً بك في سياحة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'اختر نوع حسابك للبدء',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    final isEnabled = _selectedRole != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedOpacity(
        opacity: isEnabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: isEnabled
              ? () => widget.onRoleSelected(_selectedRole!)
              : null,
          child: Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? AppColors.primaryGradient
                  : const LinearGradient(
                      colors: [Color(0xFFBBBBBB), Color(0xFFAAAAAA)],
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'متابعة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Role Card Widget
// ──────────────────────────────────────────────────────────────
class _RoleCard extends StatefulWidget {
  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _RoleCardData get _data {
    if (widget.role == UserRole.traveler) {
      return _RoleCardData(
        icon: Icons.explore_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF1A7FA8), Color(0xFF0B4F6C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        badgeColor: const Color(0xFF1A7FA8),
        title: 'مسافر',
        subtitle: 'للأفراد والعائلات',
        description:
            'ابحث واحجز الفنادق والرحلات\nبسهولة وأمان من أي مكان',
        features: [
          'البحث عن الوجهات',
          'حجز الفنادق والرحلات',
          'تتبع رحلاتك',
          'تقييم الخدمات',
        ],
        emoji: '✈️',
      );
    } else {
      return _RoleCardData(
        icon: Icons.business_center_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B47), Color(0xFFF0A500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        badgeColor: const Color(0xFFFF6B47),
        title: 'شريك أعمال',
        subtitle: 'فنادق، وكالات، مرشدون',
        description:
            'أدر أعمالك واستقطب المزيد\nمن العملاء عبر منصتنا',
        features: [
          'لوحة تحكم متكاملة',
          'إدارة الحجوزات',
          'تحليلات الأداء',
          'التواصل مع العملاء',
        ],
        emoji: '🏨',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isSelected
                  ? d.badgeColor
                  : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? d.badgeColor.withOpacity(0.2)
                    : Colors.black.withOpacity(0.07),
                blurRadius: widget.isSelected ? 24 : 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background accent
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(gradient: d.gradient),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Row(
                  children: [
                    // Icon Circle
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: d.gradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: d.badgeColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          d.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                d.title,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: d.badgeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  d.subtitle,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: d.badgeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d.description,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Feature chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: d.features.take(2).map((f) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: d.badgeColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 10,
                                      color: d.badgeColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      f,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 10,
                                        color: d.badgeColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    // Selection indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: widget.isSelected ? d.gradient : null,
                        border: Border.all(
                          color: widget.isSelected
                              ? Colors.transparent
                              : AppColors.textHint,
                          width: 2,
                        ),
                      ),
                      child: widget.isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            )
                          : null,
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
}

class _RoleCardData {
  final IconData icon;
  final LinearGradient gradient;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final String description;
  final List<String> features;
  final String emoji;

  _RoleCardData({
    required this.icon,
    required this.gradient,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
    required this.emoji,
  });
}
