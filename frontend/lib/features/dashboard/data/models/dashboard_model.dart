// ─── Modèle des données du tableau de bord admin ─────────────────────────────
// Correspond exactement à la réponse de GET /api/rapports/dashboard
 
class DashboardStats {
  final ReservationsStats reservations;
  final EquipementsStats  equipements;
  final IncidentsStats    incidents;
  final UtilisateursStats utilisateurs;
  final int               reservationsAujourdhui;
 
  const DashboardStats({
    required this.reservations,
    required this.equipements,
    required this.incidents,
    required this.utilisateurs,
    required this.reservationsAujourdhui,
  });
 
  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      reservations: ReservationsStats.fromJson(
          json['reservations'] as Map<String, dynamic>),
      equipements: EquipementsStats.fromJson(
          json['equipements'] as Map<String, dynamic>),
      incidents: IncidentsStats.fromJson(
          json['incidents'] as Map<String, dynamic>),
      utilisateurs: UtilisateursStats.fromJson(
          json['utilisateurs'] as Map<String, dynamic>),
      reservationsAujourdhui:
          int.tryParse(json['reservations_aujourdhui'].toString()) ?? 0,
    );
  }
}
 
// ─── Réservations ─────────────────────────────────────────────
class ReservationsStats {
  final int enAttente;
  final int confirmees;
  final int annulees;
  final int terminees;
  final int total;
 
  const ReservationsStats({
    required this.enAttente,
    required this.confirmees,
    required this.annulees,
    required this.terminees,
    required this.total,
  });
 
  factory ReservationsStats.fromJson(Map<String, dynamic> json) {
    return ReservationsStats(
      enAttente:  int.tryParse(json['en_attente'].toString())  ?? 0,
      confirmees: int.tryParse(json['confirmees'].toString())  ?? 0,
      annulees:   int.tryParse(json['annulees'].toString())    ?? 0,
      terminees:  int.tryParse(json['terminees'].toString())   ?? 0,
      total:      int.tryParse(json['total'].toString())       ?? 0,
    );
  }
}
 
// ─── Équipements ──────────────────────────────────────────────
class EquipementsStats {
  final int disponibles;
  final int enUtilisation;
  final int enMaintenance;
  final int enPanne;
  final int horsService;
  final int total;
 
  const EquipementsStats({
    required this.disponibles,
    required this.enUtilisation,
    required this.enMaintenance,
    required this.enPanne,
    required this.horsService,
    required this.total,
  });
 
  factory EquipementsStats.fromJson(Map<String, dynamic> json) {
    return EquipementsStats(
      disponibles:    int.tryParse(json['disponibles'].toString())    ?? 0,
      enUtilisation:  int.tryParse(json['en_utilisation'].toString()) ?? 0,
      enMaintenance:  int.tryParse(json['en_maintenance'].toString()) ?? 0,
      enPanne:        int.tryParse(json['en_panne'].toString())       ?? 0,
      horsService:    int.tryParse(json['hors_service'].toString())   ?? 0,
      total:          int.tryParse(json['total'].toString())          ?? 0,
    );
  }
}
 
// ─── Incidents ────────────────────────────────────────────────
class IncidentsStats {
  final int nouveaux;
  final int enCours;
  final int resolus;
  final int clotures;
  final int total;
 
  const IncidentsStats({
    required this.nouveaux,
    required this.enCours,
    required this.resolus,
    required this.clotures,
    required this.total,
  });
 
  factory IncidentsStats.fromJson(Map<String, dynamic> json) {
    return IncidentsStats(
      nouveaux: int.tryParse(json['nouveaux'].toString()) ?? 0,
      enCours:  int.tryParse(json['en_cours'].toString()) ?? 0,
      resolus:  int.tryParse(json['resolus'].toString())  ?? 0,
      clotures: int.tryParse(json['clotures'].toString()) ?? 0,
      total:    int.tryParse(json['total'].toString())    ?? 0,
    );
  }
}
 
// ─── Utilisateurs ─────────────────────────────────────────────
class UtilisateursStats {
  final int etudiants;
  final int enseignants;
  final int admins;
  final int total;
 
  const UtilisateursStats({
    required this.etudiants,
    required this.enseignants,
    required this.admins,
    required this.total,
  });
 
  factory UtilisateursStats.fromJson(Map<String, dynamic> json) {
    return UtilisateursStats(
      etudiants:   int.tryParse(json['etudiants'].toString())   ?? 0,
      enseignants: int.tryParse(json['enseignants'].toString())  ?? 0,
      admins:      int.tryParse(json['admins'].toString())       ?? 0,
      total:       int.tryParse(json['total'].toString())        ?? 0,
    );
  }
}
 