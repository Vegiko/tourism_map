part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class WatchAuthStateStarted extends AuthEvent {
  const WatchAuthStateStarted();
}

class AuthUserChanged extends AuthEvent {
  final AppUser? user;
  const AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user];
}

class SignInWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  const SignInWithEmailRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class RegisterWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;
  final UserRole role;
  final PartnerInfo? partnerInfo;

  const RegisterWithEmailRequested({
    required this.email,
    required this.password,
    required this.displayName,
    required this.role,
    this.partnerInfo,
  });

  @override
  List<Object?> get props => [email, displayName, role];
}

class SignInWithGoogleRequested extends AuthEvent {
  const SignInWithGoogleRequested();
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

class SendPasswordResetRequested extends AuthEvent {
  final String email;
  const SendPasswordResetRequested({required this.email});
  @override
  List<Object?> get props => [email];
}

class ClearAuthErrorEvent extends AuthEvent {
  const ClearAuthErrorEvent();
}
