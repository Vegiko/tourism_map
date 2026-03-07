import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/local_booking.dart';

class BookingDetailScreen extends StatefulWidget {
  final LocalBooking booking;
  final bool isArabic;

  const BookingDetailScreen({
    super.key,
    required this.booking,
    required this.isArabic,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late AnimationController _ticketCtrl;
  late AnimationController _qrCtrl;
  late Animation<double> _entranceFade;
  late Animation<Offset> _ticketSlide;
  late Animation<double> _qrScale;

  bool _qrVisible = false;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _ticketCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _qrCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    _entranceFade =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _ticketSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ticketCtrl, curve: Curves.easeOut));
    _qrScale =
        CurvedAnimation(parent: _qrCtrl, curve: Curves.elasticOut);

    _entranceCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200),
        () { if (mounted) _ticketCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 500),
        () { if (mounted) setState(() => _qrVisible = true); });
    Future.delayed(const Duration(milliseconds: 520),
        () { if (mounted) _qrCtrl.forward(); });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _ticketCtrl.dispose();
    _qrCtrl.dispose();
    super.dispose();
  }

  String _t(String ar, String en) => widget.isArabic ? ar : en;
  LocalBooking get b => widget.booking;

  String _formatDate(DateTime d) {
    final months = widget.isArabic
        ? ['يناير','فبراير','مارس','أبريل','مايو','يونيو',
           'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر']
        : ['Jan','Feb','Mar','Apr','May','Jun',
           'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Colored header bg
            Positioned(
              top: 0, left: 0, right: 0,
              height: MediaQuery.of(context).size.height * 0.38,
              child: _buildHeaderBg(),
            ),
            // Main scrollable content
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(context),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _entranceFade,
                      child: Column(children: [
                        const SizedBox(height: 8),
                        // Header card
                        _buildHeaderCard(),
                        const SizedBox(height: 20),
                        // Ticket + QR section
                        SlideTransition(
                          position: _ticketSlide,
                          child: _buildTicketCard(),
                        ),
                        const SizedBox(height: 20),
                        // Details
                        _buildDetailsSection(),
                        const SizedBox(height: 20),
                        // Timeline for travel package
                        if (b.serviceType == BookingServiceType.travelPackage)
                          _buildItineraryTimeline(),
                        const SizedBox(height: 20),
                        // Location card
                        if (b.address.isNotEmpty) _buildLocationCard(),
                        const SizedBox(height: 20),
                        // Price summary
                        _buildPriceSummary(),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header background gradient ──────────────────
  Widget _buildHeaderBg() {
    late Gradient gradient;
    switch (b.status) {
      case BookingStatus.upcoming:
        gradient = AppColors.primaryGradient;
        break;
      case BookingStatus.ongoing:
        gradient = AppColors.sunsetGradient;
        break;
      case BookingStatus.completed:
        gradient = const LinearGradient(
          colors: [Color(0xFF27AE60), Color(0xFF1A7A45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      default:
        gradient = const LinearGradient(
          colors: [Color(0xFF6B7A8D), Color(0xFF4A5568)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.only(
          bottomLeft:  Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
    );
  }

  // ── App Bar ─────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
          const Spacer(),
          // Offline badge
          if (!b.isSyncedToCloud) _OfflineBadge(isArabic: widget.isArabic),
          const SizedBox(width: 8),
          // Share button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_t('جارٍ مشاركة تفاصيل الحجز...', 'Sharing booking details...')),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 20),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Header Card ─────────────────────────────────
  Widget _buildHeaderCard() {
    final serviceName = widget.isArabic && b.serviceNameAr.isNotEmpty
        ? b.serviceNameAr
        : b.serviceName;
    final city = widget.isArabic && b.cityAr.isNotEmpty ? b.cityAr : b.city;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Status + type chips row
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _StatusChip(status: b.status, isArabic: widget.isArabic),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(b.serviceType.emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  widget.isArabic ? b.serviceType.nameAr : b.serviceType.nameEn,
                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            serviceName,
            style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              city.isNotEmpty ? city : b.address,
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 13),
            ),
          ]),
          const SizedBox(height: 20),
          // Check-in / Check-out row
          Row(children: [
            Expanded(child: _DateCell(
              label: _t('تاريخ الوصول', 'Check In'),
              date: _formatDate(b.checkIn),
              icon: Icons.flight_land_rounded,
              isArabic: widget.isArabic,
            )),
            Container(
              height: 60,
              width: 1,
              color: Colors.white.withOpacity(0.25),
            ),
            Expanded(child: _DateCell(
              label: _t('تاريخ المغادرة', 'Check Out'),
              date: _formatDate(b.checkOut),
              icon: Icons.flight_takeoff_rounded,
              isArabic: widget.isArabic,
            )),
            Container(
              height: 60,
              width: 1,
              color: Colors.white.withOpacity(0.25),
            ),
            Expanded(child: _DateCell(
              label: _t('الليالي', 'Nights'),
              date: '${b.nights}',
              icon: Icons.nights_stay_rounded,
              isArabic: widget.isArabic,
            )),
          ]),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  Ticket Card (with QR code)  –  the "boarding pass"
  // ════════════════════════════════════════════════
  Widget _buildTicketCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(children: [
          // Top section: booking ref + guest
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    _t('رقم التأكيد', 'Confirmation No.'),
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textHint),
                  ),
                  const SizedBox(height: 3),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: b.confirmationCode));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(_t('تم نسخ رمز الحجز', 'Confirmation code copied')),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.success,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ));
                    },
                    child: Row(children: [
                      Text(
                        b.confirmationCode,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.copy_rounded, size: 14, color: AppColors.textHint),
                    ]),
                  ),
                ])),
                // Partner logo circle
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      b.partnerName.isNotEmpty ? b.partnerName[0].toUpperCase() : 'P',
                      style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              // Guest info row
              Row(children: [
                _InfoPill(
                  icon: Icons.person_rounded,
                  text: b.guest.name.isNotEmpty ? b.guest.name : _t('ضيف', 'Guest'),
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _InfoPill(
                  icon: Icons.people_rounded,
                  text: _t('${b.guest.totalGuests} ضيوف', '${b.guest.totalGuests} guests'),
                  color: AppColors.accent,
                ),
              ]),
            ]),
          ),

          // ── Tear line ──────────────────────────
          _TearLine(),

          // ── QR Code section ────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Text(
                _t('امسح الكود للدخول', 'Scan to check in'),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              // QR code widget – works 100% OFFLINE
              if (_qrVisible)
                ScaleTransition(
                  scale: _qrScale,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: b.qrData,
                      version: QrVersions.auto,
                      size: 180,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.primaryDark,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.primaryDark,
                      ),
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                  ),
                )
              else
                Container(
                  width: 180, height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 12),
              // Offline indicator below QR
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.offline_bolt_rounded, color: AppColors.success, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    _t('يعمل بدون إنترنت ✓', 'Works offline ✓'),
                    style: const TextStyle(
                      fontFamily: 'Cairo', fontSize: 11,
                      color: AppColors.success, fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Details section ─────────────────────────────
  Widget _buildDetailsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('تفاصيل الحجز', 'Booking Details'),
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),
            _DetailRow(label: _t('مزود الخدمة', 'Service Provider'), value: b.partnerName, icon: Icons.business_rounded),
            _DetailRow(label: _t('نوع الخدمة', 'Service Type'), value: widget.isArabic ? b.serviceType.nameAr : b.serviceType.nameEn, icon: b.serviceType == BookingServiceType.hotel ? Icons.hotel_rounded : Icons.airplanemode_active_rounded),
            _DetailRow(label: _t('تاريخ الحجز', 'Booked On'), value: _formatDate(b.bookedAt), icon: Icons.receipt_long_rounded),
            _DetailRow(label: _t('عدد الضيوف', 'Guests'), value: '${b.guest.adults} ${_t("بالغ", "Adults")}${b.guest.children > 0 ? " + ${b.guest.children} ${_t("أطفال", "Children")}" : ""}', icon: Icons.people_rounded),

            // Extras
            if (b.extras.containsKey('stars'))
              _DetailRow(
                label: _t('تصنيف الفندق', 'Hotel Stars'),
                value: '${'⭐' * (b.extras['stars'] as int? ?? 0)}',
                icon: Icons.star_rounded,
              ),
            if (b.extras.containsKey('room_type'))
              _DetailRow(
                label: _t('نوع الغرفة', 'Room Type'),
                value: widget.isArabic && b.extras.containsKey('room_type_ar')
                    ? b.extras['room_type_ar'] as String
                    : b.extras['room_type'] as String,
                icon: Icons.bed_rounded,
              ),
            if (b.extras.containsKey('includes'))
              _DetailRow(
                label: _t('يشمل', 'Includes'),
                value: widget.isArabic && b.extras.containsKey('includes_ar')
                    ? b.extras['includes_ar'] as String
                    : b.extras['includes'] as String,
                icon: Icons.check_circle_outline_rounded,
              ),
            if (b.extras.containsKey('guide_name'))
              _DetailRow(
                label: _t('اسم المرشد', 'Guide Name'),
                value: b.extras['guide_name'] as String,
                icon: Icons.person_pin_rounded,
              ),
          ],
        ),
      ),
    );
  }

  // ── Itinerary Timeline (for packages) ───────────
  Widget _buildItineraryTimeline() {
    final days = b.nights;
    final destinations = [
      b.city.isNotEmpty ? b.city : 'Destination',
      b.city.isNotEmpty ? b.city : 'City',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.route_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(_t('مسار الرحلة', 'Trip Itinerary'), style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 16),
          // Day-by-day timeline (show up to 5 days)
          ...List.generate(min(days, 5), (i) {
            final date = b.checkIn.add(Duration(days: i));
            final isFirst = i == 0;
            final isLast = i == min(days, 5) - 1;
            return _TimelineItem(
              dayNumber: i + 1,
              date: _formatDate(date),
              title: isFirst
                  ? _t('الوصول والتسجيل', 'Arrival & Check-in')
                  : isLast
                      ? _t('المغادرة', 'Departure')
                      : _t('يوم الاستكشاف ${i + 1}', 'Exploration Day ${i + 1}'),
              description: isFirst
                  ? _t('استقبال في ${b.city}', 'Welcome to ${b.city}')
                  : isLast
                      ? _t('إنهاء الإجراءات والوداع', 'Final check-out')
                      : _t('جولة سياحية في المدينة', 'City sightseeing tour'),
              isFirst: isFirst,
              isLast: isLast,
            );
          }),
          if (days > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _t('+ ${days - 5} أيام أخرى', '+ ${days - 5} more days'),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textHint),
              ),
            ),
        ]),
      ),
    );
  }

  // ── Location card ────────────────────────────────
  Widget _buildLocationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              widget.isArabic && b.cityAr.isNotEmpty ? b.cityAr : b.city,
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Text(
              b.address,
              style: TextStyle(fontFamily: 'Cairo', color: Colors.white.withOpacity(0.8), fontSize: 12),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
          ])),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.directions_rounded, color: Colors.white, size: 18),
          ),
        ]),
      ),
    );
  }

  // ── Price summary ────────────────────────────────
  Widget _buildPriceSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t('ملخص الدفع', 'Payment Summary'), style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          _PriceRow(
            label: _t('سعر الخدمة', 'Service Price'),
            value: '${b.currency} ${(b.totalPrice - b.serviceFee).toStringAsFixed(2)}',
          ),
          _PriceRow(
            label: _t('رسوم الخدمة (5%)', 'Service Fee (5%)'),
            value: '${b.currency} ${b.serviceFee.toStringAsFixed(2)}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_t('الإجمالي', 'Total'), style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(
                '${b.currency} ${b.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Helper Widgets
// ════════════════════════════════════════════════════════════

class _DateCell extends StatelessWidget {
  final String label, date;
  final IconData icon;
  final bool isArabic;

  const _DateCell({required this.label, required this.date, required this.icon, required this.isArabic});

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: Colors.white70, size: 18),
    const SizedBox(height: 4),
    Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.white.withOpacity(0.7))),
    const SizedBox(height: 2),
    Text(date, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
  ]);
}

class _StatusChip extends StatelessWidget {
  final BookingStatus status;
  final bool isArabic;
  const _StatusChip({required this.status, required this.isArabic});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.4)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(status.emoji, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 4),
      Text(
        isArabic ? status.nameAr : status.nameEn,
        style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    ]),
  );
}

class _InfoPill extends StatelessWidget {
  final IconData icon; final String text; final Color color;
  const _InfoPill({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 5),
      Text(text, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ]),
  );
}

class _TearLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 20, height: 20, decoration: BoxDecoration(color: AppColors.background, borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)))),
      Expanded(child: LayoutBuilder(builder: (_, c) {
        final count = (c.maxWidth / 12).floor();
        return Row(children: List.generate(count, (i) => Expanded(
          child: Container(
            height: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: i.isEven ? AppColors.textHint.withOpacity(0.3) : Colors.transparent,
          ),
        )));
      })),
      Container(width: 20, height: 20, decoration: BoxDecoration(color: AppColors.background, borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)))),
    ]);
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value; final IconData icon;
  const _DetailRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textHint)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ])),
    ]),
  );
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary)),
      Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ]),
  );
}

class _TimelineItem extends StatelessWidget {
  final int dayNumber;
  final String date, title, description;
  final bool isFirst, isLast;

  const _TimelineItem({
    required this.dayNumber, required this.date,
    required this.title, required this.description,
    required this.isFirst, required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 40, child: Column(children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              gradient: isFirst || isLast ? AppColors.primaryGradient : null,
              color: isFirst || isLast ? null : AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$dayNumber', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700, color: isFirst || isLast ? Colors.white : AppColors.primary)),
            ),
          ),
          if (!isLast)
            Expanded(child: Container(width: 2, color: AppColors.primarySurface, margin: const EdgeInsets.symmetric(vertical: 2))),
        ])),
        const SizedBox(width: 10),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(date, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.textHint)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(description, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary)),
          ]),
        )),
      ]),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  final bool isArabic;
  const _OfflineBadge({required this.isArabic});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.warning.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.warning.withOpacity(0.5)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 12),
      const SizedBox(width: 4),
      Text(isArabic ? 'غير متزامن' : 'Not synced',
          style: const TextStyle(fontFamily: 'Cairo', color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w600)),
    ]),
  );
}
