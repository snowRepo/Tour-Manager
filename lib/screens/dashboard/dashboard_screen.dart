import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../database/db_helper.dart';
import '../../services/financial_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/trip_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DbHelper();
  final _fin = FinancialService();

  int _clientCount = 0;
  int _tripCount = 0;
  int _activeTrips = 0;
  Decimal _totalRevenue = Decimal.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    context.read<TripProvider>().loadAllTrips();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final clients = await _db.getAllClients();
    final trips = await _db.getTripCount();
    final active = await _db.getActiveTripCount();
    final revenue = await _db.getTotalRevenue();
    if (mounted) {
      setState(() {
        _clientCount = clients.length;
        _tripCount = trips;
        _activeTrips = active;
        _totalRevenue = revenue;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tripProv = context.watch<TripProvider>();
    final recentTrips = tripProv.trips.take(5).toList();

    // Determine a responsive aspect ratio for the stats grid
    final screenWidth = MediaQuery.of(context).size.width;
    final statsAspectRatio = screenWidth < 600 ? 1.1 : 1.4;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome, ${auth.currentUser?.firstName ?? 'there'} 👋',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _loadStats();
              context.read<TripProvider>().loadAllTrips();
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
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
          RefreshIndicator(
            onRefresh: () async {
              await _loadStats();
              await context.read<TripProvider>().loadAllTrips();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Grid
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: statsAspectRatio,
                          children: [
                            StatCard(
                              label: 'Total Clients',
                              value: '$_clientCount',
                              icon: Icons.people_rounded,
                              color: AppColors.primary,
                            ),
                            StatCard(
                              label: 'Total Trips',
                              value: '$_tripCount',
                              icon: Icons.flight_rounded,
                              color: AppColors.accent,
                            ),
                            StatCard(
                              label: 'Active Trips',
                              value: '$_activeTrips',
                              icon: Icons.pending_actions_rounded,
                              color: AppColors.warning,
                            ),
                            StatCard(
                              label: 'Revenue Collected',
                              value: _fin.formatCurrency(_totalRevenue),
                              icon: Icons.payments_rounded,
                              color: AppColors.success,
                            ),
                          ],
                        ),

                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _quickAction(
                        context,
                        label: 'Add Client',
                        icon: Icons.person_add_rounded,
                        color: AppColors.primary,
                        route: AppRoutes.addClient,
                      ),
                      const SizedBox(width: 10),
                      _quickAction(
                        context,
                        label: 'Create Trip',
                        icon: Icons.add_location_alt_rounded,
                        color: AppColors.accent,
                        route: AppRoutes.createTrip,
                      ),
                      const SizedBox(width: 10),
                      _quickAction(
                        context,
                        label: 'Settings',
                        icon: Icons.settings_rounded,
                        color: AppColors.textSecondary,
                        route: AppRoutes.settings,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Recent Trips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Trips',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.trips),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (tripProv.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (recentTrips.isEmpty)
                    _emptyCard(
                      'No trips yet. Create one!',
                      Icons.flight_rounded,
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentTrips.length,
                      itemBuilder: (_, i) {
                        final trip = recentTrips[i];
                        return TripTile(
                          trip: trip,
                          balance: trip.totalCost, // simplified on dashboard
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.tripDetail,
                            arguments: trip.id,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyCard(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.divider),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
