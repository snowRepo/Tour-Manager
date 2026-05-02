import 'package:flutter/foundation.dart';
import '../models/client_model.dart';
import '../database/db_helper.dart';
import '../constants/app_constants.dart';

class ClientDeleteBlockedError {
  final List<String> blockingDestinations;
  ClientDeleteBlockedError(this.blockingDestinations);

  @override
  String toString() =>
      'Cannot delete — ${blockingDestinations.length} active trip(s) must be '
      'completed or cancelled first: ${blockingDestinations.join(', ')}';
}

class ClientProvider extends ChangeNotifier {
  final DbHelper _db = DbHelper();

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
    final blocking = trips
        .where((t) =>
            t.status == TripStatus.pending ||
            t.status == TripStatus.confirmed)
        .map((t) => t.destination)
        .toList();

    if (blocking.isNotEmpty) {
      return ClientDeleteBlockedError(blocking);
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
