import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ForgotPasswordScreen({super.key, required this.onBack});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is PasswordResetEmailSent) {
              _showSuccessDialog(state.email);
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            if (state is PasswordResetEmailSent) {
              return _buildSuccessView(state.email);
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      AuthHeader(
                        title: 'استعادة كلمة المرور',
                        subtitle:
                            'أدخل بريدك الإلكتروني وسنرسل لك رابط\nإعادة تعيين كلمة المرور',
                        onBack: widget.onBack,
                        icon: Icons.lock_reset_rounded,
                      ),
                      const SizedBox(height: 36),
                      AuthTextField(
                        label: 'البريد الإلكتروني',
                        hint: 'example@email.com',
                        prefixIcon: Icons.email_outlined,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'أدخل بريدك الإلكتروني';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                            return 'بريد إلكتروني غير صحيح';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      if (state is AuthError)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: AuthErrorBanner(message: state.message),
                        ),
                      AuthPrimaryButton(
                        label: 'إرسال رابط الاستعادة',
                        isLoading: isLoading,
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  context.read<AuthBloc>().add(
                                        SendPasswordResetRequested(
                                          email: _emailCtrl.text.trim(),
                                        ),
                                      );
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSuccessView(String email) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                size: 52,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'تم الإرسال بنجاح!',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'تم إرسال رابط استعادة كلمة المرور إلى:\n$email',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            AuthPrimaryButton(
              label: 'العودة لتسجيل الدخول',
              onPressed: widget.onBack,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String email) {
    // State will rebuild to show success view
  }
}
