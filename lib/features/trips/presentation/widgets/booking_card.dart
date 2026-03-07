import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tourism_app/features/trips/domain/entities/local_booking.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/booking.dart';

// ════════════════════════════════════════════════════════════
//  BookingTimelineCard  –  card in the vertical timeline
// ════════════════════════════════════════════════════════════
class BookingTimelineCard extends StatefulWidget {
  final Booking booking;
  final bool isArabic;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const BookingTimelineCard({
    super.key,
    required this.booking,
    required this.isArabic,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  State<BookingTimelineCard> createState() => _BookingTimelineCardState();
}

class _BookingTimelineCardState extends State<BookingTimelineCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _t(String ar, String en) => widget.isArabic ? ar : en;

  String _formatTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color get _statusColor {
    switch (widget.booking.status) {
      case BookingStatus.confirmed:  return AppColors.success;
      case BookingStatus.checkedIn:  return AppColors.primaryLight;
      case BookingStatus.pending:    return AppColors.warning;
      case BookingStatus.cancelled:  return AppColors.error;
      case BookingStatus.completed:  return AppColors.textSecondary;
      case BookingStatus.upcoming:
        // TODO: Handle this case.
        throw UnimplementedError();
      case BookingStatus.ongoing:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  LinearGradient get _typeGradient {
    switch (widget.booking.serviceType) {
      case BookingServiceType.hotel:      return AppColors.primaryGradient;
      case BookingServiceType.flight:     return const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case BookingServiceType.tour:       return const LinearGradient(colors: [Color(0xFF11998E), Color(0xFF2ECC71)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case BookingServiceType.activity:   return AppColors.sunsetGradient;
      case BookingServiceType.restaurant: return const LinearGradient(colors: [Color(0xFFB24592), Color(0xFFF15F79)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case BookingServiceType.travelPackage:
        // TODO: Handle this case.
        throw UnimplementedError();
      case BookingServiceType.tourGuide:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final name = widget.isArabic && b.serviceNameAr.isNotEmpty
        ? b.serviceNameAr : b.serviceName;
    final city = widget.isArabic && b.location.cityAr.isNotEmpty
        ? b.location.cityAr : b.location.city;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Timeline line + dot ──────────────
            _TimelineDot(
              isFirst: widget.isFirst,
              isLast: widget.isLast,
              statusColor: _statusColor,
              gradient: _typeGradient,
              emoji: b.serviceType.emoji,
            ),
            const SizedBox(width: 14),

            // ── Card body ────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Image strip ──────────────
                    if (b.primaryImageUrl.isNotEmpty)
                      _ImageStrip(url: b.primaryImageUrl, nights: b.nights, isArabic: widget.isArabic),

                    // ── Content ──────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + status badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _MiniStatusBadge(status: b.status, color: _statusColor, isArabic: widget.isArabic),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Info row
                          Row(children: [
                            _IconLabel(icon: Icons.location_on_rounded, label: city, color: AppColors.accent),
                            const SizedBox(width: 12),
                            _IconLabel(icon: Icons.people_rounded, label: '${b.guests} ${_t('أشخاص', 'guests')}', color: AppColors.primary),
                          ]),
                          const SizedBox(height: 10),

                          // Date range chip
                          _DateRangeChip(checkIn: b.checkIn, checkOut: b.checkOut, isArabic: widget.isArabic),
                          const SizedBox(height: 10),

                          // Bottom row: price + QR hint
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(_t('الإجمالي', 'Total'),
                                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.textHint)),
                                Text('\$${b.totalPrice.toInt()}',
                                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 18,
                                        fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ]),
                              // QR + View ticket CTA
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: _typeGradient,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.qr_code_rounded, color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    _t('عرض التذكرة', 'View Ticket'),
                                    style: const TextStyle(fontFamily: 'Cairo', color: Colors.white,
                                        fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Timeline Dot + line
// ════════════════════════════════════════════════════════════
class _TimelineDot extends StatelessWidget {
  final bool isFirst, isLast;
  final Color statusColor;
  final LinearGradient gradient;
  final String emoji;

  const _TimelineDot({
    required this.isFirst,
    required this.isLast,
    required this.statusColor,
    required this.gradient,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Column(
        children: [
          // Top line
          if (!isFirst)
            Container(
              width: 2,
              height: 14,
              color: AppColors.textHint.withOpacity(0.25),
            ),
          // Dot
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 16)),
            ),
          ),
          // Bottom line
          if (!isLast)
            Container(
              width: 2,
              height: 80,
              color: AppColors.textHint.withOpacity(0.2),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Image Strip
// ════════════════════════════════════════════════════════════
class _ImageStrip extends StatelessWidget {
  final String url;
  final int nights;
  final bool isArabic;

  const _ImageStrip({required this.url, required this.nights, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: 130,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: const Center(child: Icon(Icons.image_rounded, color: Colors.white38, size: 32)),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Nights badge
            Positioned(
              bottom: 8,
              left: isArabic ? null : 10,
              right: isArabic ? 10 : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.nights_stay_rounded, color: Colors.white70, size: 11),
                  const SizedBox(width: 3),
                  Text(
                    '$nights ${isArabic ? 'ليالٍ' : 'nights'}',
                    style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 10),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Small helpers
// ════════════════════════════════════════════════════════════
class _MiniStatusBadge extends StatelessWidget {
  final BookingStatus status;
  final Color color;
  final bool isArabic;
  const _MiniStatusBadge({required this.status, required this.color, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(
          isArabic ? status.nameAr : status.nameEn,
          style: TextStyle(fontFamily: 'Cairo', fontSize: 9, fontWeight: FontWeight.w700, color: color),
        ),
      ]),
    );
  }
}

class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _IconLabel({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    ]);
  }
}

class _DateRangeChip extends StatelessWidget {
  final DateTime checkIn, checkOut;
  final bool isArabic;
  const _DateRangeChip({required this.checkIn, required this.checkOut, required this.isArabic});

  String _fmt(DateTime d) {
    final m = isArabic
        ? ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر']
        : ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.primary),
        const SizedBox(width: 5),
        Text(
          '${_fmt(checkIn)}  →  ${_fmt(checkOut)}',
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Empty State Widget
// ════════════════════════════════════════════════════════════
class EmptyTripsWidget extends StatelessWidget {
  final bool isArabic;
  final VoidCallback? onExplore;

  const EmptyTripsWidget({super.key, required this.isArabic, this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryLight.withOpacity(0.12), AppColors.primary.withOpacity(0.06)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🗺️', style: TextStyle(fontSize: 44))),
            ),
            const SizedBox(height: 20),
            Text(
              isArabic ? 'لا توجد رحلات مجدولة' : 'No Trips Scheduled',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'لم تقم بحجز أي رحلة بعد. ابدأ باستكشاف الوجهات المتاحة!'
                  : 'You haven\'t booked any trips yet. Start exploring amazing destinations!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onExplore,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.explore_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isArabic ? 'استكشف الرحلات' : 'Explore Trips',
                    style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Offline Banner
// ════════════════════════════════════════════════════════════
class OfflineBanner extends StatefulWidget {
  final bool isOffline;
  final bool isArabic;
  final VoidCallback? onSync;
  final bool isSyncing;

  const OfflineBanner({
    super.key,
    required this.isOffline,
    required this.isArabic,
    this.onSync,
    this.isSyncing = false,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    if (widget.isOffline) _ctrl.forward();
  }

  @override
  void didUpdateWidget(OfflineBanner old) {
    super.didUpdateWidget(old);
    if (widget.isOffline && !old.isOffline) _ctrl.forward();
    if (!widget.isOffline && old.isOffline) _ctrl.reverse();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _slide,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isOffline
              ? const Color(0xFF1A2535)
              : AppColors.success.withOpacity(0.1),
        ),
        child: Row(children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: widget.isOffline
                ? const Icon(Icons.wifi_off_rounded, color: Color(0xFFF39C12), size: 18, key: ValueKey('off'))
                : const Icon(Icons.wifi_rounded, color: AppColors.success, size: 18, key: ValueKey('on')),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.isOffline
                  ? (widget.isArabic ? 'وضع عدم الاتصال — تعرض بيانات مخزنة محلياً' : 'Offline mode — showing cached data')
                  : (widget.isArabic ? 'اتصال مستعاد — جارٍ المزامنة...' : 'Connected — syncing...'),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: widget.isOffline ? const Color(0xFFF39C12) : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (widget.isOffline && widget.onSync != null)
            GestureDetector(
              onTap: widget.isSyncing ? null : widget.onSync,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF39C12).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: widget.isSyncing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF39C12)))
                    : Text(
                        widget.isArabic ? 'مزامنة' : 'Sync',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Color(0xFFF39C12), fontWeight: FontWeight.w700),
                      ),
              ),
            ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Summary Header Cards
// ════════════════════════════════════════════════════════════
class TripSummaryRow extends StatelessWidget {
  final TripSummary summary;
  final bool isArabic;

  const TripSummaryRow({super.key, required this.summary, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final items = [
      (summary.upcomingBookings.toString(), isArabic ? 'قادمة' : 'Upcoming', Icons.flight_takeoff_rounded, AppColors.primary),
      (summary.activeBookings.toString(),   isArabic ? 'جارية' : 'Active',   Icons.hotel_rounded,         AppColors.success),
      (summary.completedBookings.toString(),isArabic ? 'مكتملة' : 'Done',    Icons.check_circle_rounded,  AppColors.textSecondary),
      ('\$${_fmt(summary.totalSpent)}',     isArabic ? 'أُنفق' : 'Spent',    Icons.payments_rounded,      AppColors.secondary),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: items.map((item) => Expanded(
          child: _SummaryCell(
            value: item.$1,
            label: item.$2,
            icon: item.$3,
            color: item.$4,
          ),
        )).toList(),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _SummaryCell extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;

  const _SummaryCell({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 9, color: AppColors.textHint)),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Day Header for timeline
// ════════════════════════════════════════════════════════════
class TripDayHeader extends StatelessWidget {
  final TripDay tripDay;
  final bool isArabic;

  const TripDayHeader({super.key, required this.tripDay, required this.isArabic});

  String _formatDay(DateTime d) {
    final months = isArabic
        ? ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر']
        : ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _dayName(DateTime d) {
    final days = isArabic
        ? ['الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت','الأحد']
        : ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return days[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isToday = tripDay.isToday;
    final isPast  = tripDay.isPast;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        // Date circle
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: isToday
                ? AppColors.sunsetGradient
                : isPast
                    ? const LinearGradient(colors: [Color(0xFFD0D0D0), Color(0xFFB0B0B0)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: isToday ? [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              '${tripDay.date.day}',
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, height: 1),
            ),
            Text(
              _monthAbbrev(tripDay.date.month),
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 9, height: 1.2),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(
              _dayName(tripDay.date),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isToday ? AppColors.accent : isPast ? AppColors.textHint : AppColors.textPrimary,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.accentSurface, borderRadius: BorderRadius.circular(20)),
                child: Text(isArabic ? 'اليوم' : 'Today',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 9, color: AppColors.accent, fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
          Text(
            _formatDay(tripDay.date),
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textHint),
          ),
        ])),
        // Booking count pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${tripDay.bookings.length} ${isArabic ? 'حجز' : 'booking${tripDay.bookings.length != 1 ? 's' : ''}'}',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    );
  }

  String _monthAbbrev(int m) {
    final months = isArabic
        ? ['ين','فب','مار','أبر','ماي','يون','يول','أغ','سب','أكت','نوف','ديس']
        : ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}
