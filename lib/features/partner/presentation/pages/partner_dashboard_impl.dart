import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/partner_service.dart';
import '../bloc/partner_bloc.dart';
import '../widgets/service_card.dart';
import 'add_service_screen.dart';

class PartnerDashboardScreen extends StatefulWidget {
  final AppUser user;
  const PartnerDashboardScreen({super.key, required this.user});

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen>
    with TickerProviderStateMixin {
  int _currentTab = 0;
  ServiceStatus? _filterStatus;

  late AnimationController _headerCtrl;
  late AnimationController _statsCtrl;
  late List<Animation<Offset>> _statSlides;
  late AnimationController _fabCtrl;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _statsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _statSlides = List.generate(4, (i) => Tween<Offset>(begin: Offset(0, 0.3 + i * 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _statsCtrl, curve: Interval(i * 0.12, 0.7 + i * 0.08, curve: Curves.easeOut))));
    _fabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fabScale = CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut);

    Future.delayed(const Duration(milliseconds: 150), () { if (mounted) _statsCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 500), () { if (mounted) _fabCtrl.forward(); });

    context.read<PartnerBloc>().add(LoadPartnerDashboardEvent(widget.user.uid));
  }

  @override
  void dispose() {
    _headerCtrl.dispose(); _statsCtrl.dispose(); _fabCtrl.dispose();
    super.dispose();
  }

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  String _t(String ar, String en) => _ar ? ar : en;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return _t('صباح الخير', 'Good Morning');
    if (h < 17) return _t('مساء الخير', 'Good Afternoon');
    return _t('مساء النور', 'Good Evening');
  }

  // ── Open Add Service ─────────────────────────────
  Future<void> _openAddService() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: BlocProvider.value(
            value: context.read<PartnerBloc>(),
            child: AddServiceScreen(partner: widget.user, isArabic: _ar),
          ),
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    if (result == true && mounted) {
      _showSnack(_t('تمت إضافة الخدمة بنجاح! 🎉', 'Service added successfully! 🎉'));
      setState(() => _currentTab = 1);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _ar ? TextDirection.rtl : TextDirection.ltr,
      child: BlocListener<PartnerBloc, PartnerState>(
        listener: (ctx, state) {
          if (state is PartnerDashboardLoaded) {
            if (state.errorMessage != null) {
              _showSnack(state.errorMessage!, isError: true);
              ctx.read<PartnerBloc>().add(const ClearPartnerErrorEvent());
            }
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF0F1923),
          body: Stack(
            children: [
              _buildBg(),
              SafeArea(
                child: Column(children: [
                  FadeTransition(opacity: _headerCtrl, child: _buildHeader()),
                  _buildTabBar(),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _currentTab == 0 ? _buildOverviewTab() : _buildServicesTab(),
                    ),
                  ),
                ]),
              ),
              Positioned(
                bottom: 24,
                right: _ar ? null : 20,
                left: _ar ? 20 : null,
                child: ScaleTransition(scale: _fabScale, child: _buildFAB()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  Widget _buildBg() => Positioned.fill(child: CustomPaint(painter: _BgPainter()));

  // ── Header ───────────────────────────────────────
  Widget _buildHeader() {
    final info = widget.user.partnerInfo;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Center(child: Text(
            widget.user.displayName.isNotEmpty ? widget.user.displayName[0].toUpperCase() : 'P',
            style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_greeting, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white.withOpacity(0.6))),
          Text(widget.user.displayName,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          if (info != null)
            Row(children: [
              _VerifiedBadge(isVerified: info.isVerified, isArabic: _ar),
              const SizedBox(width: 6),
              Flexible(child: Text(
                _ar ? info.partnerType.nameAr : info.partnerType.nameEn,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white.withOpacity(0.5)),
                overflow: TextOverflow.ellipsis)),
            ]),
        ])),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          color: const Color(0xFF1E2D3D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'signout', child: Row(children: [
              const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
              const SizedBox(width: 10),
              Text(_t('تسجيل الخروج', 'Sign Out'),
                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            ])),
          ],
          onSelected: (v) { if (v == 'signout') context.read<AuthBloc>().add(const SignOutRequested()); },
        ),
      ]),
    );
  }

  // ── Tab Bar ──────────────────────────────────────
  Widget _buildTabBar() {
    final tabs = [(Icons.dashboard_rounded, _t('نظرة عامة', 'Overview')),
                  (Icons.business_center_rounded, _t('خدماتي', 'My Services'))];
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      height: 46,
      decoration: BoxDecoration(color: const Color(0xFF1A2535), borderRadius: BorderRadius.circular(14)),
      child: Row(children: tabs.asMap().entries.map((e) {
        final i = e.key; final tab = e.value; final isActive = _currentTab == i;
        return Expanded(child: GestureDetector(
          onTap: () { setState(() => _currentTab = i); HapticFeedback.selectionClick(); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: isActive ? AppColors.primaryGradient : null,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))] : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(tab.$1, size: 16, color: isActive ? Colors.white : Colors.white38),
              const SizedBox(width: 5),
              Text(tab.$2, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.white38)),
            ]),
          ),
        ));
      }).toList()),
    );
  }

  // ════════════════════════════════════════════════
  //  OVERVIEW TAB
  // ════════════════════════════════════════════════
  Widget _buildOverviewTab() {
    return BlocBuilder<PartnerBloc, PartnerState>(
      builder: (ctx, state) {
        final stats    = state is PartnerDashboardLoaded ? state.stats    : const PartnerStats();
        final services = state is PartnerDashboardLoaded ? state.services : <PartnerService>[];
        final loading  = state is PartnerLoading;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          physics: const BouncingScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildStatsGrid(stats, loading),
            const SizedBox(height: 24),
            _buildRevenueChart(),
            const SizedBox(height: 24),
            if (services.isNotEmpty) ...[
              _SectionHeader(title: _t('آخر الخدمات', 'Recent Services'), action: _t('عرض الكل', 'See All'), onTap: () => setState(() => _currentTab = 1), isArabic: _ar),
              const SizedBox(height: 12),
              ...services.take(2).map((s) => _MiniRow(service: s, isArabic: _ar)),
            ] else if (!loading) ...[
              _buildWelcomeBanner(),
            ],
          ]),
        );
      },
    );
  }

  // ── Stats Grid ──────────────────────────────────
  Widget _buildStatsGrid(PartnerStats stats, bool loading) {
    final cards = [
      _SC(title: _t('إجمالي الحجوزات', 'Total Bookings'),
          value: loading ? '—' : '${stats.totalBookings}',
          sub: _t('${stats.pendingBookings} معلق', '${stats.pendingBookings} pending'),
          icon: Icons.book_online_rounded, gradient: AppColors.primaryGradient, trend: '+12%'),
      _SC(title: _t('إجمالي الأرباح', 'Total Revenue'),
          value: loading ? '—' : '\$${_fmt(stats.totalRevenue)}',
          sub: _t('الشهر: \$${_fmt(stats.monthlyRevenue)}', 'Month: \$${_fmt(stats.monthlyRevenue)}'),
          icon: Icons.account_balance_wallet_rounded,
          gradient: const LinearGradient(colors: [Color(0xFF27AE60), Color(0xFF1A7A45)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          trend: '+8.5%'),
      _SC(title: _t('خدماتي', 'My Services'),
          value: loading ? '—' : '${stats.totalServices}',
          sub: _t('${stats.activeServices} نشطة', '${stats.activeServices} active'),
          icon: Icons.business_center_rounded, gradient: AppColors.sunsetGradient),
      _SC(title: _t('متوسط التقييم', 'Avg Rating'),
          value: loading ? '—' : (stats.averageRating > 0 ? stats.averageRating.toStringAsFixed(1) : '—'),
          sub: _t('${stats.totalReviews} تقييم', '${stats.totalReviews} reviews'),
          icon: Icons.star_rounded,
          gradient: LinearGradient(colors: [AppColors.secondary, const Color(0xFFE67E22)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.28),
      itemCount: cards.length,
      itemBuilder: (_, i) => SlideTransition(position: _statSlides[i], child: FadeTransition(opacity: _statsCtrl, child: _StatWidget(data: cards[i]))),
    );
  }

  // ── Revenue Chart ────────────────────────────────
  Widget _buildRevenueChart() {
    final months = _ar ? ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو'] : ['Jan','Feb','Mar','Apr','May','Jun','Jul'];
    final values = [820.0, 1200.0, 980.0, 1500.0, 1800.0, 1400.0, 1750.0];
    final maxV = values.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF1A2535), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_t('الأرباح الشهرية', 'Monthly Revenue'), style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: const Text('+18.3%', style: TextStyle(fontFamily: 'Cairo', color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 100,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: values.asMap().entries.map((e) {
            final i = e.key; final val = e.value;
            final h = (val / maxV) * 88;
            final isLast = i == values.length - 1;
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (isLast) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text('\$${(val/1000).toStringAsFixed(1)}k', style: const TextStyle(fontFamily: 'Cairo', color: AppColors.success, fontSize: 8, fontWeight: FontWeight.w700))),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: Duration(milliseconds: 400 + i * 80), curve: Curves.easeOut, height: h,
                  decoration: BoxDecoration(
                    gradient: isLast
                        ? const LinearGradient(colors: [Color(0xFF27AE60), Color(0xFF52C77E)], begin: Alignment.bottomCenter, end: Alignment.topCenter)
                        : LinearGradient(colors: [AppColors.primaryLight.withOpacity(0.3), AppColors.primaryLight.withOpacity(0.6)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  )),
                const SizedBox(height: 6),
                Text(months[i], style: TextStyle(fontFamily: 'Cairo', fontSize: 9,
                    color: isLast ? Colors.white : Colors.white.withOpacity(0.4),
                    fontWeight: isLast ? FontWeight.w700 : FontWeight.w400)),
              ]),
            ));
          }).toList()),
        ),
      ]),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🚀', style: TextStyle(fontSize: 28)),
        const SizedBox(height: 10),
        Text(_t('ابدأ رحلتك كشريك!', 'Start your partner journey!'),
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18)),
        const SizedBox(height: 6),
        Text(_t('أضف خدمتك الأولى الآن وابدأ في استقبال الحجوزات.', 'Add your first service now and start receiving bookings.'),
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white.withOpacity(0.85), fontSize: 12, height: 1.6)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _openAddService,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(_t('إضافة خدمة', 'Add Service'), style: const TextStyle(fontFamily: 'Cairo', color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════
  //  SERVICES TAB
  // ════════════════════════════════════════════════
  Widget _buildServicesTab() {
    return BlocBuilder<PartnerBloc, PartnerState>(
      builder: (ctx, state) {
        final services = state is PartnerDashboardLoaded ? state.services : <PartnerService>[];
        final loading  = state is PartnerLoading;
        if (loading) return _loadingList();
        final filtered = _filterStatus == null ? services : services.where((s) => s.status == _filterStatus).toList();
        return Column(children: [
          if (services.isNotEmpty) _buildFilterChips(services),
          Expanded(
            child: filtered.isEmpty
                ? EmptyServicesWidget(isArabic: _ar, onAdd: _openAddService)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => PartnerServiceCard(
                      service: filtered[i], isArabic: _ar,
                      onDelete: () => ctx.read<PartnerBloc>().add(DeleteServiceEvent(filtered[i].id)),
                      onStatusChange: (st) => ctx.read<PartnerBloc>().add(UpdateServiceStatusEvent(filtered[i].id, st)),
                    )),
          ),
        ]);
      },
    );
  }

  Widget _buildFilterChips(List<PartnerService> services) {
    final chips = [
      (null, _t('الكل', 'All'), services.length),
      (ServiceStatus.active, _t('نشطة', 'Active'), services.where((s) => s.status == ServiceStatus.active).length),
      (ServiceStatus.pending, _t('معلقة', 'Pending'), services.where((s) => s.status == ServiceStatus.pending).length),
      (ServiceStatus.suspended, _t('موقوفة', 'Suspended'), services.where((s) => s.status == ServiceStatus.suspended).length),
    ];
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: chips.map((c) {
          final isA = _filterStatus == c.$1;
          return GestureDetector(
            onTap: () => setState(() => _filterStatus = c.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 8, top: 6, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: isA ? AppColors.primaryGradient : null,
                color: isA ? null : const Color(0xFF1A2535),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isA ? Colors.transparent : Colors.white.withOpacity(0.1)),
              ),
              child: Row(children: [
                Text(c.$2, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600, color: isA ? Colors.white : Colors.white54)),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: isA ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                  child: Text('${c.$3}', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: isA ? Colors.white : Colors.white38)),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _loadingList() => ListView.builder(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    itemCount: 3,
    itemBuilder: (_, __) => _Skeleton());

  // ── FAB ──────────────────────────────────────────
  Widget _buildFAB() {
    return GestureDetector(
      onTap: _openAddService,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: AppColors.sunsetGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(_t('إضافة خدمة جديدة', 'Add New Service'),
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ════════════════════════════════════════════════════════════
//  Supporting Widgets
// ════════════════════════════════════════════════════════════

class _SC { final String title, value, sub; final IconData icon; final Gradient gradient; final String? trend;
  const _SC({required this.title, required this.value, required this.sub, required this.icon, required this.gradient, this.trend});
}

class _StatWidget extends StatelessWidget {
  final _SC data;
  const _StatWidget({required this.data});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2535), borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(gradient: data.gradient, borderRadius: BorderRadius.circular(11),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))]),
            child: Icon(data.icon, color: Colors.white, size: 19)),
          if (data.trend != null)
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(data.trend!, style: const TextStyle(fontFamily: 'Cairo', fontSize: 9, color: AppColors.success, fontWeight: FontWeight.w700))),
        ]),
        const Spacer(),
        Text(data.value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, height: 1)),
        const SizedBox(height: 3),
        Text(data.title, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white.withOpacity(0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(data.sub, style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: Colors.white.withOpacity(0.35)), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  final bool isVerified, isArabic;
  const _VerifiedBadge({required this.isVerified, required this.isArabic});

  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: (isVerified ? AppColors.success : AppColors.warning).withOpacity(0.2),
      borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(isVerified ? Icons.verified_rounded : Icons.pending_rounded, size: 10,
          color: isVerified ? AppColors.success : AppColors.warning),
      const SizedBox(width: 3),
      Text(isArabic ? (isVerified ? 'موثق' : 'قيد المراجعة') : (isVerified ? 'Verified' : 'Pending'),
          style: TextStyle(fontFamily: 'Cairo', fontSize: 9, fontWeight: FontWeight.w700,
              color: isVerified ? AppColors.success : AppColors.warning)),
    ]));
}

class _SectionHeader extends StatelessWidget {
  final String title, action; final VoidCallback? onTap; final bool isArabic;
  const _SectionHeader({required this.title, required this.action, this.onTap, required this.isArabic});

  @override
  Widget build(BuildContext ctx) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
    GestureDetector(onTap: onTap, child: Text(action, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.primaryLight, fontWeight: FontWeight.w600))),
  ]);
}

class _MiniRow extends StatelessWidget {
  final PartnerService service; final bool isArabic;
  const _MiniRow({required this.service, required this.isArabic});

  @override
  Widget build(BuildContext ctx) {
    final name = isArabic && service.nameAr.isNotEmpty ? service.nameAr : service.name;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1A2535), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 48, height: 48,
          child: service.imageUrls.isNotEmpty
              ? Image.network(service.imageUrls.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _EmojiBox(service.serviceType.emoji))
              : _EmojiBox(service.serviceType.emoji))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(isArabic ? service.serviceType.nameAr : service.serviceType.nameEn,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white.withOpacity(0.4))),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\$${service.price.toInt()}', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: service.status.color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(isArabic ? service.status.nameAr : service.status.name,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 9, fontWeight: FontWeight.w700, color: service.status.color))),
        ]),
      ]),
    );
  }
}

class _EmojiBox extends StatelessWidget {
  final String emoji;
  const _EmojiBox(this.emoji);
  @override
  Widget build(BuildContext ctx) => Container(
    color: AppColors.primarySurface.withOpacity(0.08),
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))));
}

class _Skeleton extends StatefulWidget {
  @override
  State<_Skeleton> createState() => _SkeletonState();
}
class _SkeletonState extends State<_Skeleton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _a = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  Widget _b(double w, double h, {double r = 8}) => AnimatedBuilder(animation: _a, builder: (_, __) => Container(width: w, height: h, decoration: BoxDecoration(borderRadius: BorderRadius.circular(r),
    gradient: LinearGradient(begin: Alignment(_a.value - 1, 0), end: Alignment(_a.value + 1, 0),
        colors: const [Color(0xFF1E2D3D), Color(0xFF253545), Color(0xFF1E2D3D)]))));

  @override
  Widget build(BuildContext ctx) => Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFF1A2535), borderRadius: BorderRadius.circular(20)),
    child: Column(children: [_b(double.infinity, 130, r: 12), const SizedBox(height: 12),
      Row(children: [_b(120, 14, r: 4), const Spacer(), _b(60, 20, r: 10)]),
      const SizedBox(height: 8), _b(double.infinity, 11, r: 4)]));
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    p.color = const Color(0xFF0B4F6C).withOpacity(0.3);
    canvas.drawCircle(Offset(size.width * 1.1, -size.height * 0.05), size.width * 0.6, p);
    p.color = const Color(0xFF1A7FA8).withOpacity(0.08);
    canvas.drawCircle(Offset(-size.width * 0.1, size.height * 1.0), size.width * 0.5, p);
  }
  @override
  bool shouldRepaint(_) => false;
}
