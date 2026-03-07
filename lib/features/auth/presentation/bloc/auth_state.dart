part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});
  @override
  List<Object?> get props => [message];
}

class Authenticated extends AuthState {
  final AppUser user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class RegistrationSuccess extends AuthState {
  final AppUser user;
  final String message;
  const RegistrationSuccess({required this.user, required this.message});
  @override
  List<Object?> get props => [user, message];
}

class PasswordResetEmailSent extends AuthState {
  final String email;
  const PasswordResetEmailSent(this.email);
  @override
  List<Object?> get props => [email];
}
