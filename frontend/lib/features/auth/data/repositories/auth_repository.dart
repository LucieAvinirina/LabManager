import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_endpoints.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';
 
class AuthRepository {
 
  // ─── Connexion ────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String email,
    required String motDePasse,
  }) async {
    try {
      final response = await ApiClient.post(
        AppEndpoints.login,
        data: {
          'email':       email,
          'mot_de_passe': motDePasse,
        },
      );
 
      final data = response.data['data'];
      final user  = UserModel.fromJson(data['user']);
      final token = data['token'] as String;
 
      // Sauvegarder la session localement
      await SecureStorage.saveSession(
        token:  token,
        userId: user.id.toString(),
        role:   user.role,
        nom:    user.nom,
        prenom: user.prenom,
        email:  user.email,
      );
 
      return {'user': user, 'token': token};
 
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Erreur de connexion';
      throw Exception(message);
    }
  }
 
  // ─── Inscription ──────────────────────────────────────────
  Future<UserModel> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    String role = 'etudiant',
  }) async {
    try {
      final response = await ApiClient.post(
        AppEndpoints.register,
        data: {
          'nom':          nom,
          'prenom':       prenom,
          'email':        email,
          'mot_de_passe': motDePasse,
          'role':         role,
        },
      );
 
      return UserModel.fromJson(response.data['data']);
 
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Erreur lors de l\'inscription';
      throw Exception(message);
    }
  }
 
  // ─── Déconnexion ──────────────────────────────────────────
  Future<void> logout() async {
    await SecureStorage.clearSession();
  }
}