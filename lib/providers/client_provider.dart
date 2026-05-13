import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import '../models/client_model.dart';
import '../database/db_helper.dart';
import '../constants/app_constants.dart';
import '../services/financial_service.dart';

class ClientDeleteBlockedError {
  final List<String> activeTrips;
  final List<String> unpaidTrips;

  ClientDeleteBlockedError({
    required this.activeTrips,
    required this.unpaidTrips,
  });

  bool get hasIssues => activeTrips.isNotEmpty || unpaidTrips.isNotEmpty;

  @override
  String toString() {
    final messages = <String>[];
    if (activeTrips.isNotEmpty) {
      messages.add(
        'Pending/confirmed trips must be closed first: ${activeTrips.join(', ')}',
      );
    }
    if (unpaidTrips.isNotEmpty) {
      messages.add('Outstanding balance exists for: ${unpaidTrips.join(', ')}');
    }
    return 'Cannot delete client. ${messages.join(' ')}';
  }
}

class ClientProvider extends ChangeNotifier {
  final DbHelper _db = DbHelper();
  final FinancialService _fin = FinancialService();

  List<ClientModel> _clients = [];
  bool _isLoading = false;

  List<ClientModel> get clients => List.unmodifiable(_clients);
  bool get isLoading => _isLoading;

  Future<void> loadClients() async {
    _isLoading = true;
    notifyListeners();
    _clients = await _db.getAllClients();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addClient(ClientModel client) async {
    await _db.insertClient(client);
    await loadClients();
  }

  Future<void> updateClient(ClientModel client) async {
    await _db.updateClient(client);
    await loadClients();
  }

  /// Returns [ClientDeleteBlockedError] if deletion is blocked, null on success.
  Future<ClientDeleteBlockedError?> deleteClient(int id) async {
    final trips = await _db.getTripsByClient(id);
    final activeTrips = trips
        .where(
          (t) =>
              t.status == TripStatus.pending ||
              t.status == TripStatus.confirmed,
        )
        .map((t) => t.destination)
        .toList();

    final unpaidTrips = <String>[];
    for (final trip in trips) {
      final payments = await _db.getPaymentsByTrip(trip.id!);
      final balance = _fin.calculateBalance(trip.totalCost, payments);
      if (balance > Decimal.zero) {
        unpaidTrips.add(
          '${trip.destination} (${_fin.formatCurrency(balance)})',
        );
      }
    }

    if (activeTrips.isNotEmpty || unpaidTrips.isNotEmpty) {
      return ClientDeleteBlockedError(
        activeTrips: activeTrips,
        unpaidTrips: unpaidTrips,
      );
    }

    await _db.deleteClient(id);
    await loadClients();
    return null;
  }

  ClientModel? getById(int id) {
    try {
      return _clients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
