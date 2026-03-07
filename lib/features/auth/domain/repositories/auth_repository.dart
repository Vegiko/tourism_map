import 'package:dartz/dartz.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  // ── Stream of auth state changes ──────────────
  Stream<AppUser?> get authStateChanges;

  // ── Current user (sync) ────────────────────────
  AppUser? get currentUser;

  // ── Sign In ────────────────────────────────────
  Future<Either<AuthFailure, AppUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  // ── Sign Up ────────────────────────────────────
  Future<Either<AuthFailure, AppUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    PartnerInfo? partnerInfo,
  });

  // ── Google Sign In ─────────────────────────────
  Future<Either<AuthFailure, AppUser>> signInWithGoogle();

  // ── Sign Out ───────────────────────────────────
  Future<Either<AuthFailure, Unit>> signOut();

  // ── Send Email Verification ────────────────────
  Future<Either<AuthFailure, Unit>> sendEmailVerification();

  // ── Send Password Reset ────────────────────────
  Future<Either<AuthFailure, Unit>> sendPasswordResetEmail({
    required String email,
  });

  // ── Fetch user profile from Firestore ──────────
  Future<Either<AuthFailure, AppUser>> getUserProfile(String uid);

  // ── Update user profile ────────────────────────
  Future<Either<AuthFailure, AppUser>> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
    PartnerInfo? partnerInfo,
  });

  // ── Delete account ─────────────────────────────
  Future<Either<AuthFailure, Unit>> deleteAccount();
}
