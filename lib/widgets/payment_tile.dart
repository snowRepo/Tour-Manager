import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/payment_model.dart';
import '../services/financial_service.dart';

class PaymentTile extends StatelessWidget {
  final PaymentModel payment;
  final VoidCallback? onDelete;

  const PaymentTile({super.key, required this.payment, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fin = FinancialService();
    final isRefund = payment.isRefund;
    final color = isRefund ? AppColors.error : AppColors.success;
    final dateStr = DateFormat('dd MMM yyyy · HH:mm')
        .format(DateTime.tryParse(payment.createdAt) ?? DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isRefund ? Icons.undo_rounded : Icons.payments_outlined,
            color: color,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                fin.formatCurrency(payment.amount.abs()),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                PaymentMethod.label(payment.paymentMethod),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isRefund) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'REFUND',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateStr,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            if ((payment.note ?? '').isNotEmpty)
              Text(
                payment.note!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 20),
                onPressed: onDelete,
              )
            : null,
      ),
    );
  }
}
