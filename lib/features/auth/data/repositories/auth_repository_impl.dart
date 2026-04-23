import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  AppUser? _cachedUser;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  AppUser? get currentUser => _cachedUser;

  // ──────────────────────────────────────────────
  //  Auth State Stream
  // ──────────────────────────────────────────────
  @override
  Stream<AppUser?> get authStateChanges {
    return remoteDataSource.firebaseAuthStateChanges.asyncMap((fbUser) async {
      if (fbUser == null) {
        _cachedUser = null;
        return null;
      }
      try {
        final result = await remoteDataSource.getUserProfile(fbUser.uid);
        _cachedUser = result;
        return result;
      } catch (_) {
        return null;
      }
    });
  }

  // ──────────────────────────────────────────────
  //  Sign In
  // ──────────────────────────────────────────────
  @override
  Future<Either<AuthFailure, AppUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.signInWithEmailAndPassword(
        email,
        password,
      );
      _cachedUser = user;
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure.fromFirebaseCode(e.code));
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────────
  //  Register
  // ──────────────────────────────────────────────
  @override
  Future<Either<AuthFailure, AppUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    PartnerInfo? partnerInfo,
  }) async {
    try {
      final user = await remoteDataSource.createUserWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
        partnerInfo: partnerInfo,
      );
      _cachedUser = user;
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure.fromFirebaseCode(e.code));
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────────
  //  Google Sign In (stub - requires google_sign_in package)
  // ──────────────────────────────────────────────
  @override
  Future<Either<AuthFailure, AppUser>> signInWithGoogle() async {
    // TODO: Add google_sign_in package and implement
    return const Left(
      AuthFailure(message: 'تسجيل الدخول بـ Google قيد التطوير'),
    );
  }

  // ──────────────────────────────────────────────
  //  Sign Out
  // ──────────────────────────────────────────────
  @override
  Future<Either<AuthFailure, Unit>> signOut() async {
    try {
      await remoteDataSource.signOut();
      _cachedUser = null;
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────────
  //  Email Verification
  // ──────────────────────────────────────────────
  @override
  Future<Either<AuthFailure, Unit>> sendEmailVerification() async {
    try {
      await remoteDataSource.sendEmailVerification();
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure.fromFirebaseCode(e.code));
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────────
  //  Password Reset
  // ──────────────────────────────────────────────
  @override
  Future<Either<AuthFailure, Unit>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email);
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure.fromFirebaseCode(e.code));
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────────
  //  Get User Profile
  // ──────────────────────────────────────────────
  @override
  Future<Either<AuthFailure, AppUser>> getUserProfile(String uid) async {
    try {
      final user = await remoteDataSource.getUserProfile(uid);
      _cachedUser = user;
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure.fromFirebaseCode(e.code));
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────────
  //  Update Profile
  // ──────────────────────────────────────────────
  @override
  Future<Either<AuthFailure, AppUser>> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
    PartnerInfo? partnerInfo,
  }) async {
    try {
      final user = await remoteDataSource.updateUserProfile(
        uid: uid,
        displayName: displayName,
        photoUrl: photoUrl,
        partnerInfo: partnerInfo,
      );
      _cachedUser = user;
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure.fromFirebaseCode(e.code));
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────────
  //  Delete Account
  // ──────────────────────────────────────────────
  @override
  Future<Either<AuthFailure, Unit>> deleteAccount() async {
    try {
      await remoteDataSource.deleteAccount();
      _cachedUser = null;
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure.fromFirebaseCode(e.code));
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }
    @override
  Future<Either<AuthFailure, AppUser>> signInAnonymously() async {
    try {
      final userCredential = await _firebaseAuth.signInAnonymously();
      final user = userCredential.user!;

      return Right(AppUser(
        uid: user.uid,
        email: '',
        displayName: 'Guest',
        role: UserRole.user,
      ));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
