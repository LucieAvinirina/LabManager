import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_endpoints.dart';
import '../models/equipement_model.dart';
 
class EquipementsRepository {
 
  // ─── Lister tous les équipements ──────────────────────────
  Future<List<EquipementModel>> getAll({String? type, String? statut}) async {
    try {
      final params = <String, dynamic>{};
      if (type   != null) params['type']   = type;
      if (statut != null) params['statut'] = statut;
 
      final response = await ApiClient.get(
        AppEndpoints.equipements,
        params: params,
      );
      final List data = response.data['data'];
      return data.map((e) => EquipementModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur chargement équipements');
    }
  }
 
  // ─── Détail d'un équipement ────────────────────────────────
  Future<EquipementModel> getById(int id) async {
    try {
      final response = await ApiClient.get('${AppEndpoints.equipements}/$id');
      return EquipementModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Équipement non trouvé');
    }
  }
 
  // ─── Créer un équipement (admin) ───────────────────────────
  Future<EquipementModel> create(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.post(AppEndpoints.equipements, data: data);
      return EquipementModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur création équipement');
    }
  }
 
  // ─── Modifier un équipement (admin) ───────────────────────
  Future<EquipementModel> update(int id, Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.put(
        '${AppEndpoints.equipements}/$id',
        data: data,
      );
      return EquipementModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur modification équipement');
    }
  }
 
  // ─── Changer le statut (admin) ─────────────────────────────
  Future<EquipementModel> updateStatut(int id, String statut) async {
    try {
      final response = await ApiClient.patch(
        '${AppEndpoints.equipements}/$id/statut',
        data: {'statut': statut},
      );
      return EquipementModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur mise à jour statut');
    }
  }
 
  // ─── Supprimer un équipement (admin) ───────────────────────
  Future<void> delete(int id) async {
    try {
      await ApiClient.delete('${AppEndpoints.equipements}/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur suppression');
    }
  }
}
 