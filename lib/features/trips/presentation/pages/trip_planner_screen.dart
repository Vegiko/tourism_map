import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../bloc/trip_planner_bloc.dart';
import '../widgets/booking_card.dart';
import 'booking_ticket_screen.dart';
import '../../domain/entities/booking.dart';

// ════════════════════════════════════════════════════════════
//  Trip Planner Screen  —  Full offline-first timeline
// ════════════════════════════════════════════════════════════
class TripPlannerScreen extends StatefulWidget {
  final AppUser? user;
  final bool isArabic;

  const TripPlannerScreen({
    super.key,
    required this.user,
    required this.isArabic,
  });

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen>
    with TickerProviderStateMixin {
  // ── Controllers ───────────────────────────────
  final _scrollCtrl = ScrollController();
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late AnimationController _cardsCtrl;
  late List<Animation<Offset>> _cardSlides;
  bool _scrolled = false;

  // ── Filter ─────────────────────────────────────
  TripFilter _activeFilter = TripFilter.all;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);

    _cardsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _cardSlides = List.generate(
      6,
          (i) => Tween<Offset>(begin: Offset(0, 0.1 + i * 0.04), end: Offset.zero)
          .animate(CurvedAnimation(
          parent: _cardsCtrl,
          curve: Interval(i * 0.1, 0.6 + i * 0.07, curve: Curves.easeOut))),
    );

    _scrollCtrl.addListener(() {
      final s = _scrollCtrl.offset > 10;
      if (s != _scrolled) setState(() => _scrolled = s);
    });

    // Load trips
    if (widget.user != null) {
      context.read<TripPlannerBloc>().add(LoadTripPlannerEvent(widget.user!.uid));
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _headerCtrl.dispose();
    _cardsCtrl.dispose();
    super.dispose();
  }

  String _t(String ar, String en) => widget.isArabic ? ar : en;

  void _onFilterChanged(TripFilter f) {
    if (f == _activeFilter) return;
    setState(() => _activeFilter = f);
    context.read<TripPlannerBloc>().add(FilterTripsEvent(f));
    HapticFeedback.selectionClick();
  }

  Future<void> _onRefresh() async {
    if (widget.user == null) return;
    context.read<TripPlannerBloc>().add(RefreshTripPlannerEvent(widget.user!.uid));
    await Future.delayed(const Duration(milliseconds: 800));
  }

  void _openTicket(Booking booking, bool isOffline) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, anim, __) => FadeTransition(
        opacity: anim,
        child: BookingTicketScreen(
          booking: booking,
          isArabic: widget.isArabic,
          isOffline: isOffline,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }

  // ════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<TripPlannerBloc, TripPlannerState>(
          listener: (ctx, state) {
            if (state is TripPlannerLoaded) {
              if (state.tripDays.isNotEmpty) {
                _cardsCtrl.reset();
                _cardsCtrl.forward();
              }
            }
          },
          builder: (ctx, state) {
            return NestedScrollView(
              controller: _scrollCtrl,
              headerSliverBuilder: (_, __) => [
                _buildSliverAppBar(state),
                SliverToBoxAdapter(child: _buildOfflineBanner(state)),
                SliverToBoxAdapter(child: _buildSummaryRow(state)),
                SliverToBoxAdapter(child: _buildFilterBar()),
              ],
              body: _buildBody(state),
            );
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  Sliver App Bar
  // ════════════════════════════════════════════════
  Widget _buildSliverAppBar(TripPlannerState state) {
    final lastSync = state is TripPlannerLoaded ? state.lastSync : null;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 130,
      backgroundColor: _scrolled ? AppColors.surface : Colors.transparent,
      elevation: _scrolled ? 0.5 : 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        title: FadeTransition(
          opacity: _headerFade,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('مخطط الرحلات', 'Trip Planner'),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    if (lastSync != null)
                      Text(
                        _t('آخر مزامنة: ${_relativeTime(lastSync)}', 'Synced: ${_relativeTime(lastSync)}'),
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.textHint),
                      ),
                  ],
                ),
              ),
              // Sync button
              if (state is TripPlannerLoaded)
                GestureDetector(
                  onTap: state.isSyncing ? null : () =>
                      context.read<TripPlannerBloc>().add(SyncOfflineEvent(widget.user?.uid ?? '')),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: state.isSyncing
                        ? const Padding(
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                        : const Icon(Icons.sync_rounded, color: AppColors.primary, size: 18),
                  ),
                ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primarySurface,
                AppColors.background,
              ],
            ),
          ),
          child: Align(
            alignment: widget.isArabic ? Alignment.topRight : Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(children: [
                const Text('🗺️ ', style: TextStyle(fontSize: 28)),
                Text(
                  _t('جدولك الزمني للرحلات', 'Your Travel Timeline'),
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary.withOpacity(0.7)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Offline banner ──────────────────────────────
  Widget _buildOfflineBanner(TripPlannerState state) {
    final isOffline = state is TripPlannerLoaded && state.isOffline;
    final isSyncing = state is TripPlannerLoaded && state.isSyncing;

    return BlocBuilder<ConnectivityCubit, bool>(
      builder: (_, isOnline) => OfflineBanner(
        isOffline: !isOnline,
        isArabic: widget.isArabic,
        isSyncing: isSyncing,
        onSync: widget.user != null
            ? () => context.read<TripPlannerBloc>().add(SyncOfflineEvent(widget.user!.uid))
            : null,
      ),
    );
  }

  // ── Summary cards ───────────────────────────────
  Widget _buildSummaryRow(TripPlannerState state) {
    final summary = state is TripPlannerLoaded ? state.summary : const TripSummary();
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: TripSummaryRow(summary: summary, isArabic: widget.isArabic),
    );
  }

  // ── Filter chips ────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: TripFilter.values.map((f) {
          final isActive = _activeFilter == f;
          return GestureDetector(
            onTap: () => _onFilterChanged(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: isActive ? AppColors.primaryGradient : null,
                color: isActive ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isActive
                    ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                    : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
              ),
              child: Row(children: [
                if (isActive) ...[
                  const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(
                  widget.isArabic ? f.nameAr(true) : f.nameEn(),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  Body  —  state-dependent content
  // ════════════════════════════════════════════════
  Widget _buildBody(TripPlannerState state) {
    if (state is TripPlannerLoading) {
      return _buildSkeletonLoader();
    }

    if (state is TripPlannerError) {
      return _buildErrorState(state);
    }

    if (state is TripPlannerLoaded) {
      if (state.tripDays.isEmpty) {
        return EmptyTripsWidget(
          isArabic: widget.isArabic,
          onExplore: () {},
        );
      }
      return _buildTimeline(state);
    }

    return _buildSkeletonLoader();
  }

  // ════════════════════════════════════════════════
  //  Timeline  —  the main content
  // ════════════════════════════════════════════════
  Widget _buildTimeline(TripPlannerLoaded state) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Active booking highlight (if any)
          if (state.allBookings.any((b) => b.isActive))
            SliverToBoxAdapter(
              child: _buildActiveBookingBanner(
                state.allBookings.firstWhere((b) => b.isActive),
                state.isOffline,
              ),
            ),

          // Timeline grouped by day
          for (int di = 0; di < state.tripDays.length; di++) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: TripDayHeader(tripDay: state.tripDays[di], isArabic: widget.isArabic),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (ctx, bi) {
                    final booking = state.tripDays[di].bookings[bi];
                    final totalInDay = state.tripDays[di].bookings.length;
                    final animIdx = (di + bi).clamp(0, 5);
                    return SlideTransition(
                      position: _cardSlides[animIdx],
                      child: FadeTransition(
                        opacity: _cardsCtrl,
                        child: BookingTimelineCard(
                          booking: booking,
                          isArabic: widget.isArabic,
                          isFirst: bi == 0,
                          isLast: bi == totalInDay - 1,
                          onTap: () => _openTicket(booking, state.isOffline),
                        ),
                      ),
                    );
                  },
                  childCount: state.tripDays[di].bookings.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  Active Booking Banner (currently checked-in)
  // ════════════════════════════════════════════════
  Widget _buildActiveBookingBanner(Booking booking, bool isOffline) {
    final name = widget.isArabic && booking.serviceNameAr.isNotEmpty
        ? booking.serviceNameAr : booking.serviceName;
    final city = widget.isArabic && booking.location.cityAr.isNotEmpty
        ? booking.location.cityAr : booking.location.city;
    final daysLeft = booking.checkOut.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: () => _openTicket(booking, isOffline),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Background image
              if (booking.primaryImageUrl.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    booking.primaryImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
                  ),
                )
              else
                Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient))),

              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        AppColors.primaryDark.withOpacity(0.5),
                        AppColors.primaryDark.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // NOW badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const _PulseDot(),
                      const SizedBox(width: 6),
                      Text(
                        _t('جارٍ الآن', 'Active Now'),
                        style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(city, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white70)),
                  ]),
                  const SizedBox(height: 14),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    // Check-out info
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        _t('يتبقى $daysLeft يوم', '$daysLeft days remaining'),
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _t('حتى: ${_fmtDate(booking.checkOut)}', 'Until: ${_fmtDate(booking.checkOut)}'),
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white60),
                      ),
                    ]),
                    // View ticket
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.qr_code_rounded, color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _t('التذكرة', 'Ticket'),
                          style: const TextStyle(fontFamily: 'Cairo', color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ]),
                    ),
                  ]),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  Skeleton Loader
  // ════════════════════════════════════════════════
  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (_, i) => _SkeletonCard(),
    );
  }

  // ════════════════════════════════════════════════
  //  Error State
  // ════════════════════════════════════════════════
  Widget _buildErrorState(TripPlannerError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: state.isOfflineError
                  ? AppColors.warning.withOpacity(0.12)
                  : AppColors.error.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              state.isOfflineError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 36,
              color: state.isOfflineError ? AppColors.warning : AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            state.isOfflineError
                ? _t('أنت غير متصل بالإنترنت', 'You\'re offline')
                : _t('حدث خطأ', 'Something went wrong'),
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary, height: 1.6),
          ),
          if (!state.isOfflineError) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                if (widget.user != null) {
                  context.read<TripPlannerBloc>().add(LoadTripPlannerEvent(widget.user!.uid));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _t('إعادة المحاولة', 'Retry'),
                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final m = widget.isArabic
        ? ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر']
        : ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]}';
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return widget.isArabic ? 'منذ لحظات' : 'just now';
    if (diff.inMinutes < 60) return widget.isArabic ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    return widget.isArabic ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
  }
}

// ════════════════════════════════════════════════════════════
//  Pulse Dot  —  animated green dot for "active now"
// ════════════════════════════════════════════════════════════
class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _a = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(_a.value),
        boxShadow: [BoxShadow(color: Colors.white.withOpacity(_a.value * 0.6), blurRadius: 6)],
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  Skeleton Card
// ════════════════════════════════════════════════════════════
class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}
class _SkeletonCardState extends State<_SkeletonCard> with SingleTickerProviderStateMixin {
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

  Widget _b(double w, double h, {double r = 8}) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: w, height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: LinearGradient(
          begin: Alignment(_a.value - 1, 0), end: Alignment(_a.value + 1, 0),
          colors: const [Color(0xFFE8EDF2), Color(0xFFF5F7FA), Color(0xFFE8EDF2)],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)]),
      child: Column(children: [
        _b(double.infinity, 120, r: 20),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _b(160, 16, r: 4), _b(70, 22, r: 20),
            ]),
            const SizedBox(height: 10),
            _b(120, 12, r: 4),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _b(80, 28, r: 8), _b(110, 36, r: 20),
            ]),
          ]),
        ),
      ]),
    );
  }
}