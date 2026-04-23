import 'package:dartz/dartz.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

// 1. تعريف القاعدة الأساسية لجميع حالات الاستخدام (Base Use Case)
abstract class UseCase<Type, Params> {
  Future<Either<AuthFailure, Type>> call(Params params);
}

// كلاس نستخدمه عندما لا يحتاج الـ Use Case لبرامترات
class NoParams {
  const NoParams();
}

// ──────────────────────────────────────────────
// 2. حالات الاستخدام (Use Cases)
// ──────────────────────────────────────────────

class SignInWithEmail implements UseCase<AppUser, SignInWithEmailParams> {
  final AuthRepository repository;
  SignInWithEmail(this.repository);

  @override
  Future<Either<AuthFailure, AppUser>> call(SignInWithEmailParams params) async {
    return await repository.signInWithEmailAndPassword(
      email: params.email,
      password: params.password,
    );
  }
}

class RegisterWithEmail implements UseCase<AppUser, RegisterWithEmailParams> {
  final AuthRepository repository;
  RegisterWithEmail(this.repository);

  @override
  Future<Either<AuthFailure, AppUser>> call(RegisterWithEmailParams params) async {
    return await repository.createUserWithEmailAndPassword(
      email: params.email,
      password: params.password,
      displayName: params.displayName,
      role: params.role,
      partnerInfo: params.partnerInfo,
    );
  }
}

class SignInWithGoogle implements UseCase<AppUser, NoParams> {
  final AuthRepository repository;
  SignInWithGoogle(this.repository);

  @override
  Future<Either<AuthFailure, AppUser>> call(NoParams params) async {
    return await repository.signInWithGoogle();
  }
}

class SignOut implements UseCase<Unit, NoParams> {
  final AuthRepository repository;
  SignOut(this.repository);

  @override
  Future<Either<AuthFailure, Unit>> call(NoParams params) async {
    return await repository.signOut();
  }
}
class SendPasswordReset implements UseCase<Unit, SendPasswordResetParams> {
  final AuthRepository repository;
  SendPasswordReset(this.repository);

  @override
  Future<Either<AuthFailure, Unit>> call(SendPasswordResetParams params) async {
    return await repository.sendPasswordResetEmail(email: params.email);
  }
}

class GetUserProfile implements UseCase<AppUser, String> {
  final AuthRepository repository;
  GetUserProfile(this.repository);

  @override
  Future<Either<AuthFailure, AppUser>> call(String uid) async {
    return await repository.getUserProfile(uid);
  }
}
// ──────────────────────────────────────────────
// 3. حالة خاصة للـ Streams (مراقبة حالة المستخدم)
// ──────────────────────────────────────────────
class WatchAuthState {
  final AuthRepository repository;
  WatchAuthState(this.repository);

  Stream<AppUser?> call() => repository.authStateChanges;
}

// ──────────────────────────────────────────────
// 4. كلاسات المعاملات (Parameters)
// ──────────────────────────────────────────────

class SignInWithEmailParams {
  final String email;
  final String password;
  const SignInWithEmailParams({required this.email, required this.password});
}

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
class SendPasswordResetParams {
  final String email;
  const SendPasswordResetParams({required this.email});
}
