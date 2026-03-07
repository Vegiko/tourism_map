import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/map_marker.dart';
import '../bloc/map_bloc.dart';
import '../widgets/marker_info_card.dart';
import '../widgets/map_filter_sheet.dart';

// ════════════════════════════════════════════════════════════
//  Entry Point
// ════════════════════════════════════════════════════════════
class MapExploreScreen extends StatelessWidget {
  final bool isArabic;
  final Function(MapMarkerData marker)? onBookNow;

  const MapExploreScreen({
    super.key,
    required this.isArabic,
    this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MapBloc()..add(const LoadMapMarkersEvent()),
      child: _MapView(isArabic: isArabic, onBookNow: onBookNow),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Map View
// ════════════════════════════════════════════════════════════
class _MapView extends StatefulWidget {
  final bool isArabic;
  final Function(MapMarkerData)? onBookNow;
  const _MapView({required this.isArabic, this.onBookNow});

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  late AnimationController _fabCtrl;
  late AnimationController _cardCtrl;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  // Search
  final _searchCtrl = TextEditingController();
  bool _searchFocused = false;

  static const _initialCamera = CameraPosition(
    target: LatLng(25.2048, 55.2708), // Dubai
    zoom: 5.5,
  );

  String _t(String ar, String en) => widget.isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardFade =
        CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _fabCtrl.forward();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _fabCtrl.dispose();
    _cardCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Animate to selected marker ────────────────────
  void _animateToMarker(MapMarkerData marker) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            marker.position.latitude - 0.4,
            marker.position.longitude,
          ),
          zoom: 8.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: BlocListener<MapBloc, MapState>(
        listener: (ctx, state) {
          if (state is MapLoaded) {
            if (state.selectedMarkerId != null) {
              _cardCtrl.forward();
              if (state.selectedMarker != null) {
                _animateToMarker(state.selectedMarker!);
              }
            } else {
              _cardCtrl.reverse();
            }

            // Apply map style
            if (_mapController != null && state.mapStyle != null) {
              _mapController!.setMapStyle(state.mapStyle);
            } else if (_mapController != null && state.mapStyle == null) {
              _mapController!.setMapStyle(null);
            }
          }
        },
        child: Scaffold(
          body: Stack(
            children: [
              // ── Google Map ─────────────────────────
              BlocBuilder<MapBloc, MapState>(
                builder: (ctx, state) {
                  if (state is MapLoading || state is MapInitial) {
                    return _buildMapPlaceholder();
                  }
                  if (state is MapLoaded) {
                    return GoogleMap(
                      initialCameraPosition: _initialCamera,
                      markers: state.googleMarkers,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        if (state.mapStyle != null) {
                          controller.setMapStyle(state.mapStyle);
                        }
                      },
                      onCameraMove: (pos) => ctx.read<MapBloc>().add(
                            CameraMovedEvent(pos.target, pos.zoom),
                          ),
                      onTap: (_) => ctx.read<MapBloc>().add(
                            const SelectMarkerEvent(null),
                          ),
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: true,
                      buildingsEnabled: true,
                      mapType: MapType.normal,
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.height * 0.35,
                        top: 140,
                      ),
                    );
                  }
                  return _buildMapPlaceholder();
                },
              ),

              // ── Top overlay (search + header) ──────
              SafeArea(child: _buildTopOverlay(context)),

              // ── FABs (right side) ──────────────────
              _buildFabColumn(context),

              // ── Marker count pill ──────────────────
              _buildMarkerCountPill(context),

              // ── Marker info bottom card ─────────────
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: _buildInfoCard(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Map Placeholder ──────────────────────────────
  Widget _buildMapPlaceholder() {
    return Container(
      color: const Color(0xFFE8F0FE),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(_t('جارٍ تحميل الخريطة...', 'Loading map...'),
              style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary)),
        ]),
      ),
    );
  }

  // ── Top Overlay ──────────────────────────────────
  Widget _buildTopOverlay(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Header row
        Row(children: [
          // Title card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.map_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(_t('الخريطة السياحية', 'Travel Map'),
                  style: const TextStyle(
                      fontFamily: 'Cairo', color: Colors.white,
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ]),
          ),
          const Spacer(),
          // Style toggle
          BlocBuilder<MapBloc, MapState>(builder: (ctx, state) {
            final isDark = state is MapLoaded && state.isDarkStyle;
            return GestureDetector(
              onTap: () => ctx.read<MapBloc>().add(const ToggleMapStyleEvent()),
              child: _MapIconBtn(
                icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                active: isDark,
              ),
            );
          }),
          const SizedBox(width: 8),
          // Filter button
          BlocBuilder<MapBloc, MapState>(builder: (ctx, state) {
            final hasFilter = state is MapLoaded && !state.filter.isDefault;
            return GestureDetector(
              onTap: () => _showFilterSheet(ctx),
              child: _MapIconBtn(
                icon: Icons.tune_rounded,
                active: hasFilter,
                badge: hasFilter,
              ),
            );
          }),
        ]),
        const SizedBox(height: 10),
        // Search bar
        _buildSearchBar(ctx),
        const SizedBox(height: 10),
        // Type filter chips
        _buildTypeChips(ctx),
      ]),
    );
  }

  // ── Search Bar ───────────────────────────────────
  Widget _buildSearchBar(BuildContext ctx) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_searchFocused ? 0.15 : 0.08),
            blurRadius: _searchFocused ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: _searchFocused
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
      child: Row(children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
        ),
        Expanded(
          child: Focus(
            onFocusChange: (f) => setState(() => _searchFocused = f),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(
                  fontFamily: 'Cairo', fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: _t('ابحث عن فنادق، وجهات...', 'Search hotels, destinations...'),
                hintStyle: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 13, color: AppColors.textHint),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (v) => setState(() {}),
            ),
          ),
        ),
        if (_searchCtrl.text.isNotEmpty)
          GestureDetector(
            onTap: () => setState(() => _searchCtrl.clear()),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.close_rounded, color: AppColors.textHint, size: 18),
            ),
          ),
      ]),
    );
  }

  // ── Type Filter Chips ─────────────────────────────
  Widget _buildTypeChips(BuildContext ctx) {
    return BlocBuilder<MapBloc, MapState>(builder: (ctx, state) {
      if (state is! MapLoaded) return const SizedBox.shrink();
      final types = [
        (MarkerType.hotel,        _t('فنادق', 'Hotels'),        '🏨', const Color(0xFF1A7FA8)),
        (MarkerType.travelAgency, _t('باقات', 'Packages'),      '✈️', const Color(0xFFFF6B47)),
        (MarkerType.tourGuide,    _t('مرشدون', 'Guides'),       '🧭', const Color(0xFFF0A500)),
        (MarkerType.activity,     _t('أنشطة', 'Activities'),    '🏄', const Color(0xFF27AE60)),
      ];

      return SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: types.map((t) {
            final enabled = state.filter.enabledTypes.contains(t.$1);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                final current = Set<MarkerType>.from(state.filter.enabledTypes);
                if (enabled && current.length > 1) {
                  current.remove(t.$1);
                } else if (!enabled) {
                  current.add(t.$1);
                }
                ctx.read<MapBloc>().add(UpdateFilterEvent(
                  state.filter.copyWith(enabledTypes: current),
                ));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: enabled ? t.$4 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: enabled ? t.$4 : Colors.white),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(t.$2, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(t.$3,
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: enabled ? Colors.white : AppColors.textSecondary)),
                ]),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  // ── FAB column (zoom + locate) ────────────────────
  Widget _buildFabColumn(BuildContext ctx) {
    return Positioned(
      bottom: 260,
      right: 14,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut),
        child: Column(children: [
          _MapFab(
            icon: Icons.add_rounded,
            onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
          ),
          const SizedBox(height: 8),
          _MapFab(
            icon: Icons.remove_rounded,
            onTap: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
          ),
          const SizedBox(height: 8),
          _MapFab(
            icon: Icons.my_location_rounded,
            onTap: () => _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                const CameraPosition(target: LatLng(25.2048, 55.2708), zoom: 9),
              ),
            ),
            gradient: AppColors.primaryGradient,
            iconColor: Colors.white,
          ),
        ]),
      ),
    );
  }

  // ── Marker count pill ─────────────────────────────
  Widget _buildMarkerCountPill(BuildContext ctx) {
    return Positioned(
      bottom: 260,
      left: 14,
      child: BlocBuilder<MapBloc, MapState>(builder: (ctx, state) {
        if (state is! MapLoaded) return const SizedBox.shrink();
        final count = state.filteredMarkers.length;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.place_rounded, color: AppColors.primary, size: 15),
            const SizedBox(width: 5),
            Text('$count ${_t("موقع", "locations")}',
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ]),
        );
      }),
    );
  }

  // ── Marker Info Card ─────────────────────────────
  Widget _buildInfoCard(BuildContext ctx) {
    return BlocBuilder<MapBloc, MapState>(builder: (ctx, state) {
      if (state is! MapLoaded || state.selectedMarker == null) {
        return const SizedBox.shrink();
      }
      return SlideTransition(
        position: _cardSlide,
        child: FadeTransition(
          opacity: _cardFade,
          child: MarkerInfoCard(
            marker: state.selectedMarker!,
            isArabic: widget.isArabic,
            onClose: () => ctx.read<MapBloc>().add(const SelectMarkerEvent(null)),
            onBookNow: () {
              if (widget.onBookNow != null) {
                widget.onBookNow!(state.selectedMarker!);
              }
            },
          ),
        ),
      );
    });
  }

  // ── Filter Sheet ─────────────────────────────────
  void _showFilterSheet(BuildContext ctx) {
    final mapBloc = ctx.read<MapBloc>();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: mapBloc,
        child: MapFilterSheet(isArabic: widget.isArabic),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Small helper widgets
// ════════════════════════════════════════════════════════════

class _MapIconBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final bool badge;

  const _MapIconBtn({required this.icon, this.active = false, this.badge = false});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Icon(icon,
            color: active ? Colors.white : AppColors.textSecondary, size: 20),
      ),
      if (badge)
        Positioned(
          top: 6, right: 6,
          child: Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
                color: AppColors.accent, shape: BoxShape.circle),
          ),
        ),
    ]);
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Gradient? gradient;
  final Color iconColor;

  const _MapFab({
    required this.icon,
    required this.onTap,
    this.gradient,
    this.iconColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: gradient == null ? Colors.white : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}
