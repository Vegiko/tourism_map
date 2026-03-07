import 'package:dartz/dartz.dart';
import '../../domain/entities/destination.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeLocalDataSource localDataSource;

  HomeRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Destination>>> getFeaturedDestinations() async {
    try {
      final destinations = await localDataSource.getFeaturedDestinations();
      return Right(destinations);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Destination>>> getPopularDestinations() async {
    try {
      final destinations = await localDataSource.getPopularDestinations();
      return Right(destinations);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Destination>>> getTrendingDestinations() async {
    try {
      final destinations = await localDataSource.getTrendingDestinations();
      return Right(destinations);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Destination>>> searchDestinations(
    String query,
  ) async {
    try {
      final all = await localDataSource.getFeaturedDestinations();
      final filtered = all
          .where(
            (d) =>
                d.name.toLowerCase().contains(query.toLowerCase()) ||
                d.nameAr.contains(query) ||
                d.country.toLowerCase().contains(query.toLowerCase()) ||
                d.countryAr.contains(query),
          )
          .toList();
      return Right(filtered);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Destination>>> getDestinationsByCategory(
    DestinationCategory category,
  ) async {
    try {
      final all = await localDataSource.getFeaturedDestinations();
      final filtered =
          all.where((d) => d.category == category).toList();
      return Right(filtered);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final categories = await localDataSource.getCategories();
      return Right(categories);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
