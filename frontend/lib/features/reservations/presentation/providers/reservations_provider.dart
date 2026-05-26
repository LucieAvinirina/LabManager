import 'package:flutter/material.dart';
import '../../data/models/reservation_model.dart';
import '../../data/repositories/reservations_repository.dart';
 
enum ReservationsStatus { initial, loading, loaded, error }
 
class ReservationsProvider extends ChangeNotifier {
  final ReservationsRepository _repository = ReservationsRepository();
 
  ReservationsStatus        _status       = ReservationsStatus.initial;
  List<ReservationModel>    _reservations = [];
  List<ReservationModel>    _historique   = [];
  String                    _errorMessage = '';
 
  ReservationsStatus     get status       => _status;
  List<ReservationModel> get reservations => _reservations;
  List<ReservationModel> get historique   => _historique;
  String                 get errorMessage => _errorMessage;
  bool                   get isLoading    => _status == ReservationsStatus.loading;
 
  // ─── Charger les réservations ──────────────────────────────
  Future<void> loadAll({String? statut, String? date}) async {
    _status = ReservationsStatus.loading;
    notifyListeners();
    try {
      _reservations = await _repository.getAll(statut: statut, date: date);
      _status = ReservationsStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status       = ReservationsStatus.error;
    }
    notifyListeners();
  }
 
  // ─── Charger l'historique ──────────────────────────────────
  Future<void> loadHistorique() async {
    _status = ReservationsStatus.loading;
    notifyListeners();
    try {
      _historique = await _repository.getHistorique();
      _status     = ReservationsStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status       = ReservationsStatus.error;
    }
    notifyListeners();
  }
 
  // ─── Créer une réservation ─────────────────────────────────
  Future<bool> create(Map<String, dynamic> data) async {
    try {
      final newRes = await _repository.create(data);
      _reservations.insert(0, newRes);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
 
  // ─── Valider (admin) ───────────────────────────────────────
  Future<bool> valider(int id, String statut) async {
    try {
      await _repository.valider(id, statut);
      await loadAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
 
  // ─── Annuler ───────────────────────────────────────────────
  Future<bool> annuler(int id) async {
    try {
      await _repository.annuler(id);
      await loadAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
 