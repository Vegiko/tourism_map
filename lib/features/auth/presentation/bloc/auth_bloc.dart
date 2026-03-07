import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/auth_usecases.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithEmail signInWithEmail;
  final RegisterWithEmail registerWithEmail;
  final SignInWithGoogle signInWithGoogle;
  final SignOut signOut;
  final SendPasswordReset sendPasswordReset;
  final GetUserProfile getUserProfile;
  final WatchAuthState watchAuthState;

  StreamSubscription<AppUser?>? _authSubscription;

  AuthBloc({
    required this.signInWithEmail,
    required this.registerWithEmail,
    required this.signInWithGoogle,
    required this.signOut,
    required this.sendPasswordReset,
    required this.getUserProfile,
    required this.watchAuthState,
  }) : super(const AuthInitial()) {
    on<WatchAuthStateStarted>(_onWatchAuthState);
    on<SignInWithEmailRequested>(_onSignIn);
    on<RegisterWithEmailRequested>(_onRegister);
    on<SignInWithGoogleRequested>(_onGoogleSignIn);
    on<SignOutRequested>(_onSignOut);
    on<SendPasswordResetRequested>(_onPasswordReset);
    on<AuthUserChanged>(_onUserChanged);
    on<ClearAuthErrorEvent>(_onClearError);

    // Start watching auth state immediately
    add(const WatchAuthStateStarted());
  }

  // ──────────────────────────────────────────────
  //  Watch Auth State
  // ──────────────────────────────────────────────
  Future<void> _onWatchAuthState(
    WatchAuthStateStarted event,
    Emitter<AuthState> emit,
  ) async {
    await _authSubscription?.cancel();
    _authSubscription = watchAuthState().listen(
      (user) => add(AuthUserChanged(user)),
    );
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(Authenticated(event.user!));
    } else {
      emit(const Unauthenticated());
    }
  }

  // ──────────────────────────────────────────────
  //  Sign In
  // ──────────────────────────────────────────────
  Future<void> _onSignIn(
    SignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'جاري تسجيل الدخول...'));

    final result = await signInWithEmail(
      SignInWithEmailParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  // ──────────────────────────────────────────────
  //  Register
  // ──────────────────────────────────────────────
  Future<void> _onRegister(
    RegisterWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'جاري إنشاء الحساب...'));

    final result = await registerWithEmail(
      RegisterWithEmailParams(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
        role: event.role,
        partnerInfo: event.partnerInfo,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(
        RegistrationSuccess(
          user: user,
          message: 'تم إنشاء حسابك بنجاح! تحقق من بريدك لتفعيل الحساب',
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Google Sign In
  // ──────────────────────────────────────────────
  Future<void> _onGoogleSignIn(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'جاري تسجيل الدخول بـ Google...'));

    final result = await signInWithGoogle();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  // ──────────────────────────────────────────────
  //  Sign Out
  // ──────────────────────────────────────────────
  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'جاري تسجيل الخروج...'));

    final result = await signOut();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const Unauthenticated()),
    );
  }

  // ──────────────────────────────────────────────
  //  Password Reset
  // ──────────────────────────────────────────────
  Future<void> _onPasswordReset(
    SendPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'جاري الإرسال...'));

    final result = await sendPasswordReset(
      SendPasswordResetParams(email: event.email),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(PasswordResetEmailSent(event.email)),
    );
  }

  void _onClearError(ClearAuthErrorEvent _, Emitter<AuthState> emit) {
    emit(const Unauthenticated());
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
