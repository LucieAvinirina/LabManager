import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_endpoints.dart';
import '../models/profile_model.dart';
 
// ─── Repository : opérations sur le profil de l'utilisateur connecté ─────────
class ProfileRepository {
 
  // ─── GET /api/users/profile ────────────────────────────────
  Future<ProfileModel> getProfile() async {
    final response = await ApiClient.get(AppEndpoints.profile);
    final data = response.data;
    if (data['success'] == true) {
      return ProfileModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? 'Erreur chargement profil');
  }
 
  // ─── PUT /api/users/profile ────────────────────────────────
  Future<ProfileModel> updateProfile({
    required String nom,
    required String prenom,
  }) async {
    final response = await ApiClient.put(
      AppEndpoints.profile,
      data: {'nom': nom, 'prenom': prenom},
    );
    final data = response.data;
    if (data['success'] == true) {
      return ProfileModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? 'Erreur modification profil');
  }
 
  // ─── PUT /api/users/password ───────────────────────────────
  Future<void> changePassword({
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
  }) async {
    final response = await ApiClient.put(
      AppEndpoints.password,
      data: {
        'ancien_mot_de_passe':   ancienMotDePasse,
        'nouveau_mot_de_passe':  nouveauMotDePasse,
      },
    );
    final data = response.data;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur changement mot de passe');
    }
  }
}
 