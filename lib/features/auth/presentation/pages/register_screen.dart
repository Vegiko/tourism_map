import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/app_user.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  final UserRole initialRole;
  final VoidCallback onNavigateToLogin;
  final VoidCallback onBack;

  const RegisterScreen({
    super.key,
    required this.initialRole,
    required this.onNavigateToLogin,
    required this.onBack,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Common fields
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // Partner fields
  final _businessNameCtrl = TextEditingController();
  final _businessNameArCtrl = TextEditingController();
  final _businessPhoneCtrl = TextEditingController();
  PartnerType _selectedPartnerType = PartnerType.hotel;

  late UserRole _role;
  int _currentStep = 0; // 0: basic info, 1: partner info (if partner)

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _businessNameCtrl.dispose();
    _businessNameArCtrl.dispose();
    _businessPhoneCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _proceedOrSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // If partner and on step 0, go to step 1
    if (_role == UserRole.partner && _currentStep == 0) {
      setState(() => _currentStep = 1);
      _slideCtrl
        ..reset()
        ..forward();
      return;
    }

    // Submit
    final partnerInfo = _role == UserRole.partner
        ? PartnerInfo(
            businessName: _businessNameCtrl.text,
            businessNameAr: _businessNameArCtrl.text,
            partnerType: _selectedPartnerType,
            businessPhone: _businessPhoneCtrl.text.isNotEmpty
                ? _businessPhoneCtrl.text
                : null,
          )
        : null;

    context.read<AuthBloc>().add(
          RegisterWithEmailRequested(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            displayName: _nameCtrl.text.trim(),
            role: _role,
            partnerInfo: partnerInfo,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
             if (state is Authenticated) {
          Navigator.of(context).pushReplacementNamed('/home'); 
        }

        if (state is RegistrationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
          // الانتقال لصفحة تسجيل الدخول بعد ظهور الرسالة
          Future.delayed(const Duration(seconds: 2), () {
            widget.onNavigateToLogin();
          });
        }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                child: FadeTransition(
                  opacity: _slideCtrl,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),

                          // Header
                          AuthHeader(
                            title: _role == UserRole.traveler
                                ? 'حساب مسافر جديد'
                                : _currentStep == 0
                                    ? 'حساب شريك أعمال'
                                    : 'بيانات أعمالك',
                            subtitle: _role == UserRole.traveler
                                ? 'أنشئ حسابك وابدأ رحلتك'
                                : _currentStep == 0
                                    ? 'معلوماتك الشخصية'
                                    : 'أخبرنا عن نشاطك التجاري',
                            onBack: _currentStep > 0
                                ? () => setState(() => _currentStep = 0)
                                : widget.onBack,
                            icon: _role == UserRole.traveler
                                ? Icons.person_add_rounded
                                : Icons.business_center_rounded,
                            iconGradient: _role == UserRole.partner
                                ? AppColors.sunsetGradient
                                : null,
                          ),
                          const SizedBox(height: 24),

                          // Step indicator for partner
                          if (_role == UserRole.partner)
                            _buildStepIndicator(),

                          const SizedBox(height: 24),

                          // Form fields based on step
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _currentStep == 0
                                ? _buildBasicInfoFields()
                                : _buildPartnerInfoFields(),
                          ),

                          const SizedBox(height: 28),

                          // Submit button
                          AuthPrimaryButton(
                            label: _role == UserRole.partner &&
                                    _currentStep == 0
                                ? 'التالي'
                                : 'إنشاء الحساب',
                            isLoading: isLoading,
                            onPressed: isLoading ? null : _proceedOrSubmit,
                            gradient: _role == UserRole.partner
                                ? AppColors.sunsetGradient
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // Terms
                          _buildTermsText(),
                          const SizedBox(height: 20),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'لديك حساب بالفعل؟ ',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: widget.onNavigateToLogin,
                                child: const Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Step Indicator
  // ──────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(2, (index) {
        final isActive = index == _currentStep;
        final isPast = index < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: isActive || isPast
                        ? AppColors.sunsetGradient
                        : null,
                    color: isActive || isPast
                        ? null
                        : AppColors.textHint.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < 1) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  // ──────────────────────────────────────────────
  //  Basic Info Fields
  // ──────────────────────────────────────────────
  Widget _buildBasicInfoFields() {
    return Column(
      key: const ValueKey('basic'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthTextField(
          label: 'الاسم الكامل',
          hint: 'محمد أحمد',
          prefixIcon: Icons.person_outline_rounded,
          controller: _nameCtrl,
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'أدخل اسمك الكامل';
            if (v.trim().length < 2) return 'الاسم قصير جداً';
            return null;
          },
        ),
        const SizedBox(height: 18),
        AuthTextField(
          label: 'البريد الإلكتروني',
          hint: 'example@email.com',
          prefixIcon: Icons.email_outlined,
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.isEmpty) return 'أدخل بريدك الإلكتروني';
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
              return 'بريد إلكتروني غير صحيح';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        AuthTextField(
          label: 'كلمة المرور',
          hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          controller: _passwordCtrl,
          isPassword: true,
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
            if (v.length < 6) return 'كلمة المرور قصيرة (6 أحرف على الأقل)';
            return null;
          },
        ),
        const SizedBox(height: 18),
        AuthTextField(
          label: 'تأكيد كلمة المرور',
          hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          controller: _confirmPasswordCtrl,
          isPassword: true,
          textInputAction: _role == UserRole.traveler
              ? TextInputAction.done
              : TextInputAction.next,
          validator: (v) {
            if (v == null || v.isEmpty) return 'أكد كلمة المرور';
            if (v != _passwordCtrl.text) return 'كلمتا المرور غير متطابقتين';
            return null;
          },
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  Partner Info Fields
  // ──────────────────────────────────────────────
  Widget _buildPartnerInfoFields() {
    return Column(
      key: const ValueKey('partner'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Partner Type Selector
        const Text(
          'نوع النشاط التجاري',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _buildPartnerTypeSelector(),
        const SizedBox(height: 18),

        AuthTextField(
          label: 'اسم المنشأة (عربي)',
          hint: 'فندق النجوم',
          prefixIcon: Icons.business_rounded,
          controller: _businessNameArCtrl,
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'أدخل اسم المنشأة بالعربي';
            return null;
          },
        ),
        const SizedBox(height: 18),

        AuthTextField(
          label: 'اسم المنشأة (إنجليزي)',
          hint: 'Al Nujoom Hotel',
          prefixIcon: Icons.business_rounded,
          controller: _businessNameCtrl,
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter business name';
            return null;
          },
        ),
        const SizedBox(height: 18),

        AuthTextField(
          label: 'رقم الهاتف (اختياري)',
          hint: '+966 5x xxx xxxx',
          prefixIcon: Icons.phone_outlined,
          controller: _businessPhoneCtrl,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
        ),

        const SizedBox(height: 16),

        // Partner benefits info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withOpacity(0.08),
                AppColors.secondary.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.15),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'مميزات حساب الشريك',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...[
                'لوحة تحكم متكاملة لإدارة الحجوزات',
                'تحليلات وإحصائيات مفصلة',
                'الوصول لآلاف المسافرين',
              ].map((f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          f,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerTypeSelector() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: PartnerType.values.map((type) {
          final isSelected = _selectedPartnerType == type;
          return GestureDetector(
            onTap: () => setState(() => _selectedPartnerType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 10),
              width: 82,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withOpacity(0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _partnerTypeEmoji(type),
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type.nameAr,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _partnerTypeEmoji(PartnerType type) {
    switch (type) {
      case PartnerType.hotel:
        return '🏨';
      case PartnerType.travelAgency:
        return '✈️';
      case PartnerType.tourGuide:
        return '🧭';
      case PartnerType.restaurant:
        return '🍽️';
    }
  }

  Widget _buildTermsText() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(
            fontFamily: 'Cairo',
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
          children: [
            TextSpan(text: 'بالتسجيل توافق على '),
            TextSpan(
              text: 'شروط الاستخدام',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
            TextSpan(text: ' و '),
            TextSpan(
              text: 'سياسة الخصوصية',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
