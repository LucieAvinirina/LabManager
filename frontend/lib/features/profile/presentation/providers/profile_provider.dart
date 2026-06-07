import 'package:flutter/material.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository.dart';
 
enum ProfileStatus { initial, loading, loaded, error }
 
// ─── Provider : gestion de l'état du profil utilisateur ──────────────────────
class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository = ProfileRepository();
 
  ProfileStatus _status       = ProfileStatus.initial;
  ProfileModel? _profile;
  String        _errorMessage = '';
  bool          _isSaving     = false;
 
  // ─── Getters ──────────────────────────────────────────────
  ProfileStatus get status       => _status;
  ProfileModel? get profile      => _profile;
  String        get errorMessage => _errorMessage;
  bool          get isLoading    => _status == ProfileStatus.loading;
  bool          get isSaving     => _isSaving;
 
  // ─── Charger le profil ────────────────────────────────────
  Future<void> loadProfile() async {
    if (_status == ProfileStatus.loading) return;
    _status = ProfileStatus.loading;
    _errorMessage = '';
    notifyListeners();
 
    try {
      _profile = await _repository.getProfile();
      _status  = ProfileStatus.loaded;
    } catch (e) {
      _status       = ProfileStatus.error;
      _errorMessage = _parseError(e);
    }
    notifyListeners();
  }
 
  // ─── Modifier nom / prénom ────────────────────────────────
  Future<bool> updateProfile({
    required String nom,
    required String prenom,
  }) async {
    _isSaving     = true;
    _errorMessage = '';
    notifyListeners();
 
    try {
      _profile  = await _repository.updateProfile(nom: nom, prenom: prenom);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving     = false;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }
 
  // ─── Changer le mot de passe ──────────────────────────────
  Future<bool> changePassword({
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
  }) async {
    _isSaving     = true;
    _errorMessage = '';
    notifyListeners();
 
    try {
      await _repository.changePassword(
        ancienMotDePasse:  ancienMotDePasse,
        nouveauMotDePasse: nouveauMotDePasse,
      );
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving     = false;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }
 
  // ─── Reset au logout ──────────────────────────────────────
  void reset() {
    _status  = ProfileStatus.initial;
    _profile = null;
    notifyListeners();
  }
 
  // ─── Parse erreurs ────────────────────────────────────────
  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('ANCIEN_MDP_INVALIDE')) return 'Ancien mot de passe incorrect.';
    if (msg.contains('MDP_TROP_COURT'))      return 'Le mot de passe doit faire au moins 6 caractères.';
    if (msg.contains('SocketException'))     return 'Impossible de contacter le serveur.';
    return 'Une erreur est survenue. Réessayez.';
  }
}
 