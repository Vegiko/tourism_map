import 'package:dartz/dartz.dart';
import '../entities/destination.dart';
import '../repositories/home_repository.dart';

// ──────────────────────────────────────────────
//  Base UseCase
// ──────────────────────────────────────────────
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {}

// ──────────────────────────────────────────────
//  Get Featured Destinations
// ──────────────────────────────────────────────
class GetFeaturedDestinations extends UseCase<List<Destination>, NoParams> {
  final HomeRepository repository;
  GetFeaturedDestinations(this.repository);

  @override
  Future<Either<Failure, List<Destination>>> call(NoParams params) {
    return repository.getFeaturedDestinations();
  }
}

// ──────────────────────────────────────────────
//  Get Popular Destinations
// ──────────────────────────────────────────────
class GetPopularDestinations extends UseCase<List<Destination>, NoParams> {
  final HomeRepository repository;
  GetPopularDestinations(this.repository);

  @override
  Future<Either<Failure, List<Destination>>> call(NoParams params) {
    return repository.getPopularDestinations();
  }
}

// ──────────────────────────────────────────────
//  Get Trending Destinations
// ──────────────────────────────────────────────
class GetTrendingDestinations extends UseCase<List<Destination>, NoParams> {
  final HomeRepository repository;
  GetTrendingDestinations(this.repository);

  @override
  Future<Either<Failure, List<Destination>>> call(NoParams params) {
    return repository.getTrendingDestinations();
  }
}

// ──────────────────────────────────────────────
//  Search Destinations
// ──────────────────────────────────────────────
class SearchDestinationsParams {
  final String query;
  const SearchDestinationsParams({required this.query});
}

class SearchDestinations
    extends UseCase<List<Destination>, SearchDestinationsParams> {
  final HomeRepository repository;
  SearchDestinations(this.repository);

  @override
  Future<Either<Failure, List<Destination>>> call(
    SearchDestinationsParams params,
  ) {
    return repository.searchDestinations(params.query);
  }
}

// ──────────────────────────────────────────────
//  Get Categories
// ──────────────────────────────────────────────
class GetCategories extends UseCase<List<Category>, NoParams> {
  final HomeRepository repository;
  GetCategories(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(NoParams params) {
    return repository.getCategories();
  }
}
