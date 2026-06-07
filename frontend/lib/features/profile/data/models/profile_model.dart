// ─── Modèle profil complet — réponse de GET /api/users/profile ───────────────
// Inclut les stats (réservations, incidents) en plus des infos de base
class ProfileModel {
  final int    id;
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final String dateCreation;
  final int    totalReservations;
  final int    totalIncidents;
 
  const ProfileModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    required this.dateCreation,
    required this.totalReservations,
    required this.totalIncidents,
  });
 
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id:                json['id_utilisateur'] ?? 0,
      nom:               json['nom']            ?? '',
      prenom:            json['prenom']         ?? '',
      email:             json['email']          ?? '',
      role:              json['role']            ?? 'etudiant',
      dateCreation:      json['date_creation']?.toString() ?? '',
      totalReservations: int.tryParse(json['total_reservations'].toString()) ?? 0,
      totalIncidents:    int.tryParse(json['total_incidents'].toString())    ?? 0,
    );
  }
 
  String get fullName  => '$prenom $nom';
 
  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty    ? nom[0].toUpperCase()    : '';
    return '$p$n';
  }
 
  String get roleLabel {
    switch (role) {
      case 'admin':      return 'Administrateur';
      case 'enseignant': return 'Enseignant';
      default:           return 'Étudiant';
    }
  }
 
  // Copie avec modifications après updateProfile
  ProfileModel copyWith({String? nom, String? prenom}) {
    return ProfileModel(
      id:                id,
      nom:               nom    ?? this.nom,
      prenom:            prenom ?? this.prenom,
      email:             email,
      role:              role,
      dateCreation:      dateCreation,
      totalReservations: totalReservations,
      totalIncidents:    totalIncidents,
    );
  }
}