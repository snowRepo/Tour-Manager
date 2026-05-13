import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/trip_model.dart';
import '../../providers/trip_provider.dart';
import '../../providers/client_provider.dart';
import '../../models/client_model.dart';
import '../../widgets/app_banner.dart';
import '../../widgets/screen_background.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _clientSearchCtrl = TextEditingController();

  ClientModel? _selectedClient;
  List<ClientModel> _filteredClients = [];
  bool _showClientDropdown = false;
  DateTime? _departureDate;
  DateTime? _returnDate;
  String _status = TripStatus.pending;
  bool _isLoading = false;

  final _df = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().loadClients();
    });
  }

  @override
  void dispose() {
    _destinationCtrl.dispose();
    _costCtrl.dispose();
    _clientSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isDeparture) async {
    final now = DateTime.now();
    final initial = isDeparture
        ? (_departureDate ?? now)
        : (_returnDate ?? (_departureDate ?? now));
    final first = isDeparture ? now : (_departureDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (isDeparture) {
        _departureDate = picked;
        if (_returnDate != null && _returnDate!.isBefore(picked)) {
          _returnDate = null;
        }
      } else {
        _returnDate = picked;
      }
    });
  }

  void _filterClients(String query) {
    final clients = context.read<ClientProvider>().clients;
    setState(() {
      _selectedClient = null;
      _filteredClients = clients
          .where(
            (c) =>
                c.fullName.toLowerCase().contains(query.toLowerCase()) ||
                c.phone.contains(query) ||
                c.email.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
      _showClientDropdown = query.trim().isNotEmpty;
    });
  }

  void _selectClient(ClientModel client) {
    setState(() {
      _selectedClient = client;
      _clientSearchCtrl.text = client.fullName;
      _showClientDropdown = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a client')));
      return;
    }
    if (_departureDate == null || _returnDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please pick both dates')));
      return;
    }

    setState(() => _isLoading = true);
    final now = DateTime.now().toIso8601String();
    final trip = TripModel(
      clientId: _selectedClient!.id!,
      destination: _destinationCtrl.text.trim(),
      departureDate: _departureDate!.toIso8601String(),
      returnDate: _returnDate!.toIso8601String(),
      totalCost: Decimal.parse(_costCtrl.text.replaceAll(',', '')),
      status: _status,
      createdAt: now,
      updatedAt: now,
    );
    await context.read<TripProvider>().addTrip(trip);
    if (mounted) {
      showAppBanner(
        context,
        'Trip created',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_outline,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Trip')),
      body: ScreenBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Client search
                TextFormField(
                  controller: _clientSearchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Client *',
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Search client name, phone, or email',
                  ),
                  onChanged: _filterClients,
                  validator: (v) =>
                      _selectedClient == null ? 'Select a client' : null,
                ),
                if (_showClientDropdown)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: _filteredClients.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('No clients found.'),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredClients.length,
                            itemBuilder: (context, index) {
                              final client = _filteredClients[index];
                              return ListTile(
                                title: Text(client.fullName),
                                subtitle: Text(
                                  '${client.phone} • ${client.email}',
                                ),
                                onTap: () => _selectClient(client),
                              );
                            },
                          ),
                  ),
                if (_selectedClient != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedClient!.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Destination
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

                // Dates
                Row(
                  children: [
                    Expanded(
                      child: _datePicker(
                        'Departure Date *',
                        _departureDate,
                        true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _datePicker('Return Date *', _returnDate, false),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Total Cost
                TextFormField(
                  controller: _costCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Total Cost *',
                    prefixText: 'GHS ',
                    prefixIcon: Icon(Icons.currency_exchange),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final parsed = Decimal.tryParse(v.replaceAll(',', ''));
                    if (parsed == null || parsed <= Decimal.zero) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Status
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: TripStatus.all
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(TripStatus.label(s)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _status = v ?? TripStatus.pending),
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
                      : const Text('Create Trip'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _datePicker(String label, DateTime? date, bool isDeparture) {
    return InkWell(
      onTap: () => _pickDate(isDeparture),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          date != null ? _df.format(date) : 'Tap to select',
          style: TextStyle(
            color: date != null
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
