import 'package:flutter/material.dart';

// ── Colors ────────────────────────────────────────────────────────────────────
class AppColors {
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color accent = Color(0xFF66BB6A);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color purple = Color(0xFF7B1FA2);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);

  // Status chip colors
  static const Color pending = Color(0xFFF59E0B);
  static const Color confirmed = Color(0xFF3B82F6);
  static const Color completed = Color(0xFF10B981);
  static const Color cancelled = Color(0xFFEF4444);
}

// ── Route Names ───────────────────────────────────────────────────────────────
class AppRoutes {
  static const String welcome = '/welcome';
  static const String setup = '/setup';
  static const String setupPin = '/setup/pin';
  static const String login = '/login';
  static const String resetPassword = '/reset-password';
  static const String dashboard = '/dashboard';
  static const String clients = '/clients';
  static const String addClient = '/clients/add';
  static const String editClient = '/clients/edit';
  static const String clientDetail = '/clients/detail';
  static const String trips = '/trips';
  static const String createTrip = '/trips/create';
  static const String editTrip = '/trips/edit';
  static const String tripDetail = '/trips/detail';
  static const String addPayment = '/payments/add';
  static const String payments = '/payments';
  static const String paymentHistory = '/payments/history';
  static const String settings = '/settings';
}

// ── Trip Statuses ─────────────────────────────────────────────────────────────
class TripStatus {
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const List<String> all = [pending, confirmed, completed, cancelled];

  static Color color(String status) {
    switch (status) {
      case pending:
        return AppColors.pending;
      case confirmed:
        return AppColors.confirmed;
      case completed:
        return AppColors.completed;
      case cancelled:
        return AppColors.cancelled;
      default:
        return AppColors.textSecondary;
    }
  }

  static String label(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }
}

// ── Payment Methods ───────────────────────────────────────────────────────────
class PaymentMethod {
  static const String cash = 'cash';
  static const String mobileMoney = 'mobile_money';
  static const String bankTransfer = 'bank_transfer';

  static const List<String> all = [cash, mobileMoney, bankTransfer];

  static String label(String method) {
    switch (method) {
      case cash:
        return 'Cash';
      case mobileMoney:
        return 'Mobile Money';
      case bankTransfer:
        return 'Bank Transfer';
      default:
        return method;
    }
  }
}

// ── Settings Keys ─────────────────────────────────────────────────────────────
class SettingKeys {
  static const String businessName = 'business_name';
  static const String businessPhone = 'business_phone';
  static const String businessEmail = 'business_email';
  static const String businessLogo = 'business_logo';
  static const String termsAndConditions = 'terms_and_conditions';
}

// ── App Strings ───────────────────────────────────────────────────────────────
class AppStrings {
  static const String appName = 'Tour Manager';
  static const String currency = '₵';
  static const String defaultTnC =
      'By signing this agreement, the client acknowledges and accepts the terms '
      'and conditions set forth by the travel agency. All bookings are subject '
      'to availability. Cancellation policies apply. The agency is not responsible '
      'for delays or changes caused by third-party providers.';
}
