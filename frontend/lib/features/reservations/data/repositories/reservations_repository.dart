import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_endpoints.dart';
import '../models/reservation_model.dart';
 
class ReservationsRepository {
 
  // ─── Lister les réservations ───────────────────────────────
  Future<List<ReservationModel>> getAll({String? statut, String? date}) async {
    try {
      final params = <String, dynamic>{};
      if (statut != null) params['statut'] = statut;
      if (date   != null) params['date']   = date;
 
      final response = await ApiClient.get(
        AppEndpoints.reservations,
        params: params,
      );
      final List data = response.data['data'];
      return data.map((e) => ReservationModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur chargement réservations');
    }
  }
 
  // ─── Historique personnel ──────────────────────────────────
  Future<List<ReservationModel>> getHistorique() async {
    try {
      final response = await ApiClient.get(AppEndpoints.historique);
      final List data = response.data['data'];
      return data.map((e) => ReservationModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur historique');
    }
  }
 
  // ─── Créer une réservation ─────────────────────────────────
  Future<ReservationModel> create(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.post(AppEndpoints.reservations, data: data);
      return ReservationModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur création réservation');
    }
  }
 
  // ─── Valider / Refuser (admin) ─────────────────────────────
  Future<void> valider(int id, String statut) async {
    try {
      await ApiClient.patch(
        '${AppEndpoints.reservations}/$id/valider',
        data: {'statut': statut},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur validation');
    }
  }
 
  // ─── Annuler ───────────────────────────────────────────────
  Future<void> annuler(int id) async {
    try {
      await ApiClient.patch('${AppEndpoints.reservations}/$id/annuler');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur annulation');
    }
  }
}
 