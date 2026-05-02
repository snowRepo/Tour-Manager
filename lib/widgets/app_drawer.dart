import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/confirm_dialog.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    user?.firstName.isNotEmpty == true
                        ? user!.firstName[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? 'Admin',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user?.username ?? ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _navItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  route: AppRoutes.dashboard,
                ),
                _navItem(
                  context,
                  icon: Icons.people_rounded,
                  label: 'Clients',
                  route: AppRoutes.clients,
                ),
                _navItem(
                  context,
                  icon: Icons.flight_rounded,
                  label: 'Trips',
                  route: AppRoutes.trips,
                ),
                _navItem(
                  context,
                  icon: Icons.payment_rounded,
                  label: 'Payments',
                  route: AppRoutes.payments,
                ),
                const Divider(indent: 16, endIndent: 16),
                _navItem(
                  context,
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  route: AppRoutes.settings,
                ),
              ],
            ),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: AppColors.error,
                backgroundColor: AppColors.error.withOpacity(0.08),
              ),
              onPressed: () async {
                final confirm = await ConfirmDialog.show(
                  context,
                  title: 'Logout',
                  message: 'Are you sure you want to logout?',
                  confirmLabel: 'Logout',
                );
                if (confirm && context.mounted) {
                  context.read<AuthProvider>().logout();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (_) => false,
                  );
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final current =
        ModalRoute.of(context)?.settings.name ?? AppRoutes.dashboard;
    final isActive = current == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      selected: isActive,
      selectedTileColor: AppColors.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: () {
        Navigator.pop(context); // close drawer
        if (!isActive) Navigator.pushNamed(context, route);
      },
    );
  }
}
