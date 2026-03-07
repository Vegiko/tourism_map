import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

// ════════════════════════════════════════════════════════════
//  PaymentMethod entity
// ════════════════════════════════════════════════════════════
enum CardBrand { visa, mastercard, amex, unknown }

extension CardBrandX on CardBrand {
  String get displayName {
    switch (this) {
      case CardBrand.visa:       return 'Visa';
      case CardBrand.mastercard: return 'Mastercard';
      case CardBrand.amex:       return 'American Express';
      default:                   return 'Card';
    }
  }
  String get logoPath {
    switch (this) {
      case CardBrand.visa:       return '💳 Visa';
      case CardBrand.mastercard: return '💳 MC';
      case CardBrand.amex:       return '💳 Amex';
      default:                   return '💳';
    }
  }
  static CardBrand detect(String number) {
    final n = number.replaceAll(' ', '');
    if (n.startsWith('4'))    return CardBrand.visa;
    if (n.startsWith('5') || n.startsWith('2')) return CardBrand.mastercard;
    if (n.startsWith('3'))    return CardBrand.amex;
    return CardBrand.unknown;
  }
}

class CardDetails extends Equatable {
  final String number;
  final String expiry;
  final String cvv;
  final String holderName;

  const CardDetails({
    this.number = '',
    this.expiry = '',
    this.cvv = '',
    this.holderName = '',
  });

  CardBrand get brand => CardBrandX.detect(number);
  String get maskedNumber => number.length >= 4
      ? '**** **** **** ${number.replaceAll(' ', '').substring(number.replaceAll(' ', '').length - 4)}'
      : '****';

  bool get isNumberValid  => number.replaceAll(' ', '').length >= 13;
  bool get isExpiryValid  => _validateExpiry(expiry);
  bool get isCvvValid     => cvv.length >= 3;
  bool get isNameValid    => holderName.trim().length >= 2;
  bool get isComplete     => isNumberValid && isExpiryValid && isCvvValid && isNameValid;

  bool _validateExpiry(String e) {
    if (e.length < 5) return false;
    final parts = e.split('/');
    if (parts.length != 2) return false;
    final month = int.tryParse(parts[0]);
    final year = int.tryParse('20${parts[1]}');
    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;
    final now = DateTime.now();
    final exp = DateTime(year, month + 1);
    return exp.isAfter(now);
  }

  CardDetails copyWith({
    String? number, String? expiry, String? cvv, String? holderName,
  }) =>
      CardDetails(
        number:     number     ?? this.number,
        expiry:     expiry     ?? this.expiry,
        cvv:        cvv        ?? this.cvv,
        holderName: holderName ?? this.holderName,
      );

  @override
  List<Object?> get props => [number, expiry, cvv, holderName];
}

// ════════════════════════════════════════════════════════════
//  PaymentResult
// ════════════════════════════════════════════════════════════
class PaymentResult extends Equatable {
  final bool success;
  final String transactionId;
  final String confirmationCode;
  final DateTime timestamp;
  final double amount;
  final String currency;
  final String last4;
  final CardBrand brand;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    required this.transactionId,
    required this.confirmationCode,
    required this.timestamp,
    required this.amount,
    required this.currency,
    required this.last4,
    required this.brand,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [transactionId, success];
}

// ════════════════════════════════════════════════════════════
//  EVENTS
// ════════════════════════════════════════════════════════════
abstract class PaymentEvent extends Equatable {
  const PaymentEvent();
  @override
  List<Object?> get props => [];
}

class InitPaymentEvent extends PaymentEvent {
  final String serviceId;
  final String serviceName;
  final double amount;
  final String currency;
  final int guests;
  final DateTime checkIn;
  final DateTime checkOut;

  const InitPaymentEvent({
    required this.serviceId,
    required this.serviceName,
    required this.amount,
    this.currency = 'USD',
    required this.guests,
    required this.checkIn,
    required this.checkOut,
  });

  @override
  List<Object?> get props => [serviceId, amount];
}

class UpdateCardNumberEvent extends PaymentEvent {
  final String value;
  const UpdateCardNumberEvent(this.value);
  @override
  List<Object?> get props => [value];
}

class UpdateCardExpiryEvent extends PaymentEvent {
  final String value;
  const UpdateCardExpiryEvent(this.value);
  @override
  List<Object?> get props => [value];
}

class UpdateCardCvvEvent extends PaymentEvent {
  final String value;
  const UpdateCardCvvEvent(this.value);
  @override
  List<Object?> get props => [value];
}

class UpdateCardHolderEvent extends PaymentEvent {
  final String value;
  const UpdateCardHolderEvent(this.value);
  @override
  List<Object?> get props => [value];
}

class SelectSavedCardEvent extends PaymentEvent {
  final CardDetails card;
  const SelectSavedCardEvent(this.card);
  @override
  List<Object?> get props => [card];
}

class SubmitPaymentEvent extends PaymentEvent {
  const SubmitPaymentEvent();
}

class ResetPaymentEvent extends PaymentEvent {
  const ResetPaymentEvent();
}

// ════════════════════════════════════════════════════════════
//  STATES
// ════════════════════════════════════════════════════════════
abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentFormState extends PaymentState {
  final String serviceId;
  final String serviceName;
  final double subtotal;
  final double serviceFee;
  final double total;
  final String currency;
  final int guests;
  final DateTime checkIn;
  final DateTime checkOut;
  final CardDetails card;
  final bool isProcessing;
  final String? fieldError;
  final int currentStep; // 0=form, 1=processing, 2=result

  const PaymentFormState({
    required this.serviceId,
    required this.serviceName,
    required this.subtotal,
    required this.serviceFee,
    required this.total,
    required this.currency,
    required this.guests,
    required this.checkIn,
    required this.checkOut,
    this.card = const CardDetails(),
    this.isProcessing = false,
    this.fieldError,
    this.currentStep = 0,
  });

  PaymentFormState copyWith({
    CardDetails? card,
    bool? isProcessing,
    String? Function()? fieldError,
    int? currentStep,
  }) =>
      PaymentFormState(
        serviceId:   serviceId,
        serviceName: serviceName,
        subtotal:    subtotal,
        serviceFee:  serviceFee,
        total:       total,
        currency:    currency,
        guests:      guests,
        checkIn:     checkIn,
        checkOut:    checkOut,
        card:        card          ?? this.card,
        isProcessing: isProcessing ?? this.isProcessing,
        fieldError:  fieldError != null ? fieldError() : this.fieldError,
        currentStep: currentStep  ?? this.currentStep,
      );

  @override
  List<Object?> get props =>
      [card, isProcessing, fieldError, currentStep, serviceId];
}

class PaymentProcessingState extends PaymentState {
  final String serviceName;
  final double amount;
  final String currency;
  final CardDetails card;
  final int processingStep; // 0=validating, 1=authenticating, 2=charging, 3=confirming

  const PaymentProcessingState({
    required this.serviceName,
    required this.amount,
    required this.currency,
    required this.card,
    this.processingStep = 0,
  });

  String get stepLabel {
    switch (processingStep) {
      case 0: return 'التحقق من البطاقة...';
      case 1: return 'المصادقة الآمنة...';
      case 2: return 'معالجة الدفع...';
      case 3: return 'تأكيد الحجز...';
      default: return 'جارٍ المعالجة...';
    }
  }
  String get stepLabelEn {
    switch (processingStep) {
      case 0: return 'Validating card...';
      case 1: return 'Secure authentication...';
      case 2: return 'Processing payment...';
      case 3: return 'Confirming booking...';
      default: return 'Processing...';
    }
  }

  PaymentProcessingState copyWith({int? processingStep}) =>
      PaymentProcessingState(
        serviceName:    serviceName,
        amount:         amount,
        currency:       currency,
        card:           card,
        processingStep: processingStep ?? this.processingStep,
      );

  @override
  List<Object?> get props => [processingStep];
}

class PaymentSuccessState extends PaymentState {
  final PaymentResult result;
  final String serviceName;
  const PaymentSuccessState({required this.result, required this.serviceName});
  @override
  List<Object?> get props => [result];
}

class PaymentFailedState extends PaymentState {
  final String message;
  final PaymentFormState previousForm;
  const PaymentFailedState({required this.message, required this.previousForm});
  @override
  List<Object?> get props => [message];
}

// ════════════════════════════════════════════════════════════
//  BLOC
// ════════════════════════════════════════════════════════════
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  static const _uuid = Uuid();

  PaymentBloc() : super(PaymentInitial()) {
    on<InitPaymentEvent>(_onInit);
    on<UpdateCardNumberEvent>(_onNumber);
    on<UpdateCardExpiryEvent>(_onExpiry);
    on<UpdateCardCvvEvent>(_onCvv);
    on<UpdateCardHolderEvent>(_onHolder);
    on<SelectSavedCardEvent>(_onSelectSaved);
    on<SubmitPaymentEvent>(_onSubmit);
    on<ResetPaymentEvent>(_onReset);
  }

  void _onInit(InitPaymentEvent e, Emitter<PaymentState> emit) {
    final fee = e.amount * 0.05;
    emit(PaymentFormState(
      serviceId:   e.serviceId,
      serviceName: e.serviceName,
      subtotal:    e.amount,
      serviceFee:  double.parse(fee.toStringAsFixed(2)),
      total:       double.parse((e.amount + fee).toStringAsFixed(2)),
      currency:    e.currency,
      guests:      e.guests,
      checkIn:     e.checkIn,
      checkOut:    e.checkOut,
    ));
  }

  void _onNumber(UpdateCardNumberEvent e, Emitter<PaymentState> emit) {
    if (state is PaymentFormState) {
      emit((state as PaymentFormState).copyWith(
        card: (state as PaymentFormState).card.copyWith(number: e.value),
        fieldError: () => null,
      ));
    }
  }

  void _onExpiry(UpdateCardExpiryEvent e, Emitter<PaymentState> emit) {
    if (state is PaymentFormState) {
      emit((state as PaymentFormState).copyWith(
        card: (state as PaymentFormState).card.copyWith(expiry: e.value),
        fieldError: () => null,
      ));
    }
  }

  void _onCvv(UpdateCardCvvEvent e, Emitter<PaymentState> emit) {
    if (state is PaymentFormState) {
      emit((state as PaymentFormState).copyWith(
        card: (state as PaymentFormState).card.copyWith(cvv: e.value),
        fieldError: () => null,
      ));
    }
  }

  void _onHolder(UpdateCardHolderEvent e, Emitter<PaymentState> emit) {
    if (state is PaymentFormState) {
      emit((state as PaymentFormState).copyWith(
        card: (state as PaymentFormState).card.copyWith(holderName: e.value),
        fieldError: () => null,
      ));
    }
  }

  void _onSelectSaved(SelectSavedCardEvent e, Emitter<PaymentState> emit) {
    if (state is PaymentFormState) {
      emit((state as PaymentFormState).copyWith(card: e.card));
    }
  }

  // ── Simulate Stripe payment processing ──────────
  Future<void> _onSubmit(
      SubmitPaymentEvent e, Emitter<PaymentState> emit) async {
    if (state is! PaymentFormState) return;
    final form = state as PaymentFormState;

    if (!form.card.isComplete) {
      emit(form.copyWith(
        fieldError: () => form.card.isNumberValid == false
            ? 'رقم البطاقة غير صحيح'
            : form.card.isExpiryValid == false
                ? 'تاريخ انتهاء الصلاحية غير صحيح'
                : form.card.isCvvValid == false
                    ? 'رمز CVV غير صحيح'
                    : 'يرجى إدخال اسم حامل البطاقة',
      ));
      return;
    }

    // Start processing animation
    emit(PaymentProcessingState(
      serviceName: form.serviceName,
      amount:      form.total,
      currency:    form.currency,
      card:        form.card,
    ));

    // ── Simulate 4 processing steps ─────────────
    for (var step = 0; step < 4; step++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (state is PaymentProcessingState) {
        emit((state as PaymentProcessingState).copyWith(processingStep: step));
      }
    }

    await Future.delayed(const Duration(milliseconds: 600));

    // ── Simulate success (95%) / decline (5%) ────
    // Use card number ending to simulate decline: 0000 = decline
    final last4 = form.card.number.replaceAll(' ', '');
    final isDeclined = last4.endsWith('0000');

    if (isDeclined) {
      emit(PaymentFailedState(
        message: 'تم رفض البطاقة. يرجى التحقق من المعلومات أو استخدام بطاقة أخرى.',
        previousForm: form,
      ));
      return;
    }

    // ── Build success result ──────────────────────
    final txId = 'ch_${_uuid.v4().replaceAll('-', '').substring(0, 16)}';
    final conf = 'TRV-${DateTime.now().year}-${_uuid.v4().substring(0, 6).toUpperCase()}';

    emit(PaymentSuccessState(
      result: PaymentResult(
        success:          true,
        transactionId:    txId,
        confirmationCode: conf,
        timestamp:        DateTime.now(),
        amount:           form.total,
        currency:         form.currency,
        last4:            last4.length >= 4 ? last4.substring(last4.length - 4) : '****',
        brand:            form.card.brand,
      ),
      serviceName: form.serviceName,
    ));
  }

  void _onReset(ResetPaymentEvent e, Emitter<PaymentState> emit) {
    emit(PaymentInitial());
  }
}
