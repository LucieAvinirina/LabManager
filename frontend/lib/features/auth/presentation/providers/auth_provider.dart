import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/storage/secure_storage.dart';
 
// États possibles du module Auth
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }
 
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
 
  AuthStatus _status  = AuthStatus.initial;
  UserModel? _user;
  String     _errorMessage = '';
 
  // ─── Getters ──────────────────────────────────────────────
  AuthStatus get status       => _status;
  UserModel? get user         => _user;
  String     get errorMessage => _errorMessage;
  bool       get isLoading    => _status == AuthStatus.loading;
  bool       get isAuth       => _status == AuthStatus.authenticated;
 
  // ─── Vérifier la session au démarrage ────────────────────
  Future<void> checkSession() async {
    final isLoggedIn = await SecureStorage.isLoggedIn();
 
    if (isLoggedIn) {
      final nom    = await SecureStorage.getNom()    ?? '';
      final prenom = await SecureStorage.getPrenom() ?? '';
      final email  = await SecureStorage.getEmail()  ?? '';
      final role   = await SecureStorage.getRole()   ?? 'etudiant';
      final id     = await SecureStorage.getUserId() ?? '0';
 
      _user = UserModel(
        id:     int.parse(id),
        nom:    nom,
        prenom: prenom,
        email:  email,
        role:   role,
      );
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
 
  // ─── Connexion ────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String motDePasse,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = '';
    notifyListeners();
 
    try {
      final result = await _repository.login(
        email:      email,
        motDePasse: motDePasse,
      );
 
      _user   = result['user'] as UserModel;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
 
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status       = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }
 
  // ─── Inscription ──────────────────────────────────────────
  Future<bool> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    String role = 'etudiant',
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = '';
    notifyListeners();
 
    try {
      await _repository.register(
        nom:        nom,
        prenom:     prenom,
        email:      email,
        motDePasse: motDePasse,
        role:       role,
      );
 
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
 
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status       = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }
 
  // ─── Déconnexion ──────────────────────────────────────────
  Future<void> logout() async {
    await _repository.logout();
    _user   = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
 
  // ─── Réinitialiser l'erreur ───────────────────────────────
  void clearError() {
    _errorMessage = '';
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
 