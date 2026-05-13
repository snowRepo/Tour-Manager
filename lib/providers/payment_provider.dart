import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import '../models/payment_model.dart';
import '../database/db_helper.dart';
import '../services/financial_service.dart';

class PaymentProvider extends ChangeNotifier {
  final DbHelper _db = DbHelper();
  final FinancialService _fin = FinancialService();

  List<PaymentModel> _payments = [];
  bool _isLoading = false;
  int? _currentTripId;

  List<PaymentModel> get payments => List.unmodifiable(_payments);
  bool get isLoading => _isLoading;

  Future<void> loadPayments(int tripId) async {
    _currentTripId = tripId;
    _isLoading = true;
    notifyListeners();
    _payments = await _db.getPaymentsByTrip(tripId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllPayments() async {
    _currentTripId = null;
    _isLoading = true;
    notifyListeners();
    _payments = await _db.getAllPayments();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPayment(PaymentModel payment) async {
    await _db.insertPayment(payment);
    if (_currentTripId != null) {
      await loadPayments(_currentTripId!);
    }
  }

  /// Emergency delete — requires double-confirmation in UI before calling
  Future<void> deletePayment(int id) async {
    await _db.deletePayment(id);
    _payments = _payments.where((p) => p.id != id).toList();
    notifyListeners();
  }

  Decimal calculateBalance(Decimal totalCost) =>
      _fin.calculateBalance(totalCost, _payments);

  Decimal get totalPaid => _fin.getTotalPaid(_payments);
  Decimal get totalRefunded => _fin.getTotalRefunded(_payments);

  String formatCurrency(Decimal amount) => _fin.formatCurrency(amount);
}
