import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/trip_provider.dart';
import '../../providers/client_provider.dart';
import '../../database/db_helper.dart';
import '../../services/financial_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/screen_background.dart';
import '../../widgets/trip_tile.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final _db = DbHelper();
  final _fin = FinancialService();
  String _statusFilter = 'all';
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().loadAllTrips();
      context.read<ClientProvider>().loadClients();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripProv = context.watch<TripProvider>();
    final clientProv = context.watch<ClientProvider>();

    final filtered = tripProv.trips.where((t) {
      final matchStatus = _statusFilter == 'all' || t.status == _statusFilter;
      final matchQuery =
          _query.isEmpty ||
          t.destination.toLowerCase().contains(_query.toLowerCase());
      return matchStatus && matchQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Trips')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.createTrip);
          if (context.mounted) context.read<TripProvider>().loadAllTrips();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Trip'),
      ),
      body: ScreenBackground(
        child: Column(
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SearchBar(
                controller: _searchCtrl,
                hintText: 'Search destinations...',
                leading: const Icon(Icons.search_rounded),
                trailing: _query.isNotEmpty
                    ? [
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                      ]
                    : null,
                onChanged: (v) => setState(() => _query = v),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),

            // Status filter chips
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _chip('All', 'all'),
                  _chip('Pending', TripStatus.pending),
                  _chip('Confirmed', TripStatus.confirmed),
                  _chip('Completed', TripStatus.completed),
                  _chip('Cancelled', TripStatus.cancelled),
                ],
              ),
            ),

            // Trip list
            Expanded(
              child: tripProv.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      onRefresh: () =>
                          context.read<TripProvider>().loadAllTrips(),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final trip = filtered[i];
                          final client = clientProv.getById(trip.clientId);
                          return FutureBuilder<double>(
                            future: _db
                                .getPaymentsByTrip(trip.id!)
                                .then(
                                  (p) =>
                                      _fin.calculateBalance(trip.totalCost, p),
                                ),
                            builder: (_, snap) => TripTile(
                              trip: trip,
                              clientName: client?.fullName ?? '',
                              balance: snap.data ?? trip.totalCost,
                              onTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  AppRoutes.tripDetail,
                                  arguments: trip.id,
                                );
                                if (context.mounted) {
                                  context.read<TripProvider>().loadAllTrips();
                                }
                              },
                            ),
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

  Widget _chip(String label, String value) {
    final isActive = _statusFilter == value;
    final color = value == 'all' ? AppColors.primary : TripStatus.color(value);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) => setState(() => _statusFilter = value),
        selectedColor: color.withOpacity(0.15),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isActive ? color : AppColors.textSecondary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isActive ? color.withOpacity(0.5) : AppColors.divider,
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flight_outlined, size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text(
            _query.isNotEmpty || _statusFilter != 'all'
                ? 'No trips match your filters'
                : 'No trips yet. Create one!',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
