import 'dart:async';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/partner_service.dart';
import '../../domain/usecases/partner_usecases.dart';
import '../../../auth/domain/entities/app_user.dart';

// ════════════════════════════════════════════════════════════
//  EVENTS
// ════════════════════════════════════════════════════════════
abstract class PartnerEvent extends Equatable {
  const PartnerEvent();
  @override
  List<Object?> get props => [];
}

/// Load dashboard on first open
class LoadPartnerDashboardEvent extends PartnerEvent {
  final String partnerId;
  const LoadPartnerDashboardEvent(this.partnerId);
  @override
  List<Object?> get props => [partnerId];
}

/// Watch real-time service updates
class WatchServicesEvent extends PartnerEvent {
  final String partnerId;
  const WatchServicesEvent(this.partnerId);
  @override
  List<Object?> get props => [partnerId];
}

/// Internal: stream emitted new list
class _ServicesUpdatedEvent extends PartnerEvent {
  final List<PartnerService> services;
  const _ServicesUpdatedEvent(this.services);
  @override
  List<Object?> get props => [services];
}

/// Internal: stats stream updated
class _StatsUpdatedEvent extends PartnerEvent {
  final PartnerStats stats;
  const _StatsUpdatedEvent(this.stats);
  @override
  List<Object?> get props => [stats];
}

/// Submit new service form
class AddServiceSubmittedEvent extends PartnerEvent {
  final String partnerId;
  final String partnerName;
  final String partnerNameAr;
  final String name;
  final String nameAr;
  final String description;
  final String descriptionAr;
  final ServiceType serviceType;
  final double price;
  final ServiceLocation? location;
  final List<File> images;

  const AddServiceSubmittedEvent({
    required this.partnerId,
    required this.partnerName,
    this.partnerNameAr = '',
    required this.name,
    this.nameAr = '',
    this.description = '',
    this.descriptionAr = '',
    required this.serviceType,
    required this.price,
    this.location,
    required this.images,
  });

  @override
  List<Object?> get props => [partnerId, name, serviceType, price];
}

/// Delete a service
class DeleteServiceEvent extends PartnerEvent {
  final String serviceId;
  const DeleteServiceEvent(this.serviceId);
  @override
  List<Object?> get props => [serviceId];
}

/// Update service status (activate/suspend)
class UpdateServiceStatusEvent extends PartnerEvent {
  final String serviceId;
  final ServiceStatus newStatus;
  const UpdateServiceStatusEvent(this.serviceId, this.newStatus);
  @override
  List<Object?> get props => [serviceId, newStatus];
}

/// Clear error message
class ClearPartnerErrorEvent extends PartnerEvent {
  const ClearPartnerErrorEvent();
}

// ════════════════════════════════════════════════════════════
//  STATES
// ════════════════════════════════════════════════════════════
abstract class PartnerState extends Equatable {
  const PartnerState();
  @override
  List<Object?> get props => [];
}

class PartnerInitial extends PartnerState {}

class PartnerLoading extends PartnerState {}

class PartnerDashboardLoaded extends PartnerState {
  final List<PartnerService> services;
  final PartnerStats stats;
  final bool isAddingService;   // true while form submit in progress
  final String? successMessage;
  final String? errorMessage;

  const PartnerDashboardLoaded({
    required this.services,
    required this.stats,
    this.isAddingService = false,
    this.successMessage,
    this.errorMessage,
  });

  PartnerDashboardLoaded copyWith({
    List<PartnerService>? services,
    PartnerStats? stats,
    bool? isAddingService,
    String? Function()? successMessage,
    String? Function()? errorMessage,
  }) {
    return PartnerDashboardLoaded(
      services:       services       ?? this.services,
      stats:          stats          ?? this.stats,
      isAddingService: isAddingService ?? this.isAddingService,
      successMessage:  successMessage != null ? successMessage() : this.successMessage,
      errorMessage:    errorMessage   != null ? errorMessage()   : this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [services, stats, isAddingService, successMessage, errorMessage];
}

class ServiceAddedSuccess extends PartnerState {
  final PartnerService service;
  const ServiceAddedSuccess(this.service);
  @override
  List<Object?> get props => [service];
}

class PartnerError extends PartnerState {
  final String message;
  const PartnerError(this.message);
  @override
  List<Object?> get props => [message];
}

// ════════════════════════════════════════════════════════════
//  BLOC
// ════════════════════════════════════════════════════════════
class PartnerBloc extends Bloc<PartnerEvent, PartnerState> {
  final AddService _addService;
  final DeleteService _deleteService;
  final WatchPartnerServices _watchServices;
  final WatchPartnerStats _watchStats;

  StreamSubscription<List<PartnerService>>? _servicesSub;
  StreamSubscription<PartnerStats>? _statsSub;

  static const _uuid = Uuid();

  PartnerBloc({
    required AddService addService,
    required DeleteService deleteService,
    required WatchPartnerServices watchServices,
    required WatchPartnerStats watchStats,
  })  : _addService    = addService,
        _deleteService = deleteService,
        _watchServices = watchServices,
        _watchStats    = watchStats,
        super(PartnerInitial()) {
    on<LoadPartnerDashboardEvent>(_onLoad);
    on<WatchServicesEvent>(_onWatch);
    on<_ServicesUpdatedEvent>(_onServicesUpdated);
    on<_StatsUpdatedEvent>(_onStatsUpdated);
    on<AddServiceSubmittedEvent>(_onAddService);
    on<DeleteServiceEvent>(_onDelete);
    on<UpdateServiceStatusEvent>(_onUpdateStatus);
    on<ClearPartnerErrorEvent>(_onClearError);
  }

  // ── Load dashboard ──────────────────────────────
  Future<void> _onLoad(
    LoadPartnerDashboardEvent event,
    Emitter<PartnerState> emit,
  ) async {
    emit(PartnerLoading());
    add(WatchServicesEvent(event.partnerId));
  }

  // ── Subscribe to real-time streams ─────────────
  Future<void> _onWatch(
    WatchServicesEvent event,
    Emitter<PartnerState> emit,
  ) async {
    await _servicesSub?.cancel();
    await _statsSub?.cancel();

    _servicesSub = _watchServices(event.partnerId).listen(
      (services) => add(_ServicesUpdatedEvent(services)),
      onError: (_) {},
    );

    _statsSub = _watchStats(event.partnerId).listen(
      (stats) => add(_StatsUpdatedEvent(stats)),
      onError: (_) {},
    );
  }

  // ── Handle services stream update ──────────────
  void _onServicesUpdated(
    _ServicesUpdatedEvent event,
    Emitter<PartnerState> emit,
  ) {
    if (state is PartnerDashboardLoaded) {
      emit((state as PartnerDashboardLoaded)
          .copyWith(services: event.services));
    } else {
      emit(PartnerDashboardLoaded(
        services: event.services,
        stats: const PartnerStats(),
      ));
    }
  }

  // ── Handle stats stream update ─────────────────
  void _onStatsUpdated(
    _StatsUpdatedEvent event,
    Emitter<PartnerState> emit,
  ) {
    if (state is PartnerDashboardLoaded) {
      emit((state as PartnerDashboardLoaded).copyWith(stats: event.stats));
    } else {
      emit(PartnerDashboardLoaded(
        services: const [],
        stats: event.stats,
      ));
    }
  }

  // ── Add service ─────────────────────────────────
  Future<void> _onAddService(
    AddServiceSubmittedEvent event,
    Emitter<PartnerState> emit,
  ) async {
    if (state is PartnerDashboardLoaded) {
      final current = state as PartnerDashboardLoaded;
      emit(current.copyWith(isAddingService: true, errorMessage: () => null));
    }

    final now = DateTime.now();
    final service = PartnerService(
      id:            '',           // will be assigned by Firestore
      partnerId:     event.partnerId,
      partnerName:   event.partnerName,
      partnerNameAr: event.partnerNameAr,
      name:          event.name,
      nameAr:        event.nameAr,
      description:   event.description,
      descriptionAr: event.descriptionAr,
      serviceType:   event.serviceType,
      price:         event.price,
      location:      event.location,
      status:        ServiceStatus.pending,
      createdAt:     now,
      updatedAt:     now,
    );

    final result = await _addService(
      AddServiceParams(service: service, images: event.images),
    );

    result.fold(
      (failure) {
        if (state is PartnerDashboardLoaded) {
          emit((state as PartnerDashboardLoaded).copyWith(
            isAddingService: false,
            errorMessage: () => failure.message,
          ));
        } else {
          emit(PartnerError(failure.message));
        }
      },
      (added) {
        // Emit success state to trigger navigation pop
        emit(ServiceAddedSuccess(added));
        // Restore dashboard - stream will auto-update services list
        if (state is! PartnerDashboardLoaded) {
          emit(PartnerDashboardLoaded(
            services: const [],
            stats: const PartnerStats(),
            successMessage: 'تمت إضافة الخدمة بنجاح! 🎉',
          ));
        }
      },
    );
  }

  // ── Delete service ──────────────────────────────
  Future<void> _onDelete(
    DeleteServiceEvent event,
    Emitter<PartnerState> emit,
  ) async {
    final result = await _deleteService(event.serviceId);
    result.fold(
      (f) {
        if (state is PartnerDashboardLoaded) {
          emit((state as PartnerDashboardLoaded).copyWith(
            errorMessage: () => f.message,
          ));
        }
      },
      (_) {
        if (state is PartnerDashboardLoaded) {
          emit((state as PartnerDashboardLoaded).copyWith(
            successMessage: () => 'تم حذف الخدمة',
          ));
        }
      },
    );
  }

  // ── Update status ────────────────────────────────
  Future<void> _onUpdateStatus(
    UpdateServiceStatusEvent event,
    Emitter<PartnerState> emit,
  ) async {
    // Optimistic update - stream will confirm
    if (state is PartnerDashboardLoaded) {
      final current = state as PartnerDashboardLoaded;
      final updated = current.services.map((s) {
        if (s.id == event.serviceId) return s.copyWith(status: event.newStatus);
        return s;
      }).toList();
      emit(current.copyWith(services: updated));
    }
  }

  // ── Clear error ──────────────────────────────────
  void _onClearError(
    ClearPartnerErrorEvent event,
    Emitter<PartnerState> emit,
  ) {
    if (state is PartnerDashboardLoaded) {
      emit((state as PartnerDashboardLoaded).copyWith(
        errorMessage:   () => null,
        successMessage: () => null,
      ));
    }
  }

  @override
  Future<void> close() {
    _servicesSub?.cancel();
    _statsSub?.cancel();
    return super.close();
  }
}
