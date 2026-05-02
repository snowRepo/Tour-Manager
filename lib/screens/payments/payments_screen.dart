import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/payment_provider.dart';
import '../../database/db_helper.dart';
import '../../models/trip_model.dart';
import '../../models/client_model.dart';
import '../../widgets/screen_background.dart';
import 'add_payment_screen.dart';
import 'payment_detail_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _db = DbHelper();
  final Map<int, TripModel?> _tripCache = {};
  final Map<int, ClientModel?> _clientCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().loadAllPayments();
    });
  }

  Future<void> _loadTripAndClient(int tripId) async {
    if (!_tripCache.containsKey(tripId)) {
      _tripCache[tripId] = await _db.getTripById(tripId);
      if (_tripCache[tripId] != null) {
        final clientId = _tripCache[tripId]!.clientId;
        if (!_clientCache.containsKey(clientId)) {
          _clientCache[clientId] = await _db.getClientById(clientId);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PaymentProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('All Payments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPaymentScreen()),
        ).then((_) => prov.loadAllPayments()),
        icon: const Icon(Icons.add),
        label: const Text('New Payment'),
      ),
      body: ScreenBackground(
        child: prov.isLoading
            ? const Center(child: CircularProgressIndicator())
            : prov.payments.isEmpty
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
                      'No payments recorded yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap "New Payment" to add one.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: prov.loadAllPayments,
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: prov.payments.length,
                  itemBuilder: (_, i) {
                    final payment = prov.payments[i];
                    return FutureBuilder(
                      future: _loadTripAndClient(payment.tripId),
                      builder: (context, snapshot) {
                        final trip = _tripCache[payment.tripId];
                        final client = trip != null
                            ? _clientCache[trip.clientId]
                            : null;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: payment.isRefund
                                    ? AppColors.error.withOpacity(0.1)
                                    : AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                payment.isRefund ? Icons.undo : Icons.payment,
                                color: payment.isRefund
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            ),
                            title: Text(
                              prov.formatCurrency(payment.amount.abs()),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: payment.isRefund
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client?.fullName ?? 'Unknown Client',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  trip?.destination ?? 'Unknown Trip',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  PaymentMethod.label(payment.paymentMethod),
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              _formatDate(payment.createdAt),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PaymentDetailScreen(paymentId: payment.id!),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return 'Today';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (_) {
      return 'Unknown';
    }
  }
}
