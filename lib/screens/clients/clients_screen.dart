import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/client_provider.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/client_tile.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/app_banner.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().loadClients();
      context.read<TripProvider>().loadAllTrips();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientProv = context.watch<ClientProvider>();
    final tripProv = context.watch<TripProvider>();

    final filtered = clientProv.clients.where((c) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return c.fullName.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.addClient);
          if (context.mounted) context.read<ClientProvider>().loadClients();
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Client'),
      ),
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
          Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SearchBar(
                  controller: _searchCtrl,
                  hintText: 'Search clients...',
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

              // List
              Expanded(
                child: clientProv.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                    ? _empty(
                        _query.isEmpty
                            ? 'No clients yet. Tap + to add one.'
                            : 'No clients match "$_query"',
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            context.read<ClientProvider>().loadClients(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final client = filtered[i];
                            final tripCount = tripProv.trips
                                .where((t) => t.clientId == client.id)
                                .length;
                            return ClientTile(
                              client: client,
                              tripCount: tripCount,
                              onTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  AppRoutes.clientDetail,
                                  arguments: client.id,
                                );
                                if (context.mounted) {
                                  context.read<ClientProvider>().loadClients();
                                }
                              },
                              onEdit: () async {
                                await Navigator.pushNamed(
                                  context,
                                  AppRoutes.editClient,
                                  arguments: client,
                                );
                                if (context.mounted) {
                                  context.read<ClientProvider>().loadClients();
                                }
                              },
                              onDelete: () =>
                                  _deleteClient(context, client.id!),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClient(BuildContext context, int id) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Delete Client',
      message:
          'Are you sure you want to delete this client? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirm || !context.mounted) return;

    final error = await context.read<ClientProvider>().deleteClient(id);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      showAppBanner(
        context,
        'Client deleted',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_outline,
      );
    }
  }

  Widget _empty(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text(
            msg,
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
