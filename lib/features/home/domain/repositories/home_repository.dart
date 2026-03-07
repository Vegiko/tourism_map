import 'package:dartz/dartz.dart';
import '../entities/destination.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<Destination>>> getFeaturedDestinations();
  Future<Either<Failure, List<Destination>>> getPopularDestinations();
  Future<Either<Failure, List<Destination>>> getTrendingDestinations();
  Future<Either<Failure, List<Destination>>> searchDestinations(String query);
  Future<Either<Failure, List<Destination>>> getDestinationsByCategory(
    DestinationCategory category,
  );
  Future<Either<Failure, List<Category>>> getCategories();
}

class Failure {
  final String message;
  final int? code;
  const Failure({required this.message, this.code});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}
