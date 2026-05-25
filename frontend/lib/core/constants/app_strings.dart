// ─── Textes de l'application ─────────────────────────────────────────────────
class AppStrings {
  static const String appName       = 'LabManager';
  static const String appSubtitle   = 'Gestion de laboratoire informatique';
 
  // Auth
  static const String login         = 'Connexion';
  static const String register      = 'Inscription';
  static const String email         = 'Email institutionnel';
  static const String password      = 'Mot de passe';
  static const String nom           = 'Nom';
  static const String prenom        = 'Prénom';
  static const String logout        = 'Déconnexion';
 
  // Navigation
  static const String home          = 'Accueil';
  static const String equipements   = 'Équipements';
  static const String reservations  = 'Réservations';
  static const String incidents     = 'Incidents';
  static const String profil        = 'Profil';
 
  // Statuts équipements
  static const String disponible       = 'Disponible';
  static const String enUtilisation    = 'En cours d\'utilisation';
  static const String enMaintenance    = 'En maintenance';
  static const String enPanne          = 'En panne';
  static const String horsService      = 'Hors service';
 
  // Statuts réservations
  static const String enAttente     = 'En attente';
  static const String confirmee     = 'Confirmée';
  static const String annulee       = 'Annulée';
  static const String terminee      = 'Terminée';
 
  // Messages
  static const String erreurServeur = 'Erreur serveur. Réessayez plus tard.';
  static const String chargement    = 'Chargement...';
  static const String aucunResultat = 'Aucun résultat';
}
 