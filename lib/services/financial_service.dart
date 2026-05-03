import 'package:intl/intl.dart';
import '../models/payment_model.dart';

class FinancialService {
  static final NumberFormat _fmt = NumberFormat('#,##0.00');

  /// Outstanding balance = totalCost − sum(payments)
  /// Positive → client owes money; Negative → client is overpaid
  double calculateBalance(double totalCost, List<PaymentModel> payments) {
    final paid = payments.fold<double>(0.0, (sum, p) => sum + p.amount);
    return totalCost - paid;
  }

  /// Sum of all positive payment amounts
  double getTotalPaid(List<PaymentModel> payments) {
    return payments
        .where((p) => p.amount > 0)
        .fold<double>(0.0, (sum, p) => sum + p.amount);
  }

  /// Absolute sum of all negative payment amounts (refunds)
  double getTotalRefunded(List<PaymentModel> payments) {
    return payments
        .where((p) => p.amount < 0)
        .fold<double>(0.0, (sum, p) => sum + p.amount.abs());
  }

  /// Format double as GHS currency string e.g. GHS 1,234.56
  String formatCurrency(double amount) => 'GHS ${_fmt.format(amount)}';

  bool isFullyPaid(double balance) => balance <= 0.0;
  bool isOverpaid(double balance) => balance < 0.0;
}
