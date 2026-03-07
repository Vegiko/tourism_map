import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/map_marker.dart';

class MarkerInfoCard extends StatefulWidget {
  final MapMarkerData marker;
  final bool isArabic;
  final VoidCallback onClose;
  final VoidCallback onBookNow;

  const MarkerInfoCard({
    super.key,
    required this.marker,
    required this.isArabic,
    required this.onClose,
    required this.onBookNow,
  });

  @override
  State<MarkerInfoCard> createState() => _MarkerInfoCardState();
}

class _MarkerInfoCardState extends State<MarkerInfoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimCtrl;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _shimCtrl.dispose();
    super.dispose();
  }

  String _t(String ar, String en) => widget.isArabic ? ar : en;
  MapMarkerData get m => widget.marker;

  Color get _typeColor {
    switch (m.type) {
      case MarkerType.hotel:        return const Color(0xFF1A7FA8);
      case MarkerType.travelAgency: return const Color(0xFFFF6B47);
      case MarkerType.tourGuide:    return const Color(0xFFF0A500);
      case MarkerType.activity:     return const Color(0xFF27AE60);
    }
  }

  Gradient get _typeGradient {
    switch (m.type) {
      case MarkerType.hotel:        return AppColors.primaryGradient;
      case MarkerType.travelAgency: return AppColors.sunsetGradient;
      case MarkerType.tourGuide:
        return const LinearGradient(colors: [Color(0xFFF0A500), Color(0xFFD4920A)]);
      case MarkerType.activity:
        return const LinearGradient(colors: [Color(0xFF27AE60), Color(0xFF1E7A45)]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.isArabic && m.nameAr.isNotEmpty ? m.nameAr : m.name;
    final city = widget.isArabic && m.cityAr.isNotEmpty ? m.cityAr : m.city;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, -6)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── Handle ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.textHint.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Header row ──────────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 90, height: 90,
                  child: m.imageUrl.isNotEmpty
                      ? Image.network(m.imageUrl, fit: BoxFit.cover,
                          loadingBuilder: (_, child, prog) =>
                              prog == null ? child : _ImageShimmer(),
                          errorBuilder: (_, __, ___) => _TypeFallback(marker: m))
                      : _TypeFallback(marker: m),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Type + verified badges
                Row(children: [
                  _TypeBadge(marker: m, isArabic: widget.isArabic),
                  if (m.isVerified) ...[
                    const SizedBox(width: 6),
                    _VerifiedBadge(isArabic: widget.isArabic),
                  ],
                  const Spacer(),
                  // Close
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: AppColors.textHint),
                    ),
                  ),
                ]),
                const SizedBox(height: 6),

                // Name
                Text(name,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),

                // City + address
                if (city.isNotEmpty)
                  Row(children: [
                    Icon(Icons.location_on_rounded,
                        size: 12, color: _typeColor),
                    const SizedBox(width: 3),
                    Text(city,
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: _typeColor,
                            fontWeight: FontWeight.w600)),
                  ]),
              ])),
            ]),

            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF0F4F8)),
            const SizedBox(height: 12),

            // ── Stats row ────────────────────────────
            Row(children: [
              // Rating
              _StatChip(
                icon: Icons.star_rounded,
                value: m.rating > 0 ? m.rating.toStringAsFixed(1) : 'N/A',
                color: const Color(0xFFF0A500),
              ),
              const SizedBox(width: 8),
              // Reviews
              _StatChip(
                icon: Icons.reviews_rounded,
                value: m.reviewCount > 0 ? _formatCount(m.reviewCount) : '0',
                color: AppColors.primary,
              ),
              if (m.stars > 0) ...[
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.hotel_class_rounded,
                  value: '${'⭐' * m.stars.clamp(1, 5)}',
                  color: const Color(0xFFF0A500),
                ),
              ],
              if (m.durationDays > 0) ...[
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.schedule_rounded,
                  value: '${m.durationDays} ${_t("أيام", "days")}',
                  color: _typeColor,
                ),
              ],
              const Spacer(),
              // Featured badge
              if (m.isFeatured)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.sunsetGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('⭐ ${_t("مميز", "Featured")}',
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
            ]),

            const SizedBox(height: 16),

            // ── Price + Book button row ───────────────
            Row(children: [
              // Price block
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _t('يبدأ من', 'Starting from'),
                  style: const TextStyle(
                      fontFamily: 'Cairo', fontSize: 10, color: AppColors.textHint),
                ),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                    '\$${m.price.toInt()}',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _typeColor),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, right: 4, left: 4),
                    child: Text(
                      m.type == MarkerType.hotel
                          ? _t('/ ليلة', '/ night')
                          : _t('/ شخص', '/ person'),
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ]),
              ]),
              const Spacer(),

              // Directions button
              GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Container(
                  width: 50, height: 50,
                  margin: const EdgeInsets.only(left: 8, right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.directions_rounded,
                      color: AppColors.primary, size: 22),
                ),
              ),

              // Book Now button
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onBookNow();
                },
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: _typeGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _typeColor.withOpacity(0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.bolt_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _t('احجز الآن', 'Book Now'),
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ── Sub-widgets ──────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  final MapMarkerData marker;
  final bool isArabic;
  const _TypeBadge({required this.marker, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (marker.type) {
      case MarkerType.hotel:        color = const Color(0xFF1A7FA8); break;
      case MarkerType.travelAgency: color = const Color(0xFFFF6B47); break;
      case MarkerType.tourGuide:    color = const Color(0xFFF0A500); break;
      case MarkerType.activity:     color = const Color(0xFF27AE60); break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(marker.type.emoji, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 4),
        Text(
          isArabic ? marker.type.nameAr : marker.type.nameEn,
          style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color),
        ),
      ]),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  final bool isArabic;
  const _VerifiedBadge({required this.isArabic});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.success.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.success.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.verified_rounded, color: AppColors.success, size: 10),
      const SizedBox(width: 3),
      Text(isArabic ? 'موثق' : 'Verified',
          style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 9,
              color: AppColors.success,
              fontWeight: FontWeight.w700)),
    ]),
  );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _StatChip({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 4),
      Text(value,
          style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color)),
    ]),
  );
}

class _TypeFallback extends StatelessWidget {
  final MapMarkerData marker;
  const _TypeFallback({required this.marker});
  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (marker.type) {
      case MarkerType.hotel:        color = const Color(0xFF1A7FA8); break;
      case MarkerType.travelAgency: color = const Color(0xFFFF6B47); break;
      case MarkerType.tourGuide:    color = const Color(0xFFF0A500); break;
      case MarkerType.activity:     color = const Color(0xFF27AE60); break;
    }
    return Container(
      color: color.withOpacity(0.15),
      child: Center(
        child: Text(marker.type.emoji, style: const TextStyle(fontSize: 36)),
      ),
    );
  }
}

class _ImageShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surfaceVariant,
    child: const Center(
      child: SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
      ),
    ),
  );
}
