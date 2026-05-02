import 'package:flutter/material.dart';
import 'constants/app_constants.dart';
import 'screens/setup/welcome_screen.dart';
import 'screens/setup/setup_screen.dart';
import 'screens/setup/setup_pin_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/clients/clients_screen.dart';
import 'screens/clients/add_client_screen.dart';
import 'screens/clients/edit_client_screen.dart';
import 'screens/clients/client_detail_screen.dart';
import 'screens/trips/trips_screen.dart';
import 'screens/trips/create_trip_screen.dart';
import 'screens/trips/edit_trip_screen.dart';
import 'screens/trips/trip_detail_screen.dart';
import 'screens/payments/add_payment_screen.dart';
import 'screens/payments/payment_history_screen.dart';
import 'screens/payments/payments_screen.dart';
import 'screens/settings/settings_screen.dart';

class TourManagerApp extends StatelessWidget {
  final bool isFirstLaunch;

  const TourManagerApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: isFirstLaunch ? AppRoutes.welcome : AppRoutes.login,
      routes: {
        AppRoutes.welcome: (_) => const WelcomeScreen(),
        AppRoutes.setup: (_) => const SetupScreen(),
        AppRoutes.setupPin: (ctx) {
          final args =
              ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
          return SetupPinScreen(
            username: args['username'] as String,
            firstName: args['firstName'] as String,
            lastName: args['lastName'] as String,
            password: args['password'] as String,
          );
        },
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.resetPassword: (_) => const ResetPasswordScreen(),
        AppRoutes.dashboard: (_) => const DashboardScreen(),
        AppRoutes.clients: (_) => const ClientsScreen(),
        AppRoutes.addClient: (_) => const AddClientScreen(),
        AppRoutes.editClient: (ctx) => EditClientScreen(
          client: ModalRoute.of(ctx)!.settings.arguments as dynamic,
        ),
        AppRoutes.clientDetail: (ctx) => ClientDetailScreen(
          clientId: ModalRoute.of(ctx)!.settings.arguments as int,
        ),
        AppRoutes.trips: (_) => const TripsScreen(),
        AppRoutes.createTrip: (_) => const CreateTripScreen(),
        AppRoutes.editTrip: (ctx) => EditTripScreen(
          trip: ModalRoute.of(ctx)!.settings.arguments as dynamic,
        ),
        AppRoutes.tripDetail: (ctx) => TripDetailScreen(
          tripId: ModalRoute.of(ctx)!.settings.arguments as int,
        ),
        AppRoutes.addPayment: (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments;
          final tripId = args is int ? args : null;
          return AddPaymentScreen(tripId: tripId);
        },
        AppRoutes.payments: (_) => const PaymentsScreen(),
        AppRoutes.paymentHistory: (ctx) {
          final tripId = ModalRoute.of(ctx)!.settings.arguments as int? ?? 0;
          return PaymentHistoryScreen(tripId: tripId);
        },
        AppRoutes.settings: (_) => const SettingsScreen(),
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.divider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
