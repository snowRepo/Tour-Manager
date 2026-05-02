import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/trip_model.dart';
import '../../providers/trip_provider.dart';
import '../../providers/client_provider.dart';
import '../../models/client_model.dart';
import '../../database/db_helper.dart';

class EditTripScreen extends StatefulWidget {
  final TripModel trip;
  const EditTripScreen({super.key, required this.trip});

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _destinationCtrl;
  late final TextEditingController _costCtrl;

  ClientModel? _selectedClient;
  late DateTime _departureDate;
  late DateTime _returnDate;
  late String _status;
  bool _isLoading = false;
  bool _hasPayments = false;

  final _df = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    final t = widget.trip;
    _destinationCtrl = TextEditingController(text: t.destination);
    _costCtrl = TextEditingController(text: t.totalCost.toStringAsFixed(2));
    _departureDate = DateTime.tryParse(t.departureDate) ?? DateTime.now();
    _returnDate = DateTime.tryParse(t.returnDate) ?? DateTime.now();
    _status = t.status;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<ClientProvider>().loadClients();
      final clients = context.read<ClientProvider>().clients;
      setState(() {
        _selectedClient = clients.firstWhere(
          (c) => c.id == widget.trip.clientId,
          orElse: () => clients.isNotEmpty ? clients.first : ClientModel(
            firstName: '', lastName: '', createdAt: '', updatedAt: ''),
        );
      });
      final payments = await DbHelper().getPaymentsByTrip(t.id!);
      setState(() => _hasPayments = payments.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _destinationCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isDeparture) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDeparture ? _departureDate : _returnDate,
      firstDate: isDeparture ? DateTime.now() : _departureDate,
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (isDeparture) {
        _departureDate = picked;
        if (_returnDate.isBefore(picked)) _returnDate = picked;
      } else {
        _returnDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final newCost = double.parse(_costCtrl.text.replaceAll(',', ''));
    if (_hasPayments && newCost != widget.trip.totalCost) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cost Changed'),
          content: const Text(
            'This trip already has payments. Changing the total cost will affect the outstanding balance. Continue?',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isLoading = true);
    final updated = widget.trip.copyWith(
      clientId: _selectedClient?.id ?? widget.trip.clientId,
      destination: _destinationCtrl.text.trim(),
      departureDate: _departureDate.toIso8601String(),
      returnDate: _returnDate.toIso8601String(),
      totalCost: newCost,
      status: _status,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await context.read<TripProvider>().updateTrip(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip updated'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = context.watch<ClientProvider>().clients;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Trip')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<ClientModel>(
                initialValue: _selectedClient,
                decoration: const InputDecoration(
                  labelText: 'Client *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: clients
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.fullName),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedClient = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destinationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Destination *',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _datePicker('Departure', _departureDate, true)),
                  const SizedBox(width: 12),
                  Expanded(child: _datePicker('Return', _returnDate, false)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Total Cost *',
                  prefixText: '₵ ',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final p = double.tryParse(v.replaceAll(',', ''));
                  if (p == null || p <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: TripStatus.all
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(TripStatus.label(s)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _datePicker(String label, DateTime date, bool isDeparture) {
    return InkWell(
      onTap: () => _pickDate(isDeparture),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(_df.format(date),
            style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
