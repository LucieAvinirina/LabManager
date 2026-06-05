import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_endpoints.dart';
import '../models/dashboard_model.dart';
 
// ─── Repository : communique avec l'API pour les données du dashboard ─────────
class DashboardRepository {
 
  // ─── Récupérer les statistiques globales du dashboard ─────
  Future<DashboardStats> getDashboardStats() async {
    final response = await ApiClient.get(AppEndpoints.dashboard);
    final data = response.data;
 
    if (data['success'] == true) {
      return DashboardStats.fromJson(data['data'] as Map<String, dynamic>);
    }
 
    throw Exception(data['message'] ?? 'Erreur lors du chargement du dashboard');
  }
 
  // ─── Récupérer les réservations en attente ─────────────────
  // GET /api/reservations?statut=En attente
  Future<List<Map<String, dynamic>>> getReservationsEnAttente() async {
    final response = await ApiClient.get(
      AppEndpoints.reservations,
      params: {'statut': 'En attente'},
    );
    final data = response.data;
 
    if (data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data'] as List);
    }
 
    throw Exception(data['message'] ?? 'Erreur lors du chargement des réservations');
  }
}
 