import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/trip_model.dart';
import '../services/financial_service.dart';

class TripTile extends StatelessWidget {
  final TripModel trip;
  final String clientName;
  final double balance;
  final VoidCallback? onTap;

  const TripTile({
    super.key,
    required this.trip,
    this.clientName = '',
    required this.balance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = TripStatus.color(trip.status);
    final fin = FinancialService();
    final dateStr =
        DateFormat('dd MMM yyyy').format(DateTime.tryParse(trip.departureDate) ??
            DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.flight_takeoff_rounded,
              color: statusColor, size: 22),
        ),
        title: Text(
          trip.destination,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (clientName.isNotEmpty)
              Text(
                clientName,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            Text(
              dateStr,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Status chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                TripStatus.label(trip.status),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Balance
            Text(
              fin.formatCurrency(balance.abs()),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: balance <= 0
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
