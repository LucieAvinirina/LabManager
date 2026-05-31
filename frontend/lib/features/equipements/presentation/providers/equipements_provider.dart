import 'package:flutter/material.dart';
import '../../data/models/equipement_model.dart';
import '../../data/repositories/equipements_repository.dart';
 
enum EquipementsStatus { initial, loading, loaded, error }
 
class EquipementsProvider extends ChangeNotifier {
  final EquipementsRepository _repository = EquipementsRepository();
 
  EquipementsStatus        _status       = EquipementsStatus.initial;
  List<EquipementModel>    _equipements  = [];
  EquipementModel?         _selected;
  String                   _errorMessage = '';
  String?                  _filterType;
  String?                  _filterStatut;
 
  // ─── Getters ──────────────────────────────────────────────
  EquipementsStatus     get status       => _status;
  List<EquipementModel> get equipements  => _equipements;
  EquipementModel?      get selected     => _selected;
  String                get errorMessage => _errorMessage;
  bool                  get isLoading    => _status == EquipementsStatus.loading;
 
  // ─── Charger tous les équipements ─────────────────────────
  Future<void> loadAll({String? type, String? statut}) async {
    _status = EquipementsStatus.loading;
    notifyListeners();
    try {
      _equipements = await _repository.getAll(
        type:   type   ?? _filterType,
        statut: statut ?? _filterStatut,
      );
      _status = EquipementsStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status       = EquipementsStatus.error;
    }
    notifyListeners();
  }
 
  // ─── Charger un équipement par ID ─────────────────────────
  Future<void> loadById(int id) async {
    _status = EquipementsStatus.loading;
    notifyListeners();
    try {
      _selected = await _repository.getById(id);
      _status   = EquipementsStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status       = EquipementsStatus.error;
    }
    notifyListeners();
  }
 
  // ─── Filtres ───────────────────────────────────────────────
  void setFilter({String? type, String? statut}) {
    _filterType   = type;
    _filterStatut = statut;
    loadAll(type: type, statut: statut);
  }
 
  void clearFilters() {
    _filterType   = null;
    _filterStatut = null;
    loadAll();
  }
 
  // ─── Changer le statut (admin) ─────────────────────────────
  Future<bool> updateStatut(int id, String statut) async {
    try {
      final updated = await _repository.updateStatut(id, statut);
      final index   = _equipements.indexWhere((e) => e.idEquipement == id);
      if (index != -1) {
        _equipements[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
 
  // ─── Modifier un équipement (admin) ───────────────────────
  Future<bool> update(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _repository.update(id, data);
      final index   = _equipements.indexWhere((e) => e.idEquipement == id);
      if (index != -1) {
        _equipements[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
 
  // ─── Créer un équipement (admin) ──────────────────────────
  Future<bool> create(Map<String, dynamic> data) async {
    try {
      final newEquipement = await _repository.create(data);
      _equipements.insert(0, newEquipement);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
 
  // ─── Supprimer (admin) ─────────────────────────────────────
  Future<bool> delete(int id) async {
    try {
      await _repository.delete(id);
      _equipements.removeWhere((e) => e.idEquipement == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}