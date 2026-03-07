import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/map_marker.dart';
import '../bloc/map_bloc.dart';

class MapFilterSheet extends StatefulWidget {
  final bool isArabic;
  const MapFilterSheet({super.key, required this.isArabic});

  @override
  State<MapFilterSheet> createState() => _MapFilterSheetState();
}

class _MapFilterSheetState extends State<MapFilterSheet> {
  late MapFilter _filter;

  String _t(String ar, String en) => widget.isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    final state = context.read<MapBloc>().state;
    _filter = state is MapLoaded ? state.filter : const MapFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Header
                Row(children: [
                  const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(_t('تصفية النتائج', 'Filter Results'),
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() => _filter = const MapFilter());
                    },
                    child: Text(_t('إعادة تعيين', 'Reset'),
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 20),

                // ── Types ────────────────────────────
                _SectionLabel(_t('نوع الخدمة', 'Service Type')),
                const SizedBox(height: 10),
                _buildTypeToggles(),
                const SizedBox(height: 20),

                // ── Max Price ─────────────────────────
                _SectionLabel(
                  '${_t("الحد الأقصى للسعر", "Max Price")} — \$${_filter.maxPrice.toInt()}',
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withOpacity(0.15),
                    inactiveTrackColor: AppColors.primarySurface,
                  ),
                  child: Slider(
                    value: _filter.maxPrice,
                    min: 100,
                    max: 5000,
                    divisions: 49,
                    onChanged: (v) => setState(
                      () => _filter = _filter.copyWith(maxPrice: v),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Min Rating ────────────────────────
                _SectionLabel(
                  '${_t("الحد الأدنى للتقييم", "Min Rating")} — ${_filter.minRating.toStringAsFixed(1)} ⭐',
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFF0A500),
                    thumbColor: const Color(0xFFF0A500),
                    overlayColor: const Color(0xFFF0A500).withOpacity(0.15),
                    inactiveTrackColor: AppColors.secondarySurface,
                  ),
                  child: Slider(
                    value: _filter.minRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    onChanged: (v) => setState(
                      () => _filter = _filter.copyWith(minRating: v),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Verified only ─────────────────────
                _buildVerifiedToggle(),
                const SizedBox(height: 24),

                // ── Apply button ──────────────────────
                GestureDetector(
                  onTap: () {
                    context.read<MapBloc>().add(UpdateFilterEvent(_filter));
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Center(
                      child: Text(_t('تطبيق الفلاتر', 'Apply Filters'),
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggles() {
    final types = [
      (MarkerType.hotel,        _t('فنادق', 'Hotels'),        '🏨'),
      (MarkerType.travelAgency, _t('باقات سياحية', 'Packages'), '✈️'),
      (MarkerType.tourGuide,    _t('مرشدون', 'Tour Guides'),  '🧭'),
      (MarkerType.activity,     _t('أنشطة', 'Activities'),   '🏄'),
    ];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: types.map((t) {
        final enabled = _filter.enabledTypes.contains(t.$1);
        return GestureDetector(
          onTap: () {
            final current = Set<MarkerType>.from(_filter.enabledTypes);
            if (enabled && current.length > 1) current.remove(t.$1);
            else if (!enabled) current.add(t.$1);
            setState(() => _filter = _filter.copyWith(enabledTypes: current));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: enabled ? AppColors.primaryGradient : null,
              color: enabled ? null : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              boxShadow: enabled
                  ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                  : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(t.$2, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(t.$3,
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: enabled ? Colors.white : AppColors.textSecondary)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVerifiedToggle() {
    return GestureDetector(
      onTap: () => setState(() =>
          _filter = _filter.copyWith(showVerifiedOnly: !_filter.showVerifiedOnly)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _filter.showVerifiedOnly
              ? AppColors.success.withOpacity(0.08)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: _filter.showVerifiedOnly
              ? Border.all(color: AppColors.success.withOpacity(0.3))
              : null,
        ),
        child: Row(children: [
          const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_t('المواقع الموثقة فقط', 'Verified locations only'),
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            Text(_t('عرض نتائج معتمدة فقط', 'Show only certified results'),
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.textSecondary)),
          ])),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44, height: 24,
            decoration: BoxDecoration(
              color: _filter.showVerifiedOnly ? AppColors.success : AppColors.textHint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: _filter.showVerifiedOnly
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 20, height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));
}
