import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/home/data/datasources/home_local_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/home_usecases.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Firebase
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Auth - Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl(), firestore: sl()),
  );
  // Auth - Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  // Auth - Use Cases
  sl.registerLazySingleton(() => SignInWithEmail(sl()));
  sl.registerLazySingleton(() => RegisterWithEmail(sl()));
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => SendPasswordReset(sl()));
  sl.registerLazySingleton(() => GetUserProfile(sl()));
  sl.registerLazySingleton(() => WatchAuthState(sl()));
  // Auth - BLoC (singleton)
  sl.registerLazySingleton(() => AuthBloc(
        signInWithEmail: sl(), registerWithEmail: sl(),
        signInWithGoogle: sl(), signOut: sl(),
        sendPasswordReset: sl(), getUserProfile: sl(),
        watchAuthState: sl(),
      ));

  // Home - Data Source
  sl.registerLazySingleton<HomeLocalDataSource>(() => HomeLocalDataSourceImpl());
  // Home - Repository
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(localDataSource: sl()),
  );
  // Home - Use Cases
  sl.registerLazySingleton(() => GetFeaturedDestinations(sl()));
  sl.registerLazySingleton(() => GetPopularDestinations(sl()));
  sl.registerLazySingleton(() => GetTrendingDestinations(sl()));
  sl.registerLazySingleton(() => GetCategories(sl()));
  sl.registerLazySingleton(() => SearchDestinations(sl()));
  // Home - BLoC (factory)
  sl.registerFactory(() => HomeBloc(
        getFeaturedDestinations: sl(), getPopularDestinations: sl(),
        getTrendingDestinations: sl(), getCategories: sl(),
        searchDestinations: sl(),
      ));
}
