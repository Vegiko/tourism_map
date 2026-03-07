import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tourism_app/features/trips/domain/entities/local_booking.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/booking.dart';

// ════════════════════════════════════════════════════════════
//  BookingTicketScreen  –  full offline ticket with QR
// ════════════════════════════════════════════════════════════
class BookingTicketScreen extends StatefulWidget {
  final Booking booking;
  final bool isArabic;
  final bool isOffline;

  const BookingTicketScreen({
    super.key,
    required this.booking,
    required this.isArabic,
    this.isOffline = false,
  });

  @override
  State<BookingTicketScreen> createState() => _BookingTicketScreenState();
}

class _BookingTicketScreenState extends State<BookingTicketScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _qrCtrl;
  late Animation<double> _qrScale;
  late AnimationController _ticketCtrl;
  late Animation<Offset> _ticketSlide;
  bool _qrExpanded = false;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);

    _qrCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _qrScale = CurvedAnimation(parent: _qrCtrl, curve: Curves.easeOut);

    _ticketCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _ticketSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ticketCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _ticketCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _qrCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _qrCtrl.dispose();
    _ticketCtrl.dispose();
    super.dispose();
  }

  String _t(String ar, String en) => widget.isArabic ? ar : en;

  String _formatDate(DateTime d) {
    final months = widget.isArabic
        ? ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Color get _statusColor {
    switch (widget.booking.status) {
      case BookingStatus.confirmed:  return AppColors.success;
      case BookingStatus.checkedIn:  return AppColors.primary;
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

  LinearGradient get _headerGradient {
    switch (widget.booking.serviceType) {
      case BookingServiceType.hotel:    return AppColors.primaryGradient;
      case BookingServiceType.flight:   return const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case BookingServiceType.tour:     return const LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38EF7D)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case BookingServiceType.activity: return AppColors.sunsetGradient;
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
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── SliverAppBar ──────────────────────
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (widget.isOffline)
                  _OfflineChip(isArabic: widget.isArabic),
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  onPressed: () => _shareTicket(),
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                title: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.confirmationCode,
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white70),
                      ),
                      Text(
                        widget.isArabic && b.serviceNameAr.isNotEmpty ? b.serviceNameAr : b.serviceName,
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Hero image
                    if (b.primaryImageUrl.isNotEmpty)
                      Image.network(b.primaryImageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(decoration: BoxDecoration(gradient: _headerGradient)))
                    else
                      Container(decoration: BoxDecoration(gradient: _headerGradient)),

                    // Gradient overlay
                    DecoratedBox(decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                        stops: const [0.3, 1.0],
                      ),
                    )),

                    // Status badge
                    Positioned(top: 56, right: 16,
                      child: _StatusBadge(status: b.status, isArabic: widget.isArabic)),

                    // Type badge
                    Positioned(top: 56, left: 16,
                      child: _TypeBadge(serviceType: b.serviceType, isArabic: widget.isArabic)),
                  ],
                ),
              ),
            ),

            // ── Content ───────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _ticketSlide,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      // ── The Ticket Card ──────────
                      _buildTicketCard(),
                      const SizedBox(height: 16),

                      // ── QR Code Section ──────────
                      _buildQRSection(),
                      const SizedBox(height: 16),

                      // ── Location Section ─────────
                      _buildLocationSection(),
                      const SizedBox(height: 16),

                      // ── Amenities/Includes ───────
                      if ((b.extras['amenities'] as List?)?.isNotEmpty == true ||
                          (b.extras['includes'] as List?)?.isNotEmpty == true)
                        _buildFeaturesSection(),

                      const SizedBox(height: 16),

                      // ── Notes ────────────────────
                      if (b.notes.isNotEmpty || b.notesAr.isNotEmpty)
                        _buildNotesSection(),

                      // ── Offline badge ─────────────
                      if (widget.isOffline || b.isOfflineCached) ...[
                        const SizedBox(height: 16),
                        _buildOfflineBadge(),
                      ],
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  Ticket Card  —  boarding-pass style
  // ════════════════════════════════════════════════
  Widget _buildTicketCard() {
    final b = widget.booking;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: [
        // ── Top section ─────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(children: [
            // Provider + service name
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: _headerGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(b.serviceType.emoji,
                    style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  widget.isArabic && b.serviceNameAr.isNotEmpty ? b.serviceNameAr : b.serviceName,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 2,
                ),
                Text(
                  widget.isArabic && b.providerNameAr.isNotEmpty ? b.providerNameAr : b.providerName,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary),
                ),
              ])),
            ]),
            const SizedBox(height: 20),

            // ── Date row ──────────────────────────
            Row(children: [
              Expanded(child: _DateColumn(
                label: _t('تاريخ الوصول', 'Check In'),
                date: b.checkIn,
                dateStr: _formatDate(b.checkIn),
                isArabic: widget.isArabic,
              )),
              Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${b.nights} ${_t('ليالٍ', 'nights')}',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textHint),
              ]),
              Expanded(child: _DateColumn(
                label: _t('تاريخ المغادرة', 'Check Out'),
                date: b.checkOut,
                dateStr: _formatDate(b.checkOut),
                isArabic: widget.isArabic,
                alignEnd: true,
              )),
            ]),
            const SizedBox(height: 16),

            // ── Info chips row ───────────────────
            Wrap(spacing: 8, runSpacing: 8, children: [
              _InfoChip(icon: Icons.people_rounded,
                  label: '${b.guests} ${_t('أشخاص', 'guests')}'),
              if (b.serviceType == BookingServiceType.hotel)
                _InfoChip(icon: Icons.bed_rounded,
                    label: '${b.rooms} ${_t('غرفة', 'room')}'),
              _InfoChip(icon: Icons.location_on_rounded,
                  label: widget.isArabic && b.location.cityAr.isNotEmpty
                      ? b.location.cityAr : b.location.city),
            ]),
          ]),
        ),

        // ── Dashed separator ────────────────────
        _DashedDivider(),

        // ── Bottom section  ─────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_t('رمز التأكيد', 'Confirmation Code'),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textHint)),
              const SizedBox(height: 3),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: b.confirmationCode));
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(_t('تم نسخ الرمز', 'Code copied'),
                        style: const TextStyle(fontFamily: 'Cairo')),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 2),
                  ));
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(b.confirmationCode,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 20,
                          fontWeight: FontWeight.w700, color: AppColors.primary,
                          letterSpacing: 1.5)),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                ]),
              ),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_t('المبلغ الإجمالي', 'Total Amount'),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textHint)),
              const SizedBox(height: 3),
              Text('\$${b.totalPrice.toInt()}',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 22,
                      fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('${b.currency} · ${b.guests} ${_t('أشخاص', 'pax')}',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.textHint)),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════
  //  QR Code Section
  // ════════════════════════════════════════════════
  Widget _buildQRSection() {
    return GestureDetector(
      onTap: () {
        setState(() => _qrExpanded = !_qrExpanded);
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
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
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_t('رمز QR للحجز', 'Booking QR Code'),
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(_t('اسحب للتوسيع · متاح بلا إنترنت', 'Tap to expand · Available offline'),
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary)),
              ])),
              AnimatedRotation(
                turns: _qrExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
              ),
            ]),
          ),

          // QR Code (expandable)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 350),
            crossFadeState: _qrExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: _buildQRMini(),
            secondChild: _buildQRFull(),
          ),
        ]),
      ),
    );
  }

  Widget _buildQRMini() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ScaleTransition(
        scale: _qrScale,
        child: Container(
          width: 100, height: 100,
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primarySurface, width: 2),
          ),
          child: QrImageView(
            data: widget.booking.qrData,
            version: QrVersions.auto,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primaryDark),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildQRFull() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            // Large QR
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
              ),
              child: QrImageView(
                data: widget.booking.qrData,
                version: QrVersions.auto,
                size: 200,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primaryDark),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.booking.confirmationCode,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 3),
            ),
            const SizedBox(height: 4),
            Text(
              _t('أريحة هذا الرمز لمزود الخدمة عند الوصول', 'Show this code to the service provider upon arrival'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // Barcode-style strips (decorative)
        _buildBarcodeStrips(),
      ]),
    );
  }

  // Decorative barcode strip under QR
  Widget _buildBarcodeStrips() {
    final rng = Random(widget.booking.id.hashCode);
    return SizedBox(
      height: 52,
      child: Row(
        children: List.generate(60, (i) {
          final h = 20.0 + rng.nextDouble() * 32;
          final w = 1.0 + rng.nextDouble() * 2;
          return Container(
            width: w, height: h,
            margin: EdgeInsets.only(right: rng.nextDouble() * 1.5),
            color: AppColors.primaryDark.withOpacity(0.5 + rng.nextDouble() * 0.5),
          );
        }),
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  Location Section
  // ════════════════════════════════════════════════
  Widget _buildLocationSection() {
    final loc = widget.booking.location;
    if (loc.address.isEmpty && loc.city.isEmpty) return const SizedBox.shrink();

    final address = widget.isArabic && loc.addressAr.isNotEmpty
        ? loc.addressAr : loc.address;
    final city = widget.isArabic && loc.cityAr.isNotEmpty
        ? loc.cityAr : loc.city;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 10),
          Text(_t('الموقع', 'Location'),
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 14),

        // Map placeholder
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4E8C2),
                  const Color(0xFFB5D5A8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Road lines
                CustomPaint(size: const Size(double.infinity, 130), painter: _MapSketchPainter()),
                // Pin
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                  ),
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  ),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Address line
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.place_rounded, size: 14, color: AppColors.textHint),
          const SizedBox(width: 6),
          Expanded(child: Text(
            '${address.isNotEmpty ? address : city}, ${loc.country}',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          )),
        ]),
        if (loc.latitude != 0) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.gps_fixed_rounded, size: 12, color: AppColors.textHint),
            const SizedBox(width: 6),
            Text(
              '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textHint),
            ),
          ]),
        ],
      ]),
    );
  }

  // ════════════════════════════════════════════════
  //  Features/Amenities
  // ════════════════════════════════════════════════
  Widget _buildFeaturesSection() {
    final amenities = (widget.booking.extras['amenities'] as List?)?.cast<String>() ?? [];
    final includes  = (widget.booking.extras['includes']  as List?)?.cast<String>() ?? [];
    final items = [...amenities, ...includes];
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.secondarySurface, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 20),
          ),
          const SizedBox(width: 10),
          Text(amenities.isNotEmpty ? _t('المرافق', 'Amenities') : _t('يشمل', 'Includes'),
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: items.map((item) =>
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.12)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_rounded, size: 12, color: AppColors.success),
              const SizedBox(width: 5),
              Text(item, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textPrimary)),
            ]),
          )
        ).toList()),
      ]),
    );
  }

  // ════════════════════════════════════════════════
  //  Notes
  // ════════════════════════════════════════════════
  Widget _buildNotesSection() {
    final notes = widget.isArabic && widget.booking.notesAr.isNotEmpty
        ? widget.booking.notesAr
        : widget.booking.notes;
    if (notes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.sticky_note_2_rounded, color: AppColors.secondary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t('ملاحظات', 'Notes'),
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.secondary)),
          const SizedBox(height: 4),
          Text(notes, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary, height: 1.6)),
        ])),
      ]),
    );
  }

  // ════════════════════════════════════════════════
  //  Offline Badge
  // ════════════════════════════════════════════════
  Widget _buildOfflineBadge() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2535),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Icon(Icons.offline_pin_rounded, color: Color(0xFF52C77E), size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t('محفوظ للاستخدام دون إنترنت', 'Saved for offline use'),
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(
            _t('يمكنك رؤية هذه التذكرة حتى بدون اتصال بالإنترنت',
               'You can view this ticket even without internet'),
            style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white.withOpacity(0.6)),
          ),
        ])),
      ]),
    );
  }

  void _shareTicket() {
    HapticFeedback.mediumImpact();
    // Would use share_plus in production
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_t('سيتم مشاركة التذكرة قريباً', 'Share feature coming soon'),
          style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ════════════════════════════════════════════════════════════
//  Helper Widgets
// ════════════════════════════════════════════════════════════

class _DateColumn extends StatelessWidget {
  final String label, dateStr;
  final DateTime date;
  final bool isArabic, alignEnd;

  const _DateColumn({
    required this.label, required this.date, required this.dateStr,
    required this.isArabic, this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.textHint)),
      const SizedBox(height: 3),
      Text(dateStr, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      Text('${isArabic ? _weekdayAr(date.weekday) : _weekdayEn(date.weekday)}',
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary)),
    ],
  );

  static String _weekdayAr(int d) => ['الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت','الأحد'][d-1];
  static String _weekdayEn(int d) => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d-1];
}

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppColors.textSecondary),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _StatusBadge extends StatelessWidget {
  final BookingStatus status; final bool isArabic;
  const _StatusBadge({required this.status, required this.isArabic});

  Color get _color {
    switch (status) {
      case BookingStatus.confirmed: return AppColors.success;
      case BookingStatus.checkedIn: return AppColors.primaryLight;
      case BookingStatus.pending:   return AppColors.warning;
      case BookingStatus.cancelled: return AppColors.error;
      case BookingStatus.completed: return AppColors.textSecondary;
      case BookingStatus.upcoming:
        // TODO: Handle this case.
        throw UnimplementedError();
      case BookingStatus.ongoing:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: _color.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(status.emoji, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 4),
      Text(isArabic ? status.nameAr : status.nameEn,
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _TypeBadge extends StatelessWidget {
  final BookingServiceType serviceType; final bool isArabic;
  const _TypeBadge({required this.serviceType, required this.isArabic});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(serviceType.emoji, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 4),
      Text(isArabic ? serviceType.nameAr : serviceType.nameEn,
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _OfflineChip extends StatelessWidget {
  final bool isArabic;
  const _OfflineChip({required this.isArabic});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 12),
      const SizedBox(width: 4),
      Text(isArabic ? 'بلا إنترنت' : 'Offline',
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 10)),
    ]),
  );
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _CircleNotch(left: true),
      Expanded(child: LayoutBuilder(builder: (_, c) {
        final count = (c.maxWidth / 10).floor();
        return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(count, (_) =>
          Container(width: 5, height: 1.5, color: AppColors.textHint.withOpacity(0.3)),
        ));
      })),
      _CircleNotch(left: false),
    ]);
  }
}

class _CircleNotch extends StatelessWidget {
  final bool left;
  const _CircleNotch({required this.left});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(left ? -12 : 12, 0),
      child: Container(
        width: 22, height: 22,
        decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
      ),
    );
  }
}

class _MapSketchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 6..style = PaintingStyle.stroke;
    final road2 = Paint()..color = Colors.white.withOpacity(0.25)..strokeWidth = 3..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height * 0.45), Offset(size.width, size.height * 0.55), road);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.45, size.height), road2);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.65), road2);
  }
  @override
  bool shouldRepaint(_) => false;
}
