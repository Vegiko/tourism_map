import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourism_app/features/map/domain/entities/map_marker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/map_marker.dart';
import '../bloc/payment_bloc.dart';

// ════════════════════════════════════════════════════════════
//  Entry Point
// ════════════════════════════════════════════════════════════
class PaymentScreen extends StatelessWidget {
  final String serviceId;
  final String serviceName;
  final String? serviceNameAr;
  final MarkerType? serviceType;
  final double amount;
  final int guests;
  final DateTime checkIn;
  final DateTime checkOut;
  final bool isArabic;

  const PaymentScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    this.serviceNameAr,
    this.serviceType,
    required this.amount,
    required this.guests,
    required this.checkIn,
    required this.checkOut,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaymentBloc()
        ..add(InitPaymentEvent(
          serviceId:   serviceId,
          serviceName: serviceName,
          amount:      amount,
          guests:      guests,
          checkIn:     checkIn,
          checkOut:    checkOut,
        )),
      child: _PaymentView(
        serviceName:   serviceName,
        serviceNameAr: serviceNameAr,
        serviceType:   serviceType,
        isArabic:      isArabic,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  View
// ════════════════════════════════════════════════════════════
class _PaymentView extends StatefulWidget {
  final String serviceName;
  final String? serviceNameAr;
  final MarkerType? serviceType;
  final bool isArabic;

  const _PaymentView({
    required this.serviceName,
    this.serviceNameAr,
    this.serviceType,
    required this.isArabic,
  });

  @override
  State<_PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<_PaymentView>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _cardPreviewCtrl;
  late AnimationController _formCtrl;
  late Animation<double> _headerFade;
  late Animation<double> _cardFlip;
  late Animation<Offset> _formSlide;

  final _numberCtrl  = TextEditingController();
  final _expiryCtrl  = TextEditingController();
  final _cvvCtrl     = TextEditingController();
  final _holderCtrl  = TextEditingController();

  final _numberFocus = FocusNode();
  final _expiryFocus = FocusNode();
  final _cvvFocus    = FocusNode();
  final _holderFocus = FocusNode();

  bool _showCvvSide = false;

  // Test cards to help the user
  static const _testCards = [
    ('4242 4242 4242 4242', '12/28', '123', 'Test User',    'Visa - Approved'),
    ('5555 5555 5555 4444', '06/27', '321', 'Test User',    'Mastercard - Approved'),
    ('4000 0000 0000 0000', '01/30', '000', 'Test Decline', 'Visa - Declined'),
  ];

  String _t(String ar, String en) => widget.isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _cardPreviewCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _formCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _cardFlip = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _cardPreviewCtrl, curve: Curves.easeInOut));
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _formCtrl, curve: Curves.easeOut));

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150),
        () { if (mounted) _cardPreviewCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 300),
        () { if (mounted) _formCtrl.forward(); });

    // Flip preview to back when CVV is focused
    _cvvFocus.addListener(() {
      if (_cvvFocus.hasFocus && !_showCvvSide) {
        setState(() => _showCvvSide = true);
        _cardPreviewCtrl.reverse();
        Future.delayed(const Duration(milliseconds: 300),
            () { if (mounted) _cardPreviewCtrl.forward(); });
      } else if (!_cvvFocus.hasFocus && _showCvvSide) {
        setState(() => _showCvvSide = false);
        _cardPreviewCtrl.reverse();
        Future.delayed(const Duration(milliseconds: 300),
            () { if (mounted) _cardPreviewCtrl.forward(); });
      }
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _cardPreviewCtrl.dispose();
    _formCtrl.dispose();
    _numberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _holderCtrl.dispose();
    _numberFocus.dispose();
    _expiryFocus.dispose();
    _cvvFocus.dispose();
    _holderFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (ctx, state) {
          if (state is PaymentSuccessState || state is PaymentFailedState) {
            // Dismiss keyboard
            FocusScope.of(context).unfocus();
          }
        },
        builder: (ctx, state) {
          if (state is PaymentProcessingState) {
            return _buildProcessingScreen(state);
          }
          if (state is PaymentSuccessState) {
            return _buildSuccessScreen(ctx, state);
          }
          if (state is PaymentFailedState) {
            return _buildFailedScreen(ctx, state);
          }
          if (state is PaymentFormState) {
            return _buildFormScreen(ctx, state);
          }
          return const SizedBox();
        },
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  FORM SCREEN
  // ════════════════════════════════════════════════
  Widget _buildFormScreen(BuildContext ctx, PaymentFormState state) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        // Top gradient bg
        Positioned(
          top: 0, left: 0, right: 0, height: 240,
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(children: [
            // App bar
            FadeTransition(
              opacity: _headerFade,
              child: _buildAppBar(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(children: [
                  // Booking summary
                  _buildOrderSummary(state),
                  const SizedBox(height: 20),
                  // Card preview
                  _buildCardPreview(state),
                  const SizedBox(height: 20),
                  // Test cards hint
                  _buildTestCardsHint(ctx),
                  const SizedBox(height: 16),
                  // Card form
                  SlideTransition(
                    position: _formSlide,
                    child: _buildCardForm(ctx, state),
                  ),
                  const SizedBox(height: 16),
                  // Pay button
                  _buildPayButton(ctx, state),
                  const SizedBox(height: 12),
                  // Security badges
                  _buildSecurityRow(),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t('إتمام الدفع', 'Checkout'),
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          Text(_t('بوابة دفع آمنة • Stripe', 'Secure Payment • Stripe'),
              style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11)),
        ])),
        // Stripe logo badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock_rounded, color: Colors.white, size: 12),
            SizedBox(width: 4),
            Text('Stripe', style: TextStyle(
                fontFamily: 'Cairo', color: Colors.white,
                fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildOrderSummary(PaymentFormState state) {
    final name = widget.isArabic && (widget.serviceNameAr?.isNotEmpty ?? false)
        ? widget.serviceNameAr!
        : widget.serviceName;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Row(children: [
          // Service icon
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(
              widget.serviceType?.emoji ?? '🏨',
              style: const TextStyle(fontSize: 22),
            )),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 14,
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(
              '${_formatDate(state.checkIn)} → ${_formatDate(state.checkOut)} • ${state.guests} ${_t("ضيوف", "guests")}',
              style: const TextStyle(
                  fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary),
            ),
          ])),
        ]),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 12),
        _PriceLine(label: _t('السعر الأساسي', 'Base Price'),
            value: '\$${state.subtotal.toStringAsFixed(2)}'),
        const SizedBox(height: 6),
        _PriceLine(label: _t('رسوم الخدمة (5%)', 'Service Fee (5%)'),
            value: '\$${state.serviceFee.toStringAsFixed(2)}'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Text(_t('المجموع الكلي', 'Total'),
                style: const TextStyle(
                    fontFamily: 'Cairo', color: Colors.white,
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('\$${state.total.toStringAsFixed(2)} ${state.currency}',
                style: const TextStyle(
                    fontFamily: 'Cairo', color: Colors.white,
                    fontSize: 20, fontWeight: FontWeight.w900)),
          ]),
        ),
      ]),
    );
  }

  // ── Card Preview (3D flip) ────────────────────────
  Widget _buildCardPreview(PaymentFormState state) {
    return AnimatedBuilder(
      animation: _cardFlip,
      builder: (_, __) {
        final isFront = !_showCvvSide;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(pi * _cardFlip.value * (_showCvvSide ? -1 : 1) * 0.0),
          child: isFront
              ? _CardFront(card: state.card, isArabic: widget.isArabic)
              : _CardBack(card: state.card),
        );
      },
    );
  }

  // ── Test cards hint ───────────────────────────────
  Widget _buildTestCardsHint(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.secondary, size: 16),
          const SizedBox(width: 6),
          Text(_t('بطاقات اختبار Stripe', 'Stripe Test Cards'),
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary)),
        ]),
        const SizedBox(height: 8),
        ..._testCards.map((card) => GestureDetector(
          onTap: () {
            _numberCtrl.text = card.$1;
            _expiryCtrl.text = card.$2;
            _cvvCtrl.text    = card.$3;
            _holderCtrl.text = card.$4;
            ctx.read<PaymentBloc>()
              ..add(UpdateCardNumberEvent(card.$1))
              ..add(UpdateCardExpiryEvent(card.$2))
              ..add(UpdateCardCvvEvent(card.$3))
              ..add(UpdateCardHolderEvent(card.$4));
          },
          child: Container(
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
            ),
            child: Row(children: [
              Text(card.$1.substring(0, 4) == '5555' ? '💳 MC' : '💳 Visa',
                  style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 8),
              Expanded(child: Text(card.$5,
                  style: const TextStyle(
                      fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary))),
              const Icon(Icons.touch_app_rounded,
                  size: 14, color: AppColors.secondary),
            ]),
          ),
        )).toList(),
      ]),
    );
  }

  // ── Card Form ────────────────────────────────────
  Widget _buildCardForm(BuildContext ctx, PaymentFormState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.credit_card_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(_t('بيانات البطاقة', 'Card Details'),
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 16),

        // Card Number
        _CardField(
          controller: _numberCtrl,
          focusNode:  _numberFocus,
          label:      _t('رقم البطاقة', 'Card Number'),
          hint:       '1234 5678 9012 3456',
          icon:       Icons.credit_card_rounded,
          keyboardType: TextInputType.number,
          onChanged: (v) {
            final formatted = _formatCardNumber(v);
            if (formatted != v) {
              _numberCtrl.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
            ctx.read<PaymentBloc>().add(UpdateCardNumberEvent(formatted));
          },
          suffix: _CardBrandIcon(number: state.card.number),
          isValid:    state.card.number.isEmpty ? null : state.card.isNumberValid,
          maxLength: 19,
          nextFocus: _expiryFocus,
        ),
        const SizedBox(height: 12),

        Row(children: [
          // Expiry
          Expanded(child: _CardField(
            controller: _expiryCtrl,
            focusNode:  _expiryFocus,
            label:      _t('انتهاء الصلاحية', 'Expiry'),
            hint:       'MM/YY',
            icon:       Icons.date_range_rounded,
            keyboardType: TextInputType.number,
            onChanged: (v) {
              final formatted = _formatExpiry(v);
              if (formatted != v) {
                _expiryCtrl.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }
              ctx.read<PaymentBloc>().add(UpdateCardExpiryEvent(formatted));
            },
            isValid:  state.card.expiry.isEmpty ? null : state.card.isExpiryValid,
            maxLength: 5,
            nextFocus: _cvvFocus,
          )),
          const SizedBox(width: 10),
          // CVV
          Expanded(child: _CardField(
            controller: _cvvCtrl,
            focusNode:  _cvvFocus,
            label:      'CVV',
            hint:       '•••',
            icon:       Icons.lock_rounded,
            keyboardType: TextInputType.number,
            obscureText: true,
            onChanged: (v) =>
                ctx.read<PaymentBloc>().add(UpdateCardCvvEvent(v)),
            isValid: state.card.cvv.isEmpty ? null : state.card.isCvvValid,
            maxLength: 4,
            nextFocus: _holderFocus,
          )),
        ]),
        const SizedBox(height: 12),

        // Cardholder name
        _CardField(
          controller: _holderCtrl,
          focusNode:  _holderFocus,
          label:      _t('اسم حامل البطاقة', 'Cardholder Name'),
          hint:       _t('الاسم كما يظهر على البطاقة', 'Name as on card'),
          icon:       Icons.person_rounded,
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) =>
              ctx.read<PaymentBloc>().add(UpdateCardHolderEvent(v.toUpperCase())),
          isValid: state.card.holderName.isEmpty ? null : state.card.isNameValid,
        ),

        // Field error
        if (state.fieldError != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 14),
              const SizedBox(width: 6),
              Text(state.fieldError!,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.error)),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── Pay button ────────────────────────────────────
  Widget _buildPayButton(BuildContext ctx, PaymentFormState state) {
    return GestureDetector(
      onTap: state.card.isComplete
          ? () => ctx.read<PaymentBloc>().add(const SubmitPaymentEvent())
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: state.card.isComplete
              ? AppColors.primaryGradient
              : null,
          color: state.card.isComplete ? null : AppColors.textHint.withOpacity(0.3),
          borderRadius: BorderRadius.circular(18),
          boxShadow: state.card.isComplete
              ? [BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 16, offset: const Offset(0, 6))]
              : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock_rounded,
              color: state.card.isComplete ? Colors.white : AppColors.textHint,
              size: 18),
          const SizedBox(width: 10),
          Text(
            _t('ادفع الآن • \$${state.total.toStringAsFixed(2)}',
               'Pay Now • \$${state.total.toStringAsFixed(2)}'),
            style: TextStyle(
                fontFamily: 'Cairo',
                color: state.card.isComplete ? Colors.white : AppColors.textHint,
                fontSize: 16,
                fontWeight: FontWeight.w800),
          ),
        ]),
      ),
    );
  }

  Widget _buildSecurityRow() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _SecurityBadge(icon: Icons.security_rounded, label: _t('SSL آمن', 'SSL Secure')),
      const SizedBox(width: 12),
      _SecurityBadge(icon: Icons.verified_user_rounded, label: '3D Secure'),
      const SizedBox(width: 12),
      _SecurityBadge(icon: Icons.shield_rounded, label: _t('محمي', 'Protected')),
    ]);
  }

  // ════════════════════════════════════════════════
  //  PROCESSING SCREEN
  // ════════════════════════════════════════════════
  Widget _buildProcessingScreen(PaymentProcessingState state) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Animated Stripe logo
              _StripeSpinner(),
              const SizedBox(height: 32),
              Text(_t('جارٍ معالجة الدفع', 'Processing Payment'),
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                widget.isArabic
                    ? state.stepLabel
                    : state.stepLabelEn,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13),
              ),
              const SizedBox(height: 32),
              // Step progress
              Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) => _ProcessStep(
                    index: i,
                    currentStep: state.processingStep,
                  ))),
              const SizedBox(height: 32),
              // Card info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Row(children: [
                  Text(state.card.brand.logoPath,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Text(state.card.maskedNumber,
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 14,
                          letterSpacing: 2)),
                  const Spacer(),
                  Text('\$${state.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(height: 16),
              Text(_t('لا تغلق التطبيق...', 'Do not close the app...'),
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11)),
            ]),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  SUCCESS SCREEN
  // ════════════════════════════════════════════════
  Widget _buildSuccessScreen(BuildContext ctx, PaymentSuccessState state) {
    final r = state.result;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const SizedBox(height: 20),
                // Success animation
                _SuccessCheckmark(),
                const SizedBox(height: 20),
                Text(_t('تم الدفع بنجاح! 🎉', 'Payment Successful! 🎉'),
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(_t('تم تأكيد حجزك بنجاح', 'Your booking has been confirmed'),
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.textSecondary,
                        fontSize: 13),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),

                // Receipt card
                _buildReceipt(r, state.serviceName),
                const SizedBox(height: 20),
              ]),
            ),
          ),
          // Bottom actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(children: [
              // View Ticket button
              GestureDetector(
                onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: Container(
                  width: double.infinity, height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 14, offset: const Offset(0, 5))],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.luggage_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(_t('عرض رحلاتي', 'View My Trips'),
                        style: const TextStyle(
                            fontFamily: 'Cairo', color: Colors.white,
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_t('العودة للاستكشاف', 'Back to Explore'),
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.textSecondary,
                        fontSize: 13)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildReceipt(PaymentResult r, String serviceName) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Row(children: [
            const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(_t('إيصال الدفع', 'Payment Receipt'),
                style: const TextStyle(
                    fontFamily: 'Cairo', color: Colors.white,
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_t('مدفوع ✓', 'Paid ✓'),
                  style: const TextStyle(
                      fontFamily: 'Cairo', color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            _ReceiptRow(label: _t('رقم المرجع', 'Reference No.'),
                value: r.confirmationCode,
                bold: true, copyable: true),
            const Divider(height: 20),
            _ReceiptRow(label: _t('رقم المعاملة', 'Transaction ID'),
                value: r.transactionId.substring(0, 20) + '...',
                mono: true),
            _ReceiptRow(label: _t('الخدمة', 'Service'),
                value: serviceName),
            _ReceiptRow(label: _t('طريقة الدفع', 'Payment Method'),
                value: '${r.brand.displayName} ••${r.last4}'),
            _ReceiptRow(label: _t('التاريخ والوقت', 'Date & Time'),
                value: _formatDateTime(r.timestamp)),
            const Divider(height: 20),
            _ReceiptRow(
              label: _t('المبلغ المدفوع', 'Amount Paid'),
              value: '\$${r.amount.toStringAsFixed(2)} ${r.currency}',
              bold: true,
              valueColor: AppColors.primary,
            ),
          ]),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════
  //  FAILED SCREEN
  // ════════════════════════════════════════════════
  Widget _buildFailedScreen(BuildContext ctx, PaymentFailedState state) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.error.withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.credit_card_off_rounded,
                  color: AppColors.error, size: 42),
            ),
            const SizedBox(height: 20),
            Text(_t('فشل الدفع', 'Payment Failed'),
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.6)),
            const Spacer(),
            GestureDetector(
              onTap: () => ctx.read<PaymentBloc>().add(const ResetPaymentEvent()),
              child: Container(
                width: double.infinity, height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 14, offset: const Offset(0, 5))],
                ),
                child: Center(child: Text(
                  _t('حاول مرة أخرى', 'Try Again'),
                  style: const TextStyle(
                      fontFamily: 'Cairo', color: Colors.white,
                      fontSize: 15, fontWeight: FontWeight.w700),
                )),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_t('إلغاء', 'Cancel'),
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.textSecondary)),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────
  String _formatDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month-1]}';
  }

  String _formatDateTime(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

  String _formatCardNumber(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  String _formatExpiry(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 2) {
      return '${digits.substring(0, 2)}/${digits.substring(2).substring(0, min(digits.length - 2, 2))}';
    }
    return digits;
  }
}

// ════════════════════════════════════════════════════════════
//  Card Preview Widgets
// ════════════════════════════════════════════════════════════
class _CardFront extends StatelessWidget {
  final CardDetails card;
  final bool isArabic;
  const _CardFront({required this.card, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        gradient: card.brand == CardBrand.visa
            ? const LinearGradient(
                colors: [Color(0xFF0B4F6C), Color(0xFF1A3A5C)],
                begin: Alignment.topLeft, end: Alignment.bottomRight)
            : card.brand == CardBrand.mastercard
                ? const LinearGradient(
                    colors: [Color(0xFF8B1A1A), Color(0xFFCC4A00)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)
                : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.4),
            blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.wifi_rounded,
                color: Colors.white70, size: 20),
            const Spacer(),
            Text(card.brand.displayName,
                style: const TextStyle(
                    fontFamily: 'Cairo', color: Colors.white,
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          const Spacer(),
          // Chip
          Container(
            width: 40, height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          // Card number
          Text(
            card.number.isEmpty
                ? '•••• •••• •••• ••••'
                : card.number.padRight(19, '•'),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                letterSpacing: 2,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isArabic ? 'اسم الحامل' : 'CARDHOLDER',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 8)),
              Text(
                card.holderName.isEmpty ? 'FULL NAME' : card.holderName.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ]),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(isArabic ? 'ينتهي' : 'EXPIRES',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 8)),
              Text(
                card.expiry.isEmpty ? '••/••' : card.expiry,
                style: const TextStyle(color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ]),
          ]),
        ]),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final CardDetails card;
  const _CardBack({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1A2333), Color(0xFF2D3748)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        const SizedBox(height: 28),
        Container(height: 40, color: Colors.black),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Expanded(
              child: Container(
                height: 36,
                color: Colors.white.withOpacity(0.9),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerRight,
                child: Text(
                  card.cvv.isEmpty ? '•••' : card.cvv,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('CVV',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Small helper widgets
// ════════════════════════════════════════════════════════════

class _CardField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label, hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final ValueChanged<String> onChanged;
  final bool? isValid;
  final int? maxLength;
  final FocusNode? nextFocus;
  final Widget? suffix;
  final TextCapitalization textCapitalization;

  const _CardField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    required this.onChanged,
    this.isValid,
    this.maxLength,
    this.nextFocus,
    this.suffix,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    if (isValid == null)      borderColor = AppColors.surfaceVariant;
    else if (isValid == true) borderColor = AppColors.success;
    else                      borderColor = AppColors.error;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(14),
        color: AppColors.background,
      ),
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(icon,
              color: isValid == false ? AppColors.error : AppColors.primary,
              size: 18),
        ),
        Expanded(child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          textInputAction: nextFocus != null
              ? TextInputAction.next
              : TextInputAction.done,
          onSubmitted: (_) {
            if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
          },
          decoration: InputDecoration(
            hintText: hint,
            labelText: label,
            labelStyle: const TextStyle(
                fontFamily: 'Cairo', fontSize: 12, color: AppColors.textHint),
            hintStyle: const TextStyle(
                fontFamily: 'Cairo', fontSize: 12, color: AppColors.textHint),
            border: InputBorder.none,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          style: const TextStyle(
              fontFamily: 'Cairo', fontSize: 14, color: AppColors.textPrimary),
        )),
        if (suffix != null) Padding(padding: const EdgeInsets.only(right: 8), child: suffix!),
        if (isValid == true)
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 16),
          ),
      ]),
    );
  }
}

class _CardBrandIcon extends StatelessWidget {
  final String number;
  const _CardBrandIcon({required this.number});
  @override
  Widget build(BuildContext context) {
    final brand = CardBrandX.detect(number);
    if (brand == CardBrand.unknown) return const SizedBox.shrink();
    return Text(brand == CardBrand.visa ? '💳' : '💳',
        style: const TextStyle(fontSize: 18));
  }
}

class _SecurityBadge extends StatelessWidget {
  final IconData icon; final String label;
  const _SecurityBadge({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: AppColors.textHint),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(
        fontFamily: 'Cairo', fontSize: 10, color: AppColors.textHint)),
  ]);
}

class _PriceLine extends StatelessWidget {
  final String label, value;
  const _PriceLine({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(
          fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary)),
      Text(value, style: const TextStyle(
          fontFamily: 'Cairo', fontSize: 12,
          fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ],
  );
}

class _ProcessStep extends StatelessWidget {
  final int index, currentStep;
  const _ProcessStep({required this.index, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final done   = index < currentStep;
    final active = index == currentStep;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 32 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: done
            ? AppColors.success
            : active
                ? Colors.white
                : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class _StripeSpinner extends StatefulWidget {
  @override
  State<_StripeSpinner> createState() => _StripeSpinnerState();
}
class _StripeSpinnerState extends State<_StripeSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        width: 90, height: 90,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CircularProgressIndicator(
            value: _ctrl.value,
            strokeWidth: 4,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            backgroundColor: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.credit_card_rounded,
            color: Colors.white, size: 28),
      ),
    ],
  );
}

class _SuccessCheckmark extends StatefulWidget {
  @override
  State<_SuccessCheckmark> createState() => _SuccessCheckmarkState();
}
class _SuccessCheckmarkState extends State<_SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: Container(
      width: 100, height: 100,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFF27AE60), Color(0xFF1E7A45)]),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Color(0x5527AE60), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
    ),
  );
}

class _ReceiptRow extends StatelessWidget {
  final String label, value;
  final bool bold, mono, copyable;
  final Color? valueColor;
  const _ReceiptRow({
    required this.label, required this.value,
    this.bold = false, this.mono = false,
    this.copyable = false, this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
          fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(width: 8),
      Expanded(child: GestureDetector(
        onTap: copyable ? () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Copied!'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ));
        } : null,
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Flexible(child: Text(value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: mono ? null : 'Cairo',
              fontSize: bold ? 14 : 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
              letterSpacing: mono ? 1.0 : 0,
            ),
          )),
          if (copyable) ...[
            const SizedBox(width: 4),
            const Icon(Icons.copy_rounded, size: 12, color: AppColors.textHint),
          ],
        ]),
      )),
    ]),
  );
}
