// ─── Modèle utilisateur — correspond exactement à la table utilisateurs en BDD
class UserModel {
  final int    id;
  final String nom;
  final String prenom;
  final String email;
  final String role;
 
  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
  });
 
  // Depuis JSON (réponse API)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:     json['id']     ?? json['id_utilisateur'] ?? 0,
      nom:    json['nom']    ?? '',
      prenom: json['prenom'] ?? '',
      email:  json['email']  ?? '',
      role:   json['role']   ?? 'etudiant',
    );
  }
 
  // Vers JSON
  Map<String, dynamic> toJson() => {
    'id':     id,
    'nom':    nom,
    'prenom': prenom,
    'email':  email,
    'role':   role,
  };
 
  // Vérifications de rôle
  bool get isAdmin      => role == 'admin';
  bool get isEnseignant => role == 'enseignant';
  bool get isEtudiant   => role == 'etudiant';
 
  // Nom complet
  String get fullName => '$prenom $nom';
}
 