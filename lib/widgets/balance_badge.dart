import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Color-coded balance badge: Paid / Partial / Outstanding / Overpaid
class BalanceBadge extends StatelessWidget {
  final Decimal balance;
  final Decimal totalCost;

  const BalanceBadge({
    super.key,
    required this.balance,
    required this.totalCost,
  });

  @override
  Widget build(BuildContext context) {
    final label = _label;
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String get _label {
    if (balance < Decimal.zero) return 'Overpaid';
    if (balance == Decimal.zero) return 'Fully Paid';
    if (balance < totalCost) return 'Partial';
    return 'Unpaid';
  }

  Color get _color {
    if (balance < Decimal.zero) return AppColors.purple;
    if (balance == Decimal.zero) return AppColors.success;
    if (balance < totalCost) return AppColors.warning;
    return AppColors.error;
  }
}
