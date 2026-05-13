import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/trip_provider.dart';
import '../../database/db_helper.dart';
import '../../models/trip_model.dart';
import '../../models/client_model.dart';
import '../../services/financial_service.dart';
import '../../widgets/app_banner.dart';
import '../../widgets/screen_background.dart';

class AddPaymentScreen extends StatefulWidget {
  final int? tripId;
  const AddPaymentScreen({super.key, this.tripId});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _clientSearchCtrl = TextEditingController();
  final _paymentDateCtrl = TextEditingController();
  final _db = DbHelper();
  final _fin = FinancialService();

  String _method = PaymentMethod.cash;
  DateTime? _paymentDate;
  bool _isLoading = false;
  TripModel? _trip;
  ClientModel? _selectedClient;
  TripModel? _selectedTrip;
  Decimal _currentBalance = Decimal.zero;
  List<ClientModel> _filteredClients = [];
  bool _showClientDropdown = false;

  @override
  void initState() {
    super.initState();
    if (widget.tripId != null) {
      _loadTrip();
    } else {
      _loadClients();
    }
  }

  Future<void> _loadTrip() async {
    _trip = await _db.getTripById(widget.tripId!);
    final payments = await _db.getPaymentsByTrip(widget.tripId!);
    setState(() {
      _currentBalance = _fin.calculateBalance(
        _trip?.totalCost ?? Decimal.zero,
        payments,
      );
    });
  }

  Future<void> _loadClients() async {
    final clients = await _db.getAllClients();
    setState(() {
      _filteredClients = clients;
    });
  }

  void _filterClients(String query) {
    final clients = context.read<ClientProvider>().clients;
    setState(() {
      _filteredClients = clients
          .where(
            (c) =>
                c.fullName.toLowerCase().contains(query.toLowerCase()) ||
                c.phone.contains(query) ||
                c.email.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
      _showClientDropdown = query.isNotEmpty;
    });
  }

  Future<void> _selectClient(ClientModel client) async {
    setState(() {
      _selectedClient = client;
      _clientSearchCtrl.text = client.fullName;
      _showClientDropdown = false;
      _selectedTrip = null;
    });
    await context.read<TripProvider>().loadTripsByClient(client.id!);
  }

  void _selectTrip(TripModel trip) {
    setState(() {
      _selectedTrip = trip;
    });
    _loadTripBalance(trip.id!);
  }

  Future<void> _loadTripBalance(int tripId) async {
    final payments = await _db.getPaymentsByTrip(tripId);
    setState(() {
      _currentBalance = _fin.calculateBalance(
        _selectedTrip?.totalCost ?? Decimal.zero,
        payments,
      );
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _noteCtrl.dispose();
    _clientSearchCtrl.dispose();
    _paymentDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPaymentDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _paymentDate = picked;
      _paymentDateCtrl.text = '${picked.day}/${picked.month}/${picked.year}';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final tripId = widget.tripId ?? _selectedTrip?.id;
    if (tripId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a trip')));
      return;
    }

    final shouldRequireReference =
        _method == PaymentMethod.mobileMoney ||
        _method == PaymentMethod.bankTransfer;
    if (shouldRequireReference && _referenceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reference number is required for the selected payment method',
          ),
        ),
      );
      return;
    }
    if (_paymentDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment date')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final amount = Decimal.parse(_amountCtrl.text.replaceAll(',', ''));
    final payment = PaymentModel(
      tripId: tripId,
      amount: amount,
      paymentMethod: _method,
      referenceNumber: _referenceCtrl.text.trim().isEmpty
          ? null
          : _referenceCtrl.text.trim(),
      paymentDate: _paymentDate!.toIso8601String(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );
    await context.read<PaymentProvider>().addPayment(payment);
    if (mounted) {
      showAppBanner(
        context,
        amount < Decimal.zero ? 'Refund recorded' : 'Payment recorded',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_outline,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripProv = context.watch<TripProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tripId != null
              ? (_trip != null
                    ? 'Add Payment — ${_trip!.destination}'
                    : 'Add Payment')
              : 'Add Payment',
        ),
      ),
      body: ScreenBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client and Trip selection (only when tripId is null)
              if (widget.tripId == null) ...[
                // Client search
                TextFormField(
                  controller: _clientSearchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Search Client *',
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Type name, phone, or email',
                  ),
                  onChanged: _filterClients,
                ),
                if (_showClientDropdown && _filteredClients.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredClients.length,
                      itemBuilder: (context, index) {
                        final client = _filteredClients[index];
                        return ListTile(
                          title: Text(client.fullName),
                          subtitle: Text('${client.phone} • ${client.email}'),
                          onTap: () => _selectClient(client),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),

                // Selected client info
                if (_selectedClient != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedClient!.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Trip selection
                if (_selectedClient != null) ...[
                  DropdownButtonFormField<TripModel>(
                    initialValue: _selectedTrip,
                    decoration: const InputDecoration(
                      labelText: 'Select Trip *',
                      prefixIcon: Icon(Icons.flight),
                    ),
                    items: tripProv.trips
                        .map(
                          (trip) => DropdownMenuItem(
                            value: trip,
                            child: Text(
                              '${trip.destination} (${_fin.formatCurrency(trip.totalCost)})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (trip) =>
                        trip != null ? _selectTrip(trip) : null,
                    validator: (v) => v == null ? 'Select a trip' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // Current balance info banner
                if (_trip != null || _selectedTrip != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          (_currentBalance <= Decimal.zero
                                  ? AppColors.success
                                  : AppColors.warning)
                              .withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            (_currentBalance <= Decimal.zero
                                    ? AppColors.success
                                    : AppColors.warning)
                                .withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Outstanding Balance',
                          style: TextStyle(
                            fontSize: 12,
                            color: _currentBalance <= Decimal.zero
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fin.formatCurrency(_currentBalance.abs()) +
                              (_currentBalance < Decimal.zero
                                  ? ' (overpaid)'
                                  : ''),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _currentBalance <= Decimal.zero
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (_trip != null || _selectedTrip != null)
                const SizedBox(height: 24),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount *',
                        prefixText: 'GHS ',
                        prefixIcon: Icon(Icons.currency_exchange),
                        helperText: 'Enter negative amount for a refund',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final p = Decimal.tryParse(v.replaceAll(',', ''));
                        if (p == null || p == Decimal.zero)
                          return 'Enter a non-zero amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Method
                    DropdownButtonFormField<String>(
                      initialValue: _method,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        prefixIcon: Icon(Icons.payment_rounded),
                      ),
                      items: PaymentMethod.all
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(PaymentMethod.label(m)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _method = v ?? _method),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickPaymentDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _paymentDateCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Payment Date *',
                            prefixIcon: Icon(Icons.calendar_month_outlined),
                            hintText: 'Select payment date',
                          ),
                          validator: (v) => _paymentDate == null
                              ? 'Please select a payment date'
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _referenceCtrl,
                      decoration: InputDecoration(
                        labelText: _method == PaymentMethod.cash
                            ? 'Reference Number (optional)'
                            : 'Reference Number *',
                        prefixIcon: const Icon(
                          Icons.confirmation_number_outlined,
                        ),
                      ),
                      validator: (v) {
                        final isRequired = _method != PaymentMethod.cash;
                        if (isRequired && (v == null || v.trim().isEmpty)) {
                          return 'Reference number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Note
                    TextFormField(
                      controller: _noteCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        prefixIcon: Icon(Icons.notes_rounded),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 32),

                    FilledButton(
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Record Payment'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
