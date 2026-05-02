import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/client_model.dart';
import '../../providers/client_provider.dart';
import '../../providers/trip_provider.dart';
import '../../database/db_helper.dart';
import '../../widgets/trip_tile.dart';
import '../../widgets/confirm_dialog.dart';
import '../../services/financial_service.dart';
import '../../widgets/screen_background.dart';

class ClientDetailScreen extends StatefulWidget {
  final int clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  final _db = DbHelper();
  final _fin = FinancialService();
  ClientModel? _client;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _client = await _db.getClientById(widget.clientId);
    await context.read<TripProvider>().loadTripsByClient(widget.clientId);
    setState(() => _isLoading = false);
  }

  Future<void> _delete() async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Delete Client',
      message: 'Are you sure you want to delete ${_client?.fullName}?',
      confirmLabel: 'Delete',
    );
    if (!confirm || !context.mounted) return;
    final error = await context.read<ClientProvider>().deleteClient(
      widget.clientId,
    );
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 6),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripProv = context.watch<TripProvider>();

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Client')),
        body: const Center(child: Text('Client not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_client!.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                AppRoutes.editClient,
                arguments: _client,
              );
              if (context.mounted) _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete',
            onPressed: _delete,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.createTrip);
          if (context.mounted) _load();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Trip'),
      ),
      body: ScreenBackground(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                _infoCard(),
                const SizedBox(height: 24),

                // Trips header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trips (${tripProv.trips.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (tripProv.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (tripProv.trips.isEmpty)
                  _emptyTrips()
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tripProv.trips.length,
                    itemBuilder: (_, i) {
                      final trip = tripProv.trips[i];
                      return FutureBuilder<double>(
                        future: _db
                            .getPaymentsByTrip(trip.id!)
                            .then(
                              (payments) => _fin.calculateBalance(
                                trip.totalCost,
                                payments,
                              ),
                            ),
                        builder: (_, snap) => TripTile(
                          trip: trip,
                          balance: snap.data ?? trip.totalCost,
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              AppRoutes.tripDetail,
                              arguments: trip.id,
                            );
                            if (context.mounted) _load();
                          },
                        ),
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

  Widget _infoCard() {
    final c = _client!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              c.firstName.isNotEmpty ? c.firstName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            c.fullName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          if (c.phone.isNotEmpty) _infoRow(Icons.phone_outlined, c.phone),
          if (c.email.isNotEmpty) _infoRow(Icons.email_outlined, c.email),
          if (c.notes.isNotEmpty) _infoRow(Icons.notes_rounded, c.notes),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyTrips() {
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
          Icon(Icons.flight_outlined, size: 40, color: AppColors.divider),
          SizedBox(height: 12),
          Text(
            'No trips for this client yet.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
