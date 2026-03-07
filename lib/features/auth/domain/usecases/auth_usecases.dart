import 'package:dartz/dartz.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

// ──────────────────────────────────────────────
//  Sign In With Email
// ──────────────────────────────────────────────
class SignInWithEmailParams {
  final String email;
  final String password;
  const SignInWithEmailParams({required this.email, required this.password});
}

class SignInWithEmail {
  final AuthRepository repository;
  SignInWithEmail(this.repository);

  Future<Either<AuthFailure, AppUser>> call(SignInWithEmailParams params) {
    return repository.signInWithEmailAndPassword(
      email: params.email,
      password: params.password,
    );
  }
}

// ──────────────────────────────────────────────
//  Register With Email
// ──────────────────────────────────────────────
class RegisterWithEmailParams {
  final String email;
  final String password;
  final String displayName;
  final UserRole role;
  final PartnerInfo? partnerInfo;

  const RegisterWithEmailParams({
    required this.email,
    required this.password,
    required this.displayName,
    required this.role,
    this.partnerInfo,
  });
}

class RegisterWithEmail {
  final AuthRepository repository;
  RegisterWithEmail(this.repository);

  Future<Either<AuthFailure, AppUser>> call(RegisterWithEmailParams params) {
    return repository.createUserWithEmailAndPassword(
      email: params.email,
      password: params.password,
      displayName: params.displayName,
      role: params.role,
      partnerInfo: params.partnerInfo,
    );
  }
}

// ──────────────────────────────────────────────
//  Sign In With Google
// ──────────────────────────────────────────────
class SignInWithGoogle {
  final AuthRepository repository;
  SignInWithGoogle(this.repository);

  Future<Either<AuthFailure, AppUser>> call() {
    return repository.signInWithGoogle();
  }
}

// ──────────────────────────────────────────────
//  Sign Out
// ──────────────────────────────────────────────
class SignOut {
  final AuthRepository repository;
  SignOut(this.repository);

  Future<Either<AuthFailure, Unit>> call() {
    return repository.signOut();
  }
}

// ──────────────────────────────────────────────
//  Send Password Reset
// ──────────────────────────────────────────────
class SendPasswordResetParams {
  final String email;
  const SendPasswordResetParams({required this.email});
}

class SendPasswordReset {
  final AuthRepository repository;
  SendPasswordReset(this.repository);

  Future<Either<AuthFailure, Unit>> call(SendPasswordResetParams params) {
    return repository.sendPasswordResetEmail(email: params.email);
  }
}

// ──────────────────────────────────────────────
//  Get User Profile
// ──────────────────────────────────────────────
class GetUserProfile {
  final AuthRepository repository;
  GetUserProfile(this.repository);

  Future<Either<AuthFailure, AppUser>> call(String uid) {
    return repository.getUserProfile(uid);
  }
}

// ──────────────────────────────────────────────
//  Watch Auth State
// ──────────────────────────────────────────────
class WatchAuthState {
  final AuthRepository repository;
  WatchAuthState(this.repository);

  Stream<AppUser?> call() => repository.authStateChanges;
}
