import 'package:flutter_secure_storage/flutter_secure_storage.dart';
 
// ─── Stockage sécurisé du token JWT et infos utilisateur ─────────────────────
class SecureStorage {
  static const _storage = FlutterSecureStorage();
 
  static const _keyToken  = 'jwt_token';
  static const _keyUserId = 'user_id';
  static const _keyRole   = 'user_role';
  static const _keyNom    = 'user_nom';
  static const _keyPrenom = 'user_prenom';
  static const _keyEmail  = 'user_email';
 
  // ─── Sauvegarder après connexion ──────────────────────────
  static Future<void> saveSession({
    required String token,
    required String userId,
    required String role,
    required String nom,
    required String prenom,
    required String email,
  }) async {
    await _storage.write(key: _keyToken,  value: token);
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyRole,   value: role);
    await _storage.write(key: _keyNom,    value: nom);
    await _storage.write(key: _keyPrenom, value: prenom);
    await _storage.write(key: _keyEmail,  value: email);
  }
 
  // ─── Getters ──────────────────────────────────────────────
  static Future<String?> getToken()  async => await _storage.read(key: _keyToken);
  static Future<String?> getUserId() async => await _storage.read(key: _keyUserId);
  static Future<String?> getRole()   async => await _storage.read(key: _keyRole);
  static Future<String?> getNom()    async => await _storage.read(key: _keyNom);
  static Future<String?> getPrenom() async => await _storage.read(key: _keyPrenom);
  static Future<String?> getEmail()  async => await _storage.read(key: _keyEmail);
 
  // ─── Vérifier si connecté ─────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
 
  // ─── Supprimer la session (déconnexion) ───────────────────
  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}