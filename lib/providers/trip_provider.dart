import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';
import '../database/db_helper.dart';

class TripProvider extends ChangeNotifier {
  final DbHelper _db = DbHelper();

  List<TripModel> _trips = [];
  bool _isLoading = false;

  List<TripModel> get trips => List.unmodifiable(_trips);
  bool get isLoading => _isLoading;

  Future<void> loadAllTrips() async {
    _isLoading = true;
    notifyListeners();
    _trips = await _db.getAllTrips();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTripsByClient(int clientId) async {
    _isLoading = true;
    notifyListeners();
    _trips = await _db.getTripsByClient(clientId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTrip(TripModel trip) async {
    await _db.insertTrip(trip);
    await loadAllTrips();
  }

  Future<void> updateTrip(TripModel trip) async {
    await _db.updateTrip(trip);
    // Refresh whatever list is loaded
    if (_trips.isNotEmpty && _trips.first.clientId == trip.clientId) {
      await loadTripsByClient(trip.clientId);
    } else {
      await loadAllTrips();
    }
  }

  Future<void> deleteTrip(int id) async {
    await _db.deleteTrip(id);
    _trips = _trips.where((t) => t.id != id).toList();
    notifyListeners();
  }

  TripModel? getById(int id) {
    try {
      return _trips.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
