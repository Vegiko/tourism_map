import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/destination.dart';
import '../../domain/usecases/home_usecases.dart';

// ──────────────────────────────────────────────
//  Events
// ──────────────────────────────────────────────
abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class LoadHomeDataEvent extends HomeEvent {
  const LoadHomeDataEvent();
}

class SearchDestinationsEvent extends HomeEvent {
  final String query;
  const SearchDestinationsEvent(this.query);
  @override
  List<Object?> get props => [query];
}

class FilterByCategoryEvent extends HomeEvent {
  final DestinationCategory? category;
  const FilterByCategoryEvent(this.category);
  @override
  List<Object?> get props => [category];
}

class ToggleSaveDestinationEvent extends HomeEvent {
  final String destinationId;
  const ToggleSaveDestinationEvent(this.destinationId);
  @override
  List<Object?> get props => [destinationId];
}

// ──────────────────────────────────────────────
//  States
// ──────────────────────────────────────────────
abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Destination> featuredDestinations;
  final List<Destination> popularDestinations;
  final List<Destination> trendingDestinations;
  final List<Category> categories;
  final DestinationCategory? selectedCategory;
  final Set<String> savedDestinationIds;
  final String searchQuery;

  const HomeLoaded({
    required this.featuredDestinations,
    required this.popularDestinations,
    required this.trendingDestinations,
    required this.categories,
    this.selectedCategory,
    this.savedDestinationIds = const {},
    this.searchQuery = '',
  });

  HomeLoaded copyWith({
    List<Destination>? featuredDestinations,
    List<Destination>? popularDestinations,
    List<Destination>? trendingDestinations,
    List<Category>? categories,
    DestinationCategory? selectedCategory,
    bool clearCategory = false,
    Set<String>? savedDestinationIds,
    String? searchQuery,
  }) {
    return HomeLoaded(
      featuredDestinations:
          featuredDestinations ?? this.featuredDestinations,
      popularDestinations: popularDestinations ?? this.popularDestinations,
      trendingDestinations:
          trendingDestinations ?? this.trendingDestinations,
      categories: categories ?? this.categories,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      savedDestinationIds: savedDestinationIds ?? this.savedDestinationIds,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        featuredDestinations,
        popularDestinations,
        trendingDestinations,
        categories,
        selectedCategory,
        savedDestinationIds,
        searchQuery,
      ];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}

// ──────────────────────────────────────────────
//  BLoC
// ──────────────────────────────────────────────
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetFeaturedDestinations getFeaturedDestinations;
  final GetPopularDestinations getPopularDestinations;
  final GetTrendingDestinations getTrendingDestinations;
  final GetCategories getCategories;
  final SearchDestinations searchDestinations;

  HomeBloc({
    required this.getFeaturedDestinations,
    required this.getPopularDestinations,
    required this.getTrendingDestinations,
    required this.getCategories,
    required this.searchDestinations,
  }) : super(HomeInitial()) {
    on<LoadHomeDataEvent>(_onLoadHomeData);
    on<SearchDestinationsEvent>(_onSearch);
    on<FilterByCategoryEvent>(_onFilterByCategory);
    on<ToggleSaveDestinationEvent>(_onToggleSave);
  }

  Future<void> _onLoadHomeData(
    LoadHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());

    final featured = await getFeaturedDestinations(NoParams());
    final popular = await getPopularDestinations(NoParams());
    final trending = await getTrendingDestinations(NoParams());
    final cats = await getCategories(NoParams());

    if (featured.isRight() &&
        popular.isRight() &&
        trending.isRight() &&
        cats.isRight()) {
      emit(HomeLoaded(
        featuredDestinations: featured.getOrElse(() => []),
        popularDestinations: popular.getOrElse(() => []),
        trendingDestinations: trending.getOrElse(() => []),
        categories: cats.getOrElse(() => []),
      ));
    } else {
      emit(const HomeError('Failed to load home data'));
    }
  }

  Future<void> _onSearch(
    SearchDestinationsEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;
    final current = state as HomeLoaded;

    if (event.query.isEmpty) {
      final featured = await getFeaturedDestinations(NoParams());
      emit(current.copyWith(
        featuredDestinations: featured.getOrElse(() => []),
        searchQuery: '',
      ));
      return;
    }

    final result = await searchDestinations(
      SearchDestinationsParams(query: event.query),
    );

    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (destinations) => emit(current.copyWith(
        featuredDestinations: destinations,
        searchQuery: event.query,
      )),
    );
  }

  Future<void> _onFilterByCategory(
    FilterByCategoryEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;
    final current = state as HomeLoaded;

    if (event.category == null || event.category == current.selectedCategory) {
      final featured = await getFeaturedDestinations(NoParams());
      emit(current.copyWith(
        featuredDestinations: featured.getOrElse(() => []),
        clearCategory: true,
      ));
    } else {
      emit(current.copyWith(selectedCategory: event.category));
    }
  }

  void _onToggleSave(
    ToggleSaveDestinationEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is! HomeLoaded) return;
    final current = state as HomeLoaded;
    final saved = Set<String>.from(current.savedDestinationIds);

    if (saved.contains(event.destinationId)) {
      saved.remove(event.destinationId);
    } else {
      saved.add(event.destinationId);
    }

    emit(current.copyWith(savedDestinationIds: saved));
  }
}
