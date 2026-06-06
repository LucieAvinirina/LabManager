import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_endpoints.dart';
import '../models/user_admin_model.dart';
 
// ─── Repository : toutes les opérations admin sur les utilisateurs ────────────
class UsersRepository {
 
  // ─── GET /api/users?role=...&est_actif=... ─────────────────
  Future<List<UserAdminModel>> getAll({String? role, bool? estActif}) async {
    final params = <String, dynamic>{};
    if (role != null)      params['role']      = role;
    if (estActif != null)  params['est_actif'] = estActif;
 
    final response = await ApiClient.get(AppEndpoints.users, params: params);
    final data = response.data;
 
    if (data['success'] == true) {
      return (data['data'] as List)
          .map((u) => UserAdminModel.fromJson(u as Map<String, dynamic>))
          .toList();
    }
    throw Exception(data['message'] ?? 'Erreur chargement utilisateurs');
  }
 
  // ─── GET /api/users/stats ──────────────────────────────────
  Future<UsersStatsModel> getStats() async {
    final response = await ApiClient.get('${AppEndpoints.users}/stats');
    final data = response.data;
 
    if (data['success'] == true) {
      return UsersStatsModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? 'Erreur chargement stats');
  }
 
  // ─── GET /api/users/:id ────────────────────────────────────
  Future<UserAdminModel> getById(int id) async {
    final response = await ApiClient.get('${AppEndpoints.users}/$id');
    final data = response.data;
 
    if (data['success'] == true) {
      return UserAdminModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? 'Utilisateur non trouvé');
  }
 
  // ─── PUT /api/users/:id ────────────────────────────────────
  Future<UserAdminModel> update(
    int id, {
    required String nom,
    required String prenom,
    required String email,
    required String role,
  }) async {
    final response = await ApiClient.put(
      '${AppEndpoints.users}/$id',
      data: {'nom': nom, 'prenom': prenom, 'email': email, 'role': role},
    );
    final data = response.data;
 
    if (data['success'] == true) {
      return UserAdminModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? 'Erreur modification utilisateur');
  }
 
  // ─── PATCH /api/users/:id/actif ────────────────────────────
  Future<UserAdminModel> toggleActif(int id, {required bool estActif}) async {
    final response = await ApiClient.patch(
      '${AppEndpoints.users}/$id/actif',
      data: {'est_actif': estActif},
    );
    final data = response.data;
 
    if (data['success'] == true) {
      return UserAdminModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? 'Erreur changement statut');
  }
 
  // ─── DELETE /api/users/:id ─────────────────────────────────
  Future<void> delete(int id) async {
    final response = await ApiClient.delete('${AppEndpoints.users}/$id');
    final data = response.data;
 
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur suppression utilisateur');
    }
  }
}