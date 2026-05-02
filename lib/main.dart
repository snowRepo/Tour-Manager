import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'database/db_helper.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';
import 'providers/client_provider.dart';
import 'providers/trip_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DB (creates tables + seeds settings on first run)
  await DbHelper().database;

  // Check first-launch state
  final authService = AuthService();
  final isFirstLaunch = await authService.isFirstLaunch();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
      ],
      child: TourManagerApp(isFirstLaunch: isFirstLaunch),
    ),
  );
}
