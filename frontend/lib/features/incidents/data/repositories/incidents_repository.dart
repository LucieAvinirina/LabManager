import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_endpoints.dart';
import '../models/incident_model.dart';
 
class IncidentsRepository {
 
  // ─── Lister tous les incidents ────────────────────────────
  Future<List<IncidentModel>> getAll({String? statut}) async {
    try {
      final params = <String, dynamic>{};
      if (statut != null) params['statut'] = statut;
 
      final response = await ApiClient.get(
        AppEndpoints.incidents,
        params: params,
      );
      final List data = response.data['data'];
      return data.map((e) => IncidentModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur chargement incidents');
    }
  }
 
  // ─── Signaler un incident ──────────────────────────────────
  Future<IncidentModel> create({
    required int    idEquipement,
    required String description,
    String?         photoUrl,
  }) async {
    try {
      final response = await ApiClient.post(
        AppEndpoints.incidents,
        data: {
          'id_equipement': idEquipement,
          'description':   description,
          if (photoUrl != null) 'photo_url': photoUrl,
        },
      );
      return IncidentModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur signalement incident');
    }
  }
 
  // ─── Mettre à jour le statut (admin) ──────────────────────
  Future<void> updateStatut(int id, String statut) async {
    try {
      await ApiClient.patch(
        '${AppEndpoints.incidents}/$id/statut',
        data: {'statut': statut},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur mise à jour statut');
    }
  }
}