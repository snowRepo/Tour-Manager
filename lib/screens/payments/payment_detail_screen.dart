import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/client_model.dart';
import '../../models/payment_model.dart';
import '../../database/db_helper.dart';
import '../../models/trip_model.dart';
import '../../services/financial_service.dart';

class PaymentDetailScreen extends StatefulWidget {
  final int paymentId;

  const PaymentDetailScreen({super.key, required this.paymentId});

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  final _db = DbHelper();
  final _fin = FinancialService();
  PaymentModel? _payment;
  TripModel? _trip;
  ClientModel? _client;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _payment = await _db.getPaymentById(widget.paymentId);
    if (_payment != null) {
      _trip = await _db.getTripById(_payment!.tripId);
      if (_trip != null) {
        _client = await _db.getClientById(_trip!.clientId);
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_payment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Details')),
        body: const Center(child: Text('Payment not found')),
      );
    }

    final isRefund = _payment!.amount < Decimal.zero;
    final amount = _payment!.amount.abs();

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Details')),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE7F6EA), Color(0xFFF5FBF8)],
              ),
            ),
          ),
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      isRefund
                          ? Icons.undo_rounded
                          : Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    isRefund ? 'Refund Details' : 'Payment Details',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Payment date ${_formatDate(_payment!.paymentDate)}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _detailRow(
                    'Amount',
                    '${isRefund ? '-' : '+'}${_fin.formatCurrency(amount)}',
                  ),
                  const SizedBox(height: 16),
                  _detailRow('Type', isRefund ? 'Refund' : 'Payment'),
                  const SizedBox(height: 16),
                  _detailRow(
                    'Method',
                    PaymentMethod.label(_payment!.paymentMethod),
                  ),
                  const SizedBox(height: 16),
                  if ((_payment!.referenceNumber ?? '').isNotEmpty) ...[
                    _detailRow('Reference', _payment!.referenceNumber!),
                    const SizedBox(height: 16),
                  ],
                  if (_trip != null) ...[
                    _detailRow('Trip', _trip!.destination),
                    const SizedBox(height: 16),
                  ],
                  if (_client != null &&
                      _client!.passportNumber.isNotEmpty) ...[
                    _detailRow('Passport Number', _client!.passportNumber),
                    const SizedBox(height: 16),
                  ],
                  _detailRow(
                    'Payment Date',
                    _formatDate(_payment!.paymentDate),
                  ),
                  if (_payment!.note != null && _payment!.note!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Note',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _payment!.note!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return '${date.day}/${date.month}/${date.year}';
  }
}
