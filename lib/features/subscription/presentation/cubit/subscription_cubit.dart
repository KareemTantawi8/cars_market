import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/models/plan_model.dart';

/// Subscription State
abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SubscriptionInitial extends SubscriptionState {}

/// Loading state
class SubscriptionLoading extends SubscriptionState {}

/// Plans loaded successfully
class PlansLoaded extends SubscriptionState {
  final List<PlanModel> plans;

  const PlansLoaded(this.plans);

  @override
  List<Object?> get props => [plans];
}

/// Plan details loaded successfully
class PlanDetailsLoaded extends SubscriptionState {
  final PlanModel plan;

  const PlanDetailsLoaded(this.plan);

  @override
  List<Object?> get props => [plan];
}

/// Error state
class SubscriptionError extends SubscriptionState {
  final String message;

  const SubscriptionError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Subscription Cubit
class SubscriptionCubit extends Cubit<SubscriptionState> {
  final SubscriptionRepository _subscriptionRepository;

  SubscriptionCubit({SubscriptionRepository? subscriptionRepository})
      : _subscriptionRepository = subscriptionRepository ?? SubscriptionRepository(),
        super(SubscriptionInitial());

  /// Fetch all subscription plans
  Future<void> fetchPlans() async {
    emit(SubscriptionLoading());

    try {
      final response = await _subscriptionRepository.getPlans();
      emit(PlansLoaded(response.plans));
    } catch (e) {
      emit(SubscriptionError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Fetch plan details by ID
  Future<void> fetchPlanDetails(int planId) async {
    emit(SubscriptionLoading());

    try {
      final response = await _subscriptionRepository.getPlanDetails(planId);
      emit(PlanDetailsLoaded(response.plan));
    } catch (e) {
      emit(SubscriptionError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Reset to initial state
  void reset() {
    emit(SubscriptionInitial());
  }
}

