import 'package:flutter/material.dart';
import '../../data/models/user_admin_model.dart';
import '../../data/repositories/users_repository.dart';
 
enum UsersStatus { initial, loading, loaded, error }
 
// ─── Provider : gestion des utilisateurs côté admin ──────────────────────────
class UsersProvider extends ChangeNotifier {
  final UsersRepository _repository = UsersRepository();
 
  UsersStatus      _status       = UsersStatus.initial;
  List<UserAdminModel> _users    = [];
  UsersStatsModel? _stats;
  String           _errorMessage = '';
  String           _searchQuery  = '';
  String?          _filterRole;   // null = tous les rôles
  bool?            _filterActif;  // null = tous statuts
 
  // ─── Getters ──────────────────────────────────────────────
  UsersStatus      get status       => _status;
  String           get errorMessage => _errorMessage;
  UsersStatsModel? get stats        => _stats;
  bool             get isLoading    => _status == UsersStatus.loading;
  String           get searchQuery  => _searchQuery;
  String?          get filterRole   => _filterRole;
  bool?            get filterActif  => _filterActif;
 
  // ─── Liste filtrée + recherche (calcul en mémoire) ────────
  List<UserAdminModel> get users {
    var list = _users;
 
    // Filtre rôle
    if (_filterRole != null) {
      list = list.where((u) => u.role == _filterRole).toList();
    }
 
    // Filtre actif/inactif
    if (_filterActif != null) {
      list = list.where((u) => u.estActif == _filterActif).toList();
    }
 
    // Recherche sur nom, prénom, email
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((u) =>
        u.nom.toLowerCase().contains(q)    ||
        u.prenom.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q)
      ).toList();
    }
 
    return list;
  }
 
  // ─── Charger tous les utilisateurs + stats ────────────────
  Future<void> loadUsers() async {
    if (_status == UsersStatus.loading) return;
 
    _status = UsersStatus.loading;
    _errorMessage = '';
    notifyListeners();
 
    try {
      final results = await Future.wait([
        _repository.getAll(),
        _repository.getStats(),
      ]);
      _users  = results[0] as List<UserAdminModel>;
      _stats  = results[1] as UsersStatsModel;
      _status = UsersStatus.loaded;
    } catch (e) {
      _status       = UsersStatus.error;
      _errorMessage = _parseError(e);
    }
    notifyListeners();
  }
 
  // ─── Rafraîchir ───────────────────────────────────────────
  Future<void> refresh() async {
    _errorMessage = '';
    try {
      final results = await Future.wait([
        _repository.getAll(),
        _repository.getStats(),
      ]);
      _users  = results[0] as List<UserAdminModel>;
      _stats  = results[1] as UsersStatsModel;
      _status = UsersStatus.loaded;
    } catch (e) {
      _errorMessage = _parseError(e);
    }
    notifyListeners();
  }
 
  // ─── Recherche ────────────────────────────────────────────
  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }
 
  // ─── Filtres ──────────────────────────────────────────────
  void setFilterRole(String? role) {
    _filterRole = role;
    notifyListeners();
  }
 
  void setFilterActif(bool? actif) {
    _filterActif = actif;
    notifyListeners();
  }
 
  void clearFilters() {
    _filterRole  = null;
    _filterActif = null;
    _searchQuery = '';
    notifyListeners();
  }
 
  // ─── Modifier un utilisateur ──────────────────────────────
  Future<bool> updateUser(
    int id, {
    required String nom,
    required String prenom,
    required String email,
    required String role,
  }) async {
    try {
      final updated = await _repository.update(
        id, nom: nom, prenom: prenom, email: email, role: role,
      );
      // Mise à jour locale sans reload complet
      final idx = _users.indexWhere((u) => u.id == id);
      if (idx != -1) _users[idx] = updated;
      await _repository.getStats().then((s) => _stats = s);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }
 
  // ─── Activer / désactiver un compte ───────────────────────
  Future<bool> toggleActif(int id, {required bool estActif}) async {
    try {
      final updated = await _repository.toggleActif(id, estActif: estActif);
      final idx = _users.indexWhere((u) => u.id == id);
      if (idx != -1) _users[idx] = updated;
      await _repository.getStats().then((s) => _stats = s);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }
 
  // ─── Supprimer un utilisateur ─────────────────────────────
  Future<bool> deleteUser(int id) async {
    try {
      await _repository.delete(id);
      _users.removeWhere((u) => u.id == id);
      await _repository.getStats().then((s) => _stats = s);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }
 
  // ─── Parse erreur réseau ───────────────────────────────────
  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return 'Impossible de contacter le serveur.';
    }
    if (msg.contains('409') || msg.contains('email')) {
      return 'Cet email est déjà utilisé.';
    }
    if (msg.contains('404')) return 'Utilisateur non trouvé.';
    return 'Une erreur est survenue. Réessayez.';
  }
}