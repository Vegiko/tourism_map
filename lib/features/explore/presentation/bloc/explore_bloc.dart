import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/explore_entities.dart';
import '../../data/datasources/explore_datasource.dart';

// ════════════════════════════════════════════════════════════
//  EVENTS
// ════════════════════════════════════════════════════════════
abstract class ExploreEvent extends Equatable {
  const ExploreEvent();
  @override List<Object?> get props => [];
}

class LoadExploreDataEvent extends ExploreEvent {
  const LoadExploreDataEvent();
}

class ApplyFilterEvent extends ExploreEvent {
  final ExploreFilter filter;
  const ApplyFilterEvent(this.filter);
  @override List<Object?> get props => [filter];
}

class ResetFilterEvent extends ExploreEvent {
  const ResetFilterEvent();
}

class SearchExploreEvent extends ExploreEvent {
  final String query;
  const SearchExploreEvent(this.query);
  @override List<Object?> get props => [query];
}

class ToggleSaveItemEvent extends ExploreEvent {
  final String itemId;
  const ToggleSaveItemEvent(this.itemId);
  @override List<Object?> get props => [itemId];
}

// ════════════════════════════════════════════════════════════
//  STATES
// ════════════════════════════════════════════════════════════
abstract class ExploreState extends Equatable {
  const ExploreState();
  @override List<Object?> get props => [];
}

class ExploreInitial extends ExploreState {}

class ExploreLoading extends ExploreState {}

class ExploreLoaded extends ExploreState {
  final List<TravelPackage> packages;
  final List<Hotel> hotels;
  final ExploreFilter activeFilter;
  final Set<String> savedIds;
  final String searchQuery;
  final bool isFiltered;

  const ExploreLoaded({
    required this.packages,
    required this.hotels,
    required this.activeFilter,
    this.savedIds = const {},
    this.searchQuery = '',
    this.isFiltered = false,
  });

  // All items for display when service type is 'all'
  List<TravelPackage> get visiblePackages {
    if (activeFilter.serviceType == ServiceType.hotel) return [];
    return packages;
  }

  List<Hotel> get visibleHotels {
    if (activeFilter.serviceType == ServiceType.travelAgency) return [];
    return hotels;
  }

  bool get isEmpty => visiblePackages.isEmpty && visibleHotels.isEmpty;

  ExploreLoaded copyWith({
    List<TravelPackage>? packages,
    List<Hotel>? hotels,
    ExploreFilter? activeFilter,
    Set<String>? savedIds,
    String? searchQuery,
    bool? isFiltered,
  }) {
    return ExploreLoaded(
      packages: packages ?? this.packages,
      hotels: hotels ?? this.hotels,
      activeFilter: activeFilter ?? this.activeFilter,
      savedIds: savedIds ?? this.savedIds,
      searchQuery: searchQuery ?? this.searchQuery,
      isFiltered: isFiltered ?? this.isFiltered,
    );
  }

  @override
  List<Object?> get props =>
      [packages, hotels, activeFilter, savedIds, searchQuery, isFiltered];
}

class ExploreError extends ExploreState {
  final String message;
  const ExploreError(this.message);
  @override List<Object?> get props => [message];
}

// ════════════════════════════════════════════════════════════
//  BLOC
// ════════════════════════════════════════════════════════════
class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  ExploreBloc() : super(ExploreInitial()) {
    on<LoadExploreDataEvent>(_onLoad);
    on<ApplyFilterEvent>(_onApplyFilter);
    on<ResetFilterEvent>(_onReset);
    on<SearchExploreEvent>(_onSearch);
    on<ToggleSaveItemEvent>(_onToggleSave);
  }

  Future<void> _onLoad(
    LoadExploreDataEvent event,
    Emitter<ExploreState> emit,
  ) async {
    emit(ExploreLoading());
    await Future.delayed(const Duration(milliseconds: 800)); // simulate network
    emit(ExploreLoaded(
      packages: ExploreDataSource.packages,
      hotels: ExploreDataSource.hotels,
      activeFilter: const ExploreFilter(),
    ));
  }

  Future<void> _onApplyFilter(
    ApplyFilterEvent event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    final current = state as ExploreLoaded;

    emit(ExploreLoading());
    await Future.delayed(const Duration(milliseconds: 400));

    final filteredPackages = ExploreDataSource.filterPackages(event.filter);
    final filteredHotels = ExploreDataSource.filterHotels(event.filter);

    emit(current.copyWith(
      packages: filteredPackages,
      hotels: filteredHotels,
      activeFilter: event.filter,
      isFiltered: event.filter.isActive,
    ));
  }

  Future<void> _onReset(
    ResetFilterEvent event,
    Emitter<ExploreState> emit,
  ) async {
    emit(ExploreLoading());
    await Future.delayed(const Duration(milliseconds: 300));
    emit(ExploreLoaded(
      packages: ExploreDataSource.packages,
      hotels: ExploreDataSource.hotels,
      activeFilter: const ExploreFilter(),
    ));
  }

  Future<void> _onSearch(
    SearchExploreEvent event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    final current = state as ExploreLoaded;

    if (event.query.isEmpty) {
      emit(current.copyWith(
        packages: ExploreDataSource.filterPackages(current.activeFilter),
        hotels: ExploreDataSource.filterHotels(current.activeFilter),
        searchQuery: '',
      ));
      return;
    }

    final q = event.query.toLowerCase();
    final pkgs = ExploreDataSource.packages.where((p) =>
        p.title.toLowerCase().contains(q) ||
        p.titleAr.contains(event.query) ||
        p.destinationCity.toLowerCase().contains(q) ||
        p.destinationCityAr.contains(event.query) ||
        p.agencyName.toLowerCase().contains(q) ||
        p.agencyNameAr.contains(event.query)).toList();

    final htls = ExploreDataSource.hotels.where((h) =>
        h.name.toLowerCase().contains(q) ||
        h.nameAr.contains(event.query) ||
        h.city.toLowerCase().contains(q) ||
        h.cityAr.contains(event.query)).toList();

    emit(current.copyWith(
      packages: pkgs,
      hotels: htls,
      searchQuery: event.query,
    ));
  }

  void _onToggleSave(
    ToggleSaveItemEvent event,
    Emitter<ExploreState> emit,
  ) {
    if (state is! ExploreLoaded) return;
    final current = state as ExploreLoaded;
    final saved = Set<String>.from(current.savedIds);
    if (saved.contains(event.itemId)) {
      saved.remove(event.itemId);
    } else {
      saved.add(event.itemId);
    }
    emit(current.copyWith(savedIds: saved));
  }
}
