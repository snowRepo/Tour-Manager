import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/payment_provider.dart';
import '../../database/db_helper.dart';
import '../../models/trip_model.dart';
import '../../services/financial_service.dart';
import '../../widgets/payment_tile.dart';
import '../../widgets/balance_badge.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/screen_background.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final int tripId;
  const PaymentHistoryScreen({super.key, required this.tripId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final _db = DbHelper();
  final _fin = FinancialService();
  TripModel? _trip;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _trip = await _db.getTripById(widget.tripId);
    await context.read<PaymentProvider>().loadPayments(widget.tripId);
    setState(() => _isLoading = false);
  }

  Future<void> _deletePayment(int id) async {
    final first = await ConfirmDialog.show(
      context,
      title: 'Delete Payment',
      message: 'Are you sure? Payments are meant to be immutable.',
      confirmLabel: 'Delete',
    );
    if (!first || !context.mounted) return;
    final second = await ConfirmDialog.show(
      context,
      title: 'Final Confirmation',
      message: 'This will permanently delete this payment record.',
      confirmLabel: 'Yes, Delete',
    );
    if (!second || !context.mounted) return;
    await context.read<PaymentProvider>().deletePayment(id);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PaymentProvider>();

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final balance = _trip != null
        ? prov.calculateBalance(_trip!.totalCost)
        : Decimal.zero;

    return Scaffold(
      appBar: AppBar(title: Text(_trip?.destination ?? 'Payment History')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          AppRoutes.addPayment,
        ).then((_) => _load()),
        icon: const Icon(Icons.add),
        label: const Text('New Payment'),
      ),
      body: ScreenBackground(
        child: Column(
          children: [
            // Summary banner
            if (_trip != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Outstanding Balance',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fin.formatCurrency(balance.abs()),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    BalanceBadge(balance: balance, totalCost: _trip!.totalCost),
                  ],
                ),
              ),

            // List
            Expanded(
              child: prov.payments.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 56,
                            color: AppColors.divider,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No payments recorded.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: prov.payments.length,
                        itemBuilder: (_, i) {
                          final p = prov.payments[i];
                          return PaymentTile(
                            payment: p,
                            onDelete: () => _deletePayment(p.id!),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
