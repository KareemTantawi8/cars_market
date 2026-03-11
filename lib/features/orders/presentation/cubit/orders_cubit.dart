import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/orders_repository.dart';

abstract class OrdersState {}

class OrdersInitial extends OrdersState {}

class OrdersAccepting extends OrdersState {}

class OrderAccepted extends OrdersState {
  final String message;
  final int? chatId;
  final Map<String, dynamic>? data;

  OrderAccepted({
    required this.message,
    this.chatId,
    this.data,
  });
}

class OrdersError extends OrdersState {
  final String message;

  OrdersError(this.message);
}

class OrdersCubit extends Cubit<OrdersState> {
  final OrdersRepository _repository = OrdersRepository();

  OrdersCubit() : super(OrdersInitial());

  /// Accept a pending order (vendor). On success, chat_id can be used to open chat.
  Future<void> acceptOrder(int orderId) async {
    emit(OrdersAccepting());
    try {
      final result = await _repository.acceptOrder(orderId);
      emit(OrderAccepted(
        message: result.message,
        chatId: result.chatId,
        data: result.data,
      ));
    } catch (e) {
      emit(OrdersError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
