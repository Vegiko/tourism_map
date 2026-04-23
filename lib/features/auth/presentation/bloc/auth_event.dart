part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

// 1. مراقبة حالة المصادقة عند تشغيل التطبيق
class WatchAuthStateStarted extends AuthEvent {
  const WatchAuthStateStarted();
}
// 2. تحديث بيانات المستخدم عند تغيير حالته في Firebase
class AuthUserChanged extends AuthEvent {
  final AppUser? user;
  const AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user];
}
// 3. تسجيل الدخول بالبريد وكلمة المرور
class SignInWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  const SignInWithEmailRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}
// 4. إنشاء حساب جديد مع تفاصيل الدور والشريك
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
// 5. تسجيل الدخول عبر Google
class SignInWithGoogleRequested extends AuthEvent {
  const SignInWithGoogleRequested();
}
// 6. تسجيل الدخول كضيف (وضع الضيف - التعديل المطلوب)
class GuestSignInRequested extends AuthEvent {
  const GuestSignInRequested();
}
// 7. تسجيل الخروج
class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}
// 8. طلب إعادة تعيين كلمة المرور
class SendPasswordResetRequested extends AuthEvent {
  final String email;
  const SendPasswordResetRequested({required this.email});
  @override
  List<Object?> get props => [email];
}
// 9. مسح أخطاء المصادقة من الواجهة
class ClearAuthErrorEvent extends AuthEvent {
  const ClearAuthErrorEvent();
}
