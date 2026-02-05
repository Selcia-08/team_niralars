import 'package:flutter/foundation.dart';
import '../models/eway_bill_model.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

/// Earnings Provider - Manages transactions and earnings
class EarningsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Transaction> _transactions = [];
  double _totalEarnings = 0;
  double _weeklyEarnings = 0;
  double _todayEarnings = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Transaction> get transactions => _transactions;
  double get totalEarnings => _totalEarnings;
  double get weeklyEarnings => _weeklyEarnings;
  double get todayEarnings => _todayEarnings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch transactions
  Future<void> fetchTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await _api.get(
        ApiConfig.transactions,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];

        if (data['transactions'] != null) {
          _transactions = (data['transactions'] as List)
              .map((t) => Transaction.fromJson(t))
              .toList();
        }

        _totalEarnings = (data['totalEarnings'] ?? 0).toDouble();
        _weeklyEarnings = (data['weeklyEarnings'] ?? 0).toDouble();
        _todayEarnings = (data['todayEarnings'] ?? 0).toDouble();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get transactions by type
  List<Transaction> getByType(String type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  /// Get total by type
  double getTotalByType(String type) {
    return getByType(type).fold(0, (sum, t) => sum + t.amount);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
