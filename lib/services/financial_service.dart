import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import '../models/payment_model.dart';

class FinancialService {
  static final NumberFormat _fmt = NumberFormat('#,##0.00');

  /// Outstanding balance = totalCost − sum(payments)
  /// Positive → client owes money; Negative → client is overpaid
  Decimal calculateBalance(Decimal totalCost, List<PaymentModel> payments) {
    final paid = payments.fold<Decimal>(
      Decimal.zero,
      (sum, p) => sum + p.amount,
    );
    return totalCost - paid;
  }

  /// Sum of all positive payment amounts
  Decimal getTotalPaid(List<PaymentModel> payments) {
    return payments
        .where((p) => p.amount > Decimal.zero)
        .fold<Decimal>(Decimal.zero, (sum, p) => sum + p.amount);
  }

  /// Absolute sum of all negative payment amounts (refunds)
  Decimal getTotalRefunded(List<PaymentModel> payments) {
    return payments
        .where((p) => p.amount < Decimal.zero)
        .fold<Decimal>(Decimal.zero, (sum, p) => sum + p.amount.abs());
  }

  /// Format decimal as GHS currency string e.g. GHS 1,234.56
  String formatCurrency(Decimal amount) =>
      'GHS ${_fmt.format(amount.toDouble())}';

  bool isFullyPaid(Decimal balance) => balance <= Decimal.zero;
  bool isOverpaid(Decimal balance) => balance < Decimal.zero;
}
