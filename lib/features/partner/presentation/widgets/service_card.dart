import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/partner_service.dart';

// ════════════════════════════════════════════════════════════
//  Service Card
// ════════════════════════════════════════════════════════════
class PartnerServiceCard extends StatefulWidget {
  final PartnerService service;
  final bool isArabic;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final void Function(ServiceStatus) onStatusChange;

  const PartnerServiceCard({
    super.key,
    required this.service,
    required this.isArabic,
    this.onEdit,
    this.onDelete,
    required this.onStatusChange,
  });

  @override
  State<PartnerServiceCard> createState() => _PartnerServiceCardState();
}

class _PartnerServiceCardState extends State<PartnerServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _t(String ar, String en) => widget.isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final name = widget.isArabic && s.nameAr.isNotEmpty ? s.nameAr : s.name;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
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
              // Image + status overlay
              _buildImageSection(s),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + type badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(s.serviceType.emoji,
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 5),
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
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 3),
                              Text(
                                widget.isArabic
                                    ? s.serviceType.nameAr
                                    : s.serviceType.nameEn,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status pill
                        _StatusPill(
                          status: s.status,
                          isArabic: widget.isArabic,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Metrics row
                    _buildMetricsRow(s),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 10),

                    // Actions row
                    _buildActionsRow(context, s),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(PartnerService s) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image or placeholder
            s.imageUrls.isNotEmpty
                ? Image.network(
                    s.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ImagePlaceholder(s),
                  )
                : _ImagePlaceholder(s),

            // Gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),

            // Image count
            if (s.imageUrls.length > 1)
              Positioned(
                bottom: 8,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.photo_library_rounded,
                        color: Colors.white, size: 10),
                    const SizedBox(width: 3),
                    Text('${s.imageUrls.length}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 10,
                        )),
                  ]),
                ),
              ),

            // Price badge
            Positioned(
              bottom: 8,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '\$${s.price.toInt()}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow(PartnerService s) {
    return Row(
      children: [
        _MetricChip(
          icon: Icons.book_online_rounded,
          value: '${s.bookingCount}',
          label: _t('حجز', 'Bookings'),
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        _MetricChip(
          icon: Icons.star_rounded,
          value: s.rating > 0 ? s.rating.toStringAsFixed(1) : '-',
          label: _t('تقييم', 'Rating'),
          color: AppColors.secondary,
        ),
        const SizedBox(width: 8),
        _MetricChip(
          icon: Icons.attach_money_rounded,
          value: '\$${s.totalRevenue.toInt()}',
          label: _t('أرباح', 'Revenue'),
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildActionsRow(BuildContext ctx, PartnerService s) {
    return Row(
      children: [
        // Toggle active/suspend
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onStatusChange(
                s.isActive ? ServiceStatus.suspended : ServiceStatus.active,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: s.isActive
                    ? AppColors.error.withOpacity(0.08)
                    : AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: s.isActive
                      ? AppColors.error.withOpacity(0.2)
                      : AppColors.success.withOpacity(0.2),
                ),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                  s.isActive
                      ? Icons.pause_circle_rounded
                      : Icons.play_circle_rounded,
                  size: 16,
                  color: s.isActive ? AppColors.error : AppColors.success,
                ),
                const SizedBox(width: 5),
                Text(
                  s.isActive
                      ? _t('إيقاف', 'Suspend')
                      : _t('تفعيل', 'Activate'),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: s.isActive ? AppColors.error : AppColors.success,
                  ),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Delete
        GestureDetector(
          onTap: () => _confirmDelete(ctx),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 18),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext ctx) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => Directionality(
        textDirection:
            widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(_t('حذف الخدمة', 'Delete Service'),
              style: const TextStyle(fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700)),
          content: Text(
            _t('هل أنت متأكد من حذف هذه الخدمة؟ لا يمكن التراجع.',
                'Are you sure you want to delete this service? This cannot be undone.'),
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_t('إلغاء', 'Cancel'),
                  style: const TextStyle(fontFamily: 'Cairo',
                      color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_t('حذف', 'Delete'),
                  style: const TextStyle(fontFamily: 'Cairo',
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) widget.onDelete?.call();
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final PartnerService s;
  const _ImagePlaceholder(this.s);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight.withOpacity(0.2),
            AppColors.primary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(s.serviceType.emoji,
              style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 6),
          const Icon(Icons.add_photo_alternate_rounded,
              color: AppColors.textHint, size: 20),
        ]),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ServiceStatus status;
  final bool isArabic;
  const _StatusPill({required this.status, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: status.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          isArabic ? status.nameAr : status.name,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: status.color,
          ),
        ),
      ]),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(label,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 9,
                        color: AppColors.textHint,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Empty Services State
// ════════════════════════════════════════════════════════════
class EmptyServicesWidget extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onAdd;

  const EmptyServicesWidget({
    super.key,
    required this.isArabic,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primaryLight.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_business_rounded,
                  color: AppColors.primary, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              isArabic ? 'لا توجد خدمات بعد' : 'No Services Yet',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'أضف خدمتك الأولى وابدأ في استقبال الحجوزات من العملاء'
                  : 'Add your first service and start receiving bookings from customers',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.sunsetGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    isArabic ? 'إضافة خدمة' : 'Add Service',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
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
