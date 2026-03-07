import 'dart:async';
import 'dart:ui' as ui;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/map_marker.dart';

// ════════════════════════════════════════════════════════════
//  EVENTS
// ════════════════════════════════════════════════════════════
abstract class MapEvent extends Equatable {
  const MapEvent();
  @override
  List<Object?> get props => [];
}

class LoadMapMarkersEvent extends MapEvent {
  const LoadMapMarkersEvent();
}

class SelectMarkerEvent extends MapEvent {
  final String? markerId; // null = deselect
  const SelectMarkerEvent(this.markerId);
  @override
  List<Object?> get props => [markerId];
}

class UpdateFilterEvent extends MapEvent {
  final MapFilter filter;
  const UpdateFilterEvent(this.filter);
  @override
  List<Object?> get props => [filter];
}

class CameraMovedEvent extends MapEvent {
  final LatLng center;
  final double zoom;
  const CameraMovedEvent(this.center, this.zoom);
  @override
  List<Object?> get props => [center, zoom];
}

class ToggleMapStyleEvent extends MapEvent {
  const ToggleMapStyleEvent();
}

class SearchNearbyEvent extends MapEvent {
  final LatLng center;
  final double radiusKm;
  const SearchNearbyEvent(this.center, this.radiusKm);
  @override
  List<Object?> get props => [center, radiusKm];
}

// ════════════════════════════════════════════════════════════
//  STATES
// ════════════════════════════════════════════════════════════
abstract class MapState extends Equatable {
  const MapState();
  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {}
class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final List<MapMarkerData> allMarkers;
  final Set<Marker> googleMarkers;
  final MapFilter filter;
  final String? selectedMarkerId;
  final LatLng cameraCenter;
  final double cameraZoom;
  final bool isDarkStyle;
  final String? mapStyle;

  const MapLoaded({
    required this.allMarkers,
    required this.googleMarkers,
    required this.filter,
    this.selectedMarkerId,
    this.cameraCenter = const LatLng(25.2048, 55.2708), // Dubai default
    this.cameraZoom = 5.0,
    this.isDarkStyle = false,
    this.mapStyle,
  });

  MapMarkerData? get selectedMarker =>
      selectedMarkerId == null
          ? null
          : allMarkers.where((m) => m.id == selectedMarkerId).firstOrNull;

  List<MapMarkerData> get filteredMarkers => allMarkers.where((m) {
        if (!filter.enabledTypes.contains(m.type)) return false;
        if (m.price > filter.maxPrice) return false;
        if (m.rating < filter.minRating) return false;
        if (filter.showVerifiedOnly && !m.isVerified) return false;
        return true;
      }).toList();

  MapLoaded copyWith({
    List<MapMarkerData>? allMarkers,
    Set<Marker>? googleMarkers,
    MapFilter? filter,
    String? Function()? selectedMarkerId,
    LatLng? cameraCenter,
    double? cameraZoom,
    bool? isDarkStyle,
    String? Function()? mapStyle,
  }) =>
      MapLoaded(
        allMarkers:      allMarkers     ?? this.allMarkers,
        googleMarkers:   googleMarkers  ?? this.googleMarkers,
        filter:          filter         ?? this.filter,
        selectedMarkerId: selectedMarkerId != null ? selectedMarkerId() : this.selectedMarkerId,
        cameraCenter:    cameraCenter   ?? this.cameraCenter,
        cameraZoom:      cameraZoom     ?? this.cameraZoom,
        isDarkStyle:     isDarkStyle    ?? this.isDarkStyle,
        mapStyle:        mapStyle != null ? mapStyle() : this.mapStyle,
      );

  @override
  List<Object?> get props =>
      [allMarkers, filter, selectedMarkerId, cameraCenter, cameraZoom, isDarkStyle];
}

class MapError extends MapState {
  final String message;
  const MapError(this.message);
  @override
  List<Object?> get props => [message];
}

// ════════════════════════════════════════════════════════════
//  BLOC
// ════════════════════════════════════════════════════════════
class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc() : super(MapInitial()) {
    on<LoadMapMarkersEvent>(_onLoad);
    on<SelectMarkerEvent>(_onSelect);
    on<UpdateFilterEvent>(_onFilter);
    on<CameraMovedEvent>(_onCamera);
    on<ToggleMapStyleEvent>(_onToggleStyle);
    on<SearchNearbyEvent>(_onSearchNearby);
  }

  // ── Load all markers ─────────────────────────────
  Future<void> _onLoad(
      LoadMapMarkersEvent event, Emitter<MapState> emit) async {
    emit(MapLoading());

    final markers = _buildMockMarkers();
    final filter = const MapFilter();
    final googleMarkers =
        await _buildGoogleMarkers(markers, filter, null);

    emit(MapLoaded(
      allMarkers:    markers,
      googleMarkers: googleMarkers,
      filter:        filter,
    ));
  }

  // ── Select / deselect marker ─────────────────────
  Future<void> _onSelect(
      SelectMarkerEvent event, Emitter<MapState> emit) async {
    if (state is! MapLoaded) return;
    final current = state as MapLoaded;
    HapticFeedback.lightImpact();

    final updated = current.copyWith(
      selectedMarkerId: () => event.markerId,
    );

    // Rebuild markers so selected one gets highlighted icon
    final googleMarkers = await _buildGoogleMarkers(
      current.filteredMarkers,
      current.filter,
      event.markerId,
    );

    emit(updated.copyWith(googleMarkers: googleMarkers));
  }

  // ── Apply filter ─────────────────────────────────
  Future<void> _onFilter(
      UpdateFilterEvent event, Emitter<MapState> emit) async {
    if (state is! MapLoaded) return;
    final current = state as MapLoaded;

    final updated = current.copyWith(
      filter: event.filter,
      selectedMarkerId: () => null,
    );

    final googleMarkers = await _buildGoogleMarkers(
      updated.filteredMarkers,
      event.filter,
      null,
    );

    emit(updated.copyWith(googleMarkers: googleMarkers));
  }

  // ── Camera moved ─────────────────────────────────
  void _onCamera(CameraMovedEvent event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return;
    emit((state as MapLoaded).copyWith(
      cameraCenter: event.center,
      cameraZoom: event.zoom,
    ));
  }

  // ── Toggle dark style ─────────────────────────────
  Future<void> _onToggleStyle(
      ToggleMapStyleEvent event, Emitter<MapState> emit) async {
    if (state is! MapLoaded) return;
    final current = state as MapLoaded;
    final isDark = !current.isDarkStyle;
    emit(current.copyWith(
      isDarkStyle: isDark,
      mapStyle: () => isDark ? _darkMapStyle : null,
    ));
  }

  // ── Search nearby ─────────────────────────────────
  void _onSearchNearby(
      SearchNearbyEvent event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return;
    final current = state as MapLoaded;
    // Filter markers within radius
    final nearby = current.allMarkers.where((m) {
      final dist = _distance(event.center, m.position);
      return dist <= event.radiusKm;
    }).toList();
    // For now just update camera to center
    emit(current.copyWith(cameraCenter: event.center));
  }

  // ════════════════════════════════════════════════
  //  Build Google Markers with custom bitmaps
  // ════════════════════════════════════════════════
  Future<Set<Marker>> _buildGoogleMarkers(
    List<MapMarkerData> markers,
    MapFilter filter,
    String? selectedId,
  ) async {
    final Set<Marker> result = {};

    for (final m in markers) {
      if (!filter.enabledTypes.contains(m.type)) continue;
      if (m.price > filter.maxPrice) continue;
      if (m.rating < filter.minRating) continue;

      final isSelected = m.id == selectedId;
      final icon = await _createMarkerBitmap(m, isSelected);

      result.add(Marker(
        markerId: MarkerId(m.id),
        position: m.position,
        icon: icon,
        zIndex: isSelected ? 2.0 : 1.0,
        onTap: () => add(SelectMarkerEvent(
          isSelected ? null : m.id,
        )),
        infoWindow: InfoWindow.noText,
      ));
    }

    return result;
  }

  // ── Custom marker bitmap (price bubble) ──────────
  Future<BitmapDescriptor> _createMarkerBitmap(
      MapMarkerData m, bool isSelected) async {
    const size = 120.0;
    const height = 148.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // ── Bubble colors ──────────────────────────────
    final Color bg;
    switch (m.type) {
      case MarkerType.hotel:
        bg = isSelected ? const Color(0xFF0B4F6C) : const Color(0xFF1A7FA8);
        break;
      case MarkerType.travelAgency:
        bg = isSelected ? const Color(0xFFD85A2A) : const Color(0xFFFF6B47);
        break;
      case MarkerType.tourGuide:
        bg = isSelected ? const Color(0xFFD4920A) : const Color(0xFFF0A500);
        break;
      case MarkerType.activity:
        bg = isSelected ? const Color(0xFF1E7A45) : const Color(0xFF27AE60);
        break;
    }

    // Shadow
    final shadowPaint = Paint()
      ..color = bg.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(4, 6, size - 8, 52), const Radius.circular(24)),
      shadowPaint,
    );

    // Main bubble
    final bubblePaint = Paint()..color = bg;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, size, 52), const Radius.circular(26)),
      bubblePaint,
    );

    // White border if selected
    if (isSelected) {
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(1.5, 1.5, size - 3, 49), const Radius.circular(24)),
        borderPaint,
      );
    }

    // Triangle pointer
    final path = Path()
      ..moveTo(size / 2 - 10, 50)
      ..lineTo(size / 2 + 10, 50)
      ..lineTo(size / 2, 68)
      ..close();
    canvas.drawPath(path, bubblePaint);

    // Price text
    final price = '\$${m.price.toInt()}';
    final textPainter = TextPainter(
      text: TextSpan(
        text: price,
        style: TextStyle(
          color: Colors.white,
          fontSize: isSelected ? 21 : 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size);

    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (52 - textPainter.height) / 2),
    );

    // Dot indicator for verified
    if (m.isVerified) {
      canvas.drawCircle(
        const Offset(size - 14, 14),
        7,
        Paint()..color = const Color(0xFF27AE60),
      );
      canvas.drawCircle(
        const Offset(size - 14, 14),
        7,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), height.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  // ════════════════════════════════════════════════
  //  Mock marker data (Hotels + Travel Packages)
  // ════════════════════════════════════════════════
  static List<MapMarkerData> _buildMockMarkers() => [
    // ── Dubai Hotels ────────────────────────────
    const MapMarkerData(
      id: 'h_burj_khalifa',
      name: 'Armani Hotel Dubai',
      nameAr: 'فندق أرماني دبي',
      type: MarkerType.hotel,
      position: LatLng(25.1972, 55.2744),
      price: 950,
      rating: 4.9,
      reviewCount: 2341,
      imageUrl: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=600',
      city: 'Dubai', cityAr: 'دبي',
      address: 'Burj Khalifa, Downtown Dubai',
      isVerified: true, isFeatured: true, stars: 5,
    ),
    const MapMarkerData(
      id: 'h_atlantis',
      name: 'Atlantis The Palm',
      nameAr: 'أتلانتس النخلة',
      type: MarkerType.hotel,
      position: LatLng(25.1304, 55.1175),
      price: 780,
      rating: 4.7,
      reviewCount: 5432,
      imageUrl: 'https://images.unsplash.com/photo-1615460549969-36fa19521a4f?w=600',
      city: 'Dubai', cityAr: 'دبي',
      address: 'Palm Jumeirah, Dubai',
      isVerified: true, stars: 5,
    ),
    const MapMarkerData(
      id: 'h_burj_arab',
      name: 'Burj Al Arab Jumeirah',
      nameAr: 'برج العرب جميرا',
      type: MarkerType.hotel,
      position: LatLng(25.1412, 55.1852),
      price: 1850,
      rating: 4.95,
      reviewCount: 8900,
      imageUrl: 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600',
      city: 'Dubai', cityAr: 'دبي',
      address: 'Jumeirah Beach Road',
      isVerified: true, isFeatured: true, stars: 7,
    ),
    const MapMarkerData(
      id: 'h_address',
      name: 'Address Downtown',
      nameAr: 'أدريس داون تاون',
      type: MarkerType.hotel,
      position: LatLng(25.1892, 55.2792),
      price: 620,
      rating: 4.6,
      reviewCount: 3120,
      imageUrl: 'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=600',
      city: 'Dubai', cityAr: 'دبي',
      address: 'Downtown Dubai',
      isVerified: true, stars: 5,
    ),
    const MapMarkerData(
      id: 'h_ritz',
      name: 'The Ritz-Carlton DIFC',
      nameAr: 'ريتز كارلتون ديفك',
      type: MarkerType.hotel,
      position: LatLng(25.2132, 55.2832),
      price: 720,
      rating: 4.8,
      reviewCount: 1890,
      imageUrl: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=600',
      city: 'Dubai', cityAr: 'دبي',
      address: 'DIFC, Dubai',
      isVerified: true, stars: 5,
    ),

    // ── Abu Dhabi Hotels ─────────────────────────
    const MapMarkerData(
      id: 'h_emirates_palace',
      name: 'Emirates Palace',
      nameAr: 'قصر الإمارات',
      type: MarkerType.hotel,
      position: LatLng(24.4609, 54.3135),
      price: 1200,
      rating: 4.9,
      reviewCount: 4567,
      imageUrl: 'https://images.unsplash.com/photo-1568084680786-a84f91d1153c?w=600',
      city: 'Abu Dhabi', cityAr: 'أبوظبي',
      address: 'West Corniche Road, Abu Dhabi',
      isVerified: true, isFeatured: true, stars: 5,
    ),

    // ── Travel Packages ──────────────────────────
    const MapMarkerData(
      id: 'pkg_maldives',
      name: 'Maldives Paradise',
      nameAr: 'جنة المالديف',
      type: MarkerType.travelAgency,
      position: LatLng(4.1755, 73.5093),
      price: 2499,
      rating: 4.9,
      reviewCount: 1243,
      imageUrl: 'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?w=600',
      city: 'Malé', cityAr: 'ماليه',
      isVerified: true, isFeatured: true, durationDays: 7,
    ),
    const MapMarkerData(
      id: 'pkg_bali',
      name: 'Bali Spirit Retreat',
      nameAr: 'رحلة بالي الروحانية',
      type: MarkerType.travelAgency,
      position: LatLng(-8.5069, 115.2625),
      price: 1750,
      rating: 4.7,
      reviewCount: 876,
      imageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600',
      city: 'Bali', cityAr: 'بالي',
      isVerified: true, durationDays: 6,
    ),
    const MapMarkerData(
      id: 'pkg_tokyo',
      name: 'Tokyo Hidden Gems',
      nameAr: 'كنوز طوكيو الخفية',
      type: MarkerType.tourGuide,
      position: LatLng(35.6762, 139.6503),
      price: 890,
      rating: 4.8,
      reviewCount: 654,
      imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=600',
      city: 'Tokyo', cityAr: 'طوكيو',
      isVerified: true, durationDays: 3,
    ),
    const MapMarkerData(
      id: 'pkg_paris',
      name: 'Paris Luxury Tour',
      nameAr: 'جولة باريس الفاخرة',
      type: MarkerType.travelAgency,
      position: LatLng(48.8566, 2.3522),
      price: 3200,
      rating: 4.85,
      reviewCount: 2100,
      imageUrl: 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=600',
      city: 'Paris', cityAr: 'باريس',
      isVerified: true, isFeatured: true, durationDays: 5,
    ),
    const MapMarkerData(
      id: 'pkg_santorini',
      name: 'Santorini Getaway',
      nameAr: 'عطلة سانتوريني',
      type: MarkerType.travelAgency,
      position: LatLng(36.3932, 25.4615),
      price: 2100,
      rating: 4.75,
      reviewCount: 987,
      imageUrl: 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=600',
      city: 'Santorini', cityAr: 'سانتوريني',
      isVerified: true, durationDays: 4,
    ),
    const MapMarkerData(
      id: 'pkg_safari',
      name: 'Kenya Wildlife Safari',
      nameAr: 'سفاري كينيا البري',
      type: MarkerType.activity,
      position: LatLng(-1.2921, 36.8219),
      price: 4500,
      rating: 4.95,
      reviewCount: 445,
      imageUrl: 'https://images.unsplash.com/photo-1547036967-23d11aacaee0?w=600',
      city: 'Nairobi', cityAr: 'نيروبي',
      isVerified: true, isFeatured: true, durationDays: 7,
    ),
    const MapMarkerData(
      id: 'pkg_amsterdam',
      name: 'Amsterdam Explorer',
      nameAr: 'مستكشف أمستردام',
      type: MarkerType.tourGuide,
      position: LatLng(52.3676, 4.9041),
      price: 680,
      rating: 4.6,
      reviewCount: 321,
      imageUrl: 'https://images.unsplash.com/photo-1534351590666-13e3e96b5017?w=600',
      city: 'Amsterdam', cityAr: 'أمستردام',
      durationDays: 2,
    ),
    const MapMarkerData(
      id: 'pkg_new_york',
      name: 'New York City Break',
      nameAr: 'عطلة نيويورك',
      type: MarkerType.travelAgency,
      position: LatLng(40.7128, -74.0060),
      price: 2800,
      rating: 4.7,
      reviewCount: 1543,
      imageUrl: 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=600',
      city: 'New York', cityAr: 'نيويورك',
      isVerified: true, durationDays: 5,
    ),
  ];

  // Distance in km between two LatLngs (Haversine approx)
  double _distance(LatLng a, LatLng b) {
    const r = 6371.0;
    final dlat = (b.latitude - a.latitude) * 3.14159 / 180;
    final dlon = (b.longitude - a.longitude) * 3.14159 / 180;
    final sinDlat = dlat / 2;
    final sinDlon = dlon / 2;
    final aa = sinDlat * sinDlat +
        sinDlon * sinDlon * 0.999;
    return r * 2 * 0.9999 * aa;
  }

  // ── Dark map style JSON ───────────────────────────
  static const String _darkMapStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
    {"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e6d70"}]},
    {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#283d6a"}]},
    {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#406d76"}]}
  ]''';
}
