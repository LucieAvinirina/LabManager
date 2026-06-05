import 'package:flutter/material.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/repositories/dashboard_repository.dart';
 
// ─── États possibles du dashboard ────────────────────────────
enum DashboardStatus { initial, loading, loaded, error }
 
// ─── Provider : gestion de l'état du tableau de bord admin ───────────────────
class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repository = DashboardRepository();
 
  DashboardStatus _status = DashboardStatus.initial;
  DashboardStats? _stats;
  String          _errorMessage = '';
  bool            _isRefreshing = false;
 
  // ─── Getters ──────────────────────────────────────────────
  DashboardStatus get status       => _status;
  DashboardStats? get stats        => _stats;
  String          get errorMessage => _errorMessage;
  bool            get isLoading    => _status == DashboardStatus.loading;
  bool            get isRefreshing => _isRefreshing;
  bool            get hasData      => _stats != null;
 
  // ─── Chargement initial des stats du dashboard ────────────
  Future<void> loadDashboard() async {
    // Éviter un double chargement
    if (_status == DashboardStatus.loading) return;
 
    _status = DashboardStatus.loading;
    _errorMessage = '';
    notifyListeners();
 
    try {
      _stats  = await _repository.getDashboardStats();
      _status = DashboardStatus.loaded;
    } catch (e) {
      _status       = DashboardStatus.error;
      _errorMessage = _parseError(e);
    }
 
    notifyListeners();
  }
 
  // ─── Rafraîchissement (pull-to-refresh) ───────────────────
  Future<void> refresh() async {
    _isRefreshing = true;
    _errorMessage = '';
    notifyListeners();
 
    try {
      _stats  = await _repository.getDashboardStats();
      _status = DashboardStatus.loaded;
    } catch (e) {
      _errorMessage = _parseError(e);
      // On garde les données précédentes si le refresh échoue
    }
 
    _isRefreshing = false;
    notifyListeners();
  }
 
  // ─── Extraire un message d'erreur lisible ─────────────────
  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return 'Impossible de contacter le serveur.\nVérifiez votre connexion.';
    }
    if (msg.contains('401') || msg.contains('Unauthorized')) {
      return 'Session expirée. Reconnectez-vous.';
    }
    if (msg.contains('403') || msg.contains('Forbidden')) {
      return 'Accès non autorisé.';
    }
    return 'Erreur de chargement. Réessayez.';
  }
}