// ─── URLs de l'API LabManager ─────────────────────────────────────────────────
class AppEndpoints {
 
  // Changer cette URL selon l'environnement
  // Pour tester sur téléphone physique : utilise l'IP de ta machine
  // ex: http://192.168.1.xx:3000/api
  static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android émulateur
  // static const String baseUrl = 'http://localhost:3000/api'; // Web
 
  // ─── Auth ─────────────────────────────────────────────────
  static const String register  = '/auth/register';
  static const String login     = '/auth/login';
  static const String fcmToken  = '/auth/fcm-token';
 
  // ─── Users ────────────────────────────────────────────────
  static const String profile         = '/users/profile';
  static const String password        = '/users/password';
  static const String users           = '/users';
 
  // ─── Équipements ──────────────────────────────────────────
  static const String equipements     = '/equipements';
 
  // ─── Réservations ─────────────────────────────────────────
  static const String reservations    = '/reservations';
  static const String historique      = '/reservations/historique';
 
  // ─── Incidents ────────────────────────────────────────────
  static const String incidents       = '/incidents';
 
  // ─── Notifications ────────────────────────────────────────
  static const String notifAll        = '/notifications/all';
  static const String notifUser       = '/notifications/user';
 
  // ─── Rapports ─────────────────────────────────────────────
  static const String dashboard       = '/rapports/dashboard';
  static const String occupation      = '/rapports/occupation';
  static const String mesStats        = '/rapports/mes-stats';
  static const String exportCsv       = '/rapports/export/csv';
}