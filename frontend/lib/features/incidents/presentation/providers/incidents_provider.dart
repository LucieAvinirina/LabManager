import 'package:flutter/material.dart';
import '../../data/models/incident_model.dart';
import '../../data/repositories/incidents_repository.dart';
 
enum IncidentsStatus { initial, loading, loaded, error }
 
class IncidentsProvider extends ChangeNotifier {
  final IncidentsRepository _repository = IncidentsRepository();
 
  IncidentsStatus      _status       = IncidentsStatus.initial;
  List<IncidentModel>  _incidents    = [];
  String               _errorMessage = '';
 
  IncidentsStatus     get status       => _status;
  List<IncidentModel> get incidents    => _incidents;
  String              get errorMessage => _errorMessage;
  bool                get isLoading    => _status == IncidentsStatus.loading;
 
  // ─── Charger les incidents ─────────────────────────────────
  Future<void> loadAll({String? statut}) async {
    _status = IncidentsStatus.loading;
    notifyListeners();
    try {
      _incidents = await _repository.getAll(statut: statut);
      _status    = IncidentsStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status       = IncidentsStatus.error;
    }
    notifyListeners();
  }
 
  // ─── Signaler un incident ──────────────────────────────────
  Future<bool> create({
    required int    idEquipement,
    required String description,
    String?         photoUrl,
  }) async {
    try {
      final newIncident = await _repository.create(
        idEquipement: idEquipement,
        description:  description,
        photoUrl:     photoUrl,
      );
      _incidents.insert(0, newIncident);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
 
  // ─── Mettre à jour le statut (admin) ──────────────────────
  Future<bool> updateStatut(int id, String statut) async {
    try {
      await _repository.updateStatut(id, statut);
      await loadAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}