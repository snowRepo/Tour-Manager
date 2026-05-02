import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/trip_model.dart';
import '../../models/client_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/settings_provider.dart';
import '../../database/db_helper.dart';
import '../../services/pdf_service.dart';
import '../../services/financial_service.dart';
import '../../widgets/balance_badge.dart';
import '../../widgets/payment_tile.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/screen_background.dart';

class TripDetailScreen extends StatefulWidget {
  final int tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final _db = DbHelper();
  final _pdf = PdfService();
  final _fin = FinancialService();
  final _df = DateFormat('dd MMM yyyy');

  TripModel? _trip;
  ClientModel? _client;
  bool _isLoading = true;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _trip = await _db.getTripById(widget.tripId);
    if (_trip != null) {
      _client = await _db.getClientById(_trip!.clientId);
      await context.read<PaymentProvider>().loadPayments(widget.tripId);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _printAgreement() async {
    if (_trip == null || _client == null) return;
    setState(() => _isPrinting = true);
    try {
      final settings = context.read<SettingsProvider>().settings;
      final payments = context.read<PaymentProvider>().payments;
      await _pdf.printTripAgreement(
        trip: _trip!,
        client: _client!,
        payments: payments.toList(),
        settings: Map<String, String>.from(settings),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _deletePayment(int id) async {
    final first = await ConfirmDialog.show(
      context,
      title: 'Delete Payment',
      message: 'Are you sure? This action is strongly discouraged.',
      confirmLabel: 'Delete',
    );
    if (!first || !context.mounted) return;
    final second = await ConfirmDialog.show(
      context,
      title: 'Confirm Again',
      message: 'This will permanently delete the payment record. Proceed?',
      confirmLabel: 'Yes, Delete',
    );
    if (!second || !context.mounted) return;
    await context.read<PaymentProvider>().deletePayment(id);
  }

  @override
  Widget build(BuildContext context) {
    final paymentProv = context.watch<PaymentProvider>();

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip')),
        body: const Center(child: Text('Trip not found')),
      );
    }

    final balance = paymentProv.calculateBalance(_trip!.totalCost);
    final statusColor = TripStatus.color(_trip!.status);

    return Scaffold(
      appBar: AppBar(
        title: Text(_trip!.destination),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                AppRoutes.editTrip,
                arguments: _trip,
              );
              if (context.mounted) _load();
            },
          ),
        ],
      ),
      body: ScreenBackground(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trip status + destination header card
                _tripHeaderCard(statusColor),
                const SizedBox(height: 16),

                // Financial summary
                _financialCard(paymentProv, balance),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.addPayment,
                            arguments: _trip!.id,
                          );
                          if (context.mounted) _load();
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, size: 18),
                            SizedBox(width: 6),
                            Text('Add Payment'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isPrinting ? null : _printAgreement,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                        ),
                        child: _isPrinting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.print_rounded, size: 18),
                                  SizedBox(width: 6),
                                  Text('Print Agreement'),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Payment history
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment History (${paymentProv.payments.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (paymentProv.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (paymentProv.payments.isEmpty)
                  _emptyPayments()
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: paymentProv.payments.length,
                    itemBuilder: (_, i) {
                      final p = paymentProv.payments[i];
                      return PaymentTile(
                        payment: p,
                        onDelete: () => _deletePayment(p.id!),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tripHeaderCard(Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.15), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Text(
                  TripStatus.label(_trip!.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _trip!.destination,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (_client != null)
            _infoRow(Icons.person_outline, _client!.fullName),
          _infoRow(
            Icons.flight_takeoff_rounded,
            'Departs ${_df.format(DateTime.tryParse(_trip!.departureDate) ?? DateTime.now())}',
          ),
          _infoRow(
            Icons.flight_land_rounded,
            'Returns ${_df.format(DateTime.tryParse(_trip!.returnDate) ?? DateTime.now())}',
          ),
        ],
      ),
    );
  }

  Widget _financialCard(PaymentProvider prov, double balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Financial Summary',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              BalanceBadge(balance: balance, totalCost: _trip!.totalCost),
            ],
          ),
          const SizedBox(height: 16),
          _finRow('Total Cost', _fin.formatCurrency(_trip!.totalCost)),
          _finRow(
            'Total Paid',
            _fin.formatCurrency(prov.totalPaid),
            color: AppColors.success,
          ),
          if (prov.totalRefunded > 0)
            _finRow(
              'Total Refunded',
              _fin.formatCurrency(prov.totalRefunded),
              color: AppColors.error,
            ),
          const Divider(height: 20),
          _finRow(
            balance < 0 ? 'Overpaid By' : 'Outstanding Balance',
            _fin.formatCurrency(balance.abs()),
            color: balance <= 0 ? AppColors.success : AppColors.warning,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _finRow(
    String label,
    String value, {
    Color? color,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPayments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.divider),
          SizedBox(height: 12),
          Text(
            'No payments recorded yet.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
