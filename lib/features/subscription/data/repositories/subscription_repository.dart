import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/plan_model.dart';

/// Subscription Repository - Handles subscription plans API calls
class SubscriptionRepository {
  final ApiClient _apiClient;

  SubscriptionRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  void _log(String message) {
    // ignore: avoid_print
    print('💳 SubscriptionRepository: $message');
  }

  /// Get all subscription plans
  /// GET /api/v1/plans
  Future<PlansResponseModel> getPlans() async {
    _log('📋 Fetching plans from: ${ApiEndpoints.plans}');
    try {
      final response = await _apiClient.get(
        ApiEndpoints.plans,
      );

      _log('✅ Plans response status: ${response.statusCode}');
      _log('📄 Plans response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final result = PlansResponseModel.fromJson(data);
          _log('✅ Parsed ${result.plans.length} plans');
          return result;
        }
        return PlansResponseModel(plans: []);
      } else {
        throw Exception('Failed to fetch plans: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ DioException fetching plans: ${e.message}');
      _log('❌ Response: ${e.response?.data}');
      // Handle API errors
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'فشل في جلب الخطط'
            : 'فشل في جلب الخطط';
        throw Exception(errorMessage);
      } else {
        throw Exception('خطأ في الشبكة: ${e.message}');
      }
    } catch (e) {
      _log('❌ Unexpected error fetching plans: $e');
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  /// Get plan details by ID
  /// GET /api/v1/plans/:id
  Future<PlanDetailsResponseModel> getPlanDetails(int planId) async {
    _log('📋 Fetching plan details for ID: $planId');
    try {
      final response = await _apiClient.get(
        ApiEndpoints.planDetails(planId),
      );

      _log('✅ Plan details response status: ${response.statusCode}');
      _log('📄 Plan details response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final result = PlanDetailsResponseModel.fromJson(data);
          _log('✅ Parsed plan details: ${result.plan.name}');
          return result;
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception('Failed to fetch plan details: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ DioException fetching plan details: ${e.message}');
      _log('❌ Response: ${e.response?.data}');
      // Handle API errors
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'فشل في جلب تفاصيل الخطة'
            : 'فشل في جلب تفاصيل الخطة';
        throw Exception(errorMessage);
      } else {
        throw Exception('خطأ في الشبكة: ${e.message}');
      }
    } catch (e) {
      _log('❌ Unexpected error fetching plan details: $e');
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }
}

