import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

/// Orders Repository - Handles order API calls (e.g. vendor accept)
class OrdersRepository {
  final ApiClient _apiClient = ApiClient();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('📦 OrdersRepository: $message');
    }
  }

  /// POST /api/v1/orders/{id}/accept - Vendor accepts a pending order. Returns chat_id for navigation. 400 Order not pending / 403 Forbidden.
  Future<OrderAcceptResult> acceptOrder(int orderId) async {
    _log('✅ Accepting order: $orderId');
    try {
      final response = await _apiClient.post(ApiEndpoints.orderAccept(orderId));

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final message = data['message']?.toString();
          final chatId = data['chat_id'];
          final orderData = data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : null;
          return OrderAcceptResult(
            message: message ?? 'Order accepted successfully.',
            chatId: chatId is int ? chatId : (chatId is num ? chatId.toInt() : null),
            data: orderData,
          );
        }
        return OrderAcceptResult(message: 'Order accepted successfully.');
      } else {
        throw Exception('Failed to accept order: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ Error accepting order: ${e.message}');
      if (e.response != null) {
        if (e.response!.statusCode == 400) {
          final msg = e.response!.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Order is not pending.'
              : 'Order is not pending.';
          throw Exception(msg);
        }
        if (e.response!.statusCode == 403) {
          final msg = e.response!.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Unauthorized action.'
              : 'Unauthorized action.';
          throw Exception(msg);
        }
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? 'Failed to accept order'
            : 'Failed to accept order';
        throw Exception(errorMessage);
      }
      throw Exception('Failed to accept order');
    }
  }
}

/// Result of accepting an order (includes chat_id for opening chat)
class OrderAcceptResult {
  final String message;
  final int? chatId;
  final Map<String, dynamic>? data;

  OrderAcceptResult({
    required this.message,
    this.chatId,
    this.data,
  });
}
