// ─── Modèle utilisateur côté admin — correspond à la table utilisateurs ───────
// Plus complet que UserModel (auth) : inclut est_actif, date_creation, stats
class UserAdminModel {
  final int    id;
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final bool   estActif;
  final String dateCreation;
 
  const UserAdminModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    required this.estActif,
    required this.dateCreation,
  });
 
  factory UserAdminModel.fromJson(Map<String, dynamic> json) {
    return UserAdminModel(
      id:           json['id_utilisateur'] ?? 0,
      nom:          json['nom']            ?? '',
      prenom:       json['prenom']         ?? '',
      email:        json['email']          ?? '',
      role:         json['role']           ?? 'etudiant',
      estActif:     json['est_actif']      ?? true,
      dateCreation: json['date_creation']?.toString() ?? '',
    );
  }
 
  // Nom complet
  String get fullName => '$prenom $nom';
 
  // Initiales pour l'avatar
  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty    ? nom[0].toUpperCase()    : '';
    return '$p$n';
  }
 
  // Libellé du rôle en français
  String get roleLabel {
    switch (role) {
      case 'admin':      return 'Administrateur';
      case 'enseignant': return 'Enseignant';
      case 'etudiant':   return 'Étudiant';
      default:           return role;
    }
  }
 
  // Copie avec modifications (pour les mises à jour locales)
  UserAdminModel copyWith({
    String? nom,
    String? prenom,
    String? email,
    String? role,
    bool?   estActif,
  }) {
    return UserAdminModel(
      id:           id,
      nom:          nom          ?? this.nom,
      prenom:       prenom       ?? this.prenom,
      email:        email        ?? this.email,
      role:         role         ?? this.role,
      estActif:     estActif     ?? this.estActif,
      dateCreation: dateCreation,
    );
  }
}
 
// ─── Stats globales des utilisateurs ──────────────────────────
class UsersStatsModel {
  final int etudiants;
  final int enseignants;
  final int admins;
  final int actifs;
  final int inactifs;
  final int total;
 
  const UsersStatsModel({
    required this.etudiants,
    required this.enseignants,
    required this.admins,
    required this.actifs,
    required this.inactifs,
    required this.total,
  });
 
  factory UsersStatsModel.fromJson(Map<String, dynamic> json) {
    return UsersStatsModel(
      etudiants:   int.tryParse(json['etudiants'].toString())   ?? 0,
      enseignants: int.tryParse(json['enseignants'].toString())  ?? 0,
      admins:      int.tryParse(json['admins'].toString())       ?? 0,
      actifs:      int.tryParse(json['actifs'].toString())       ?? 0,
      inactifs:    int.tryParse(json['inactifs'].toString())     ?? 0,
      total:       int.tryParse(json['total'].toString())        ?? 0,
    );
  }
}