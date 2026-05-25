import 'package:flutter/material.dart';
 
// ─── Palette officielle LabManager (définie dans l'analyse des besoins) ───────
class AppColors {
 
  // ─── Couleurs principales ────────────────────────────────
  static const Color primaryDark   = Color(0xFF1A3A5C); // Bleu nuit
  static const Color primary       = Color(0xFF2E6DA4); // Bleu moyen
  static const Color primaryLight  = Color(0xFF378ADD); // Bleu clair
 
  // ─── Couleurs sémantiques (statuts) ──────────────────────
  static const Color available     = Color(0xFF1D9E75); // Vert émeraude → Disponible
  static const Color warning       = Color(0xFFBA7517); // Ambre → En attente
  static const Color warningDark   = Color(0xFF854F0B); // Ambre foncé → En maintenance
  static const Color error         = Color(0xFFA32D2D); // Rouge → En panne / Erreur
  static const Color disabled      = Color(0xFF888780); // Gris neutre → Hors service
  static const Color cancelled     = Color(0xFF444441); // Gris foncé → Annulé
 
  // ─── Couleurs neutres ────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1A1A1A); // Noir texte
  static const Color textSecondary = Color(0xFF888780); // Gris
  static const Color background    = Color(0xFFF5F7FA); // Fond gris clair
  static const Color white         = Color(0xFFFFFFFF);
  static const Color cardBg        = Color(0xFFFFFFFF);
  static const Color divider       = Color(0xFFE0E0E0);
 
  // ─── Couleurs de statut équipements ──────────────────────
  static Color getStatutEquipementColor(String statut) {
    switch (statut) {
      case 'Disponible':             return available;
      case 'En cours d\'utilisation': return primaryLight;
      case 'En maintenance':         return warningDark;
      case 'En panne':               return error;
      case 'Hors service':           return disabled;
      default:                       return disabled;
    }
  }
 
  // ─── Couleurs de statut réservation ──────────────────────
  static Color getStatutReservationColor(String statut) {
    switch (statut) {
      case 'Confirmée':   return available;
      case 'En attente':  return warning;
      case 'Annulée':     return cancelled;
      case 'Terminée':    return disabled;
      default:            return disabled;
    }
  }
 
  // ─── Couleurs de statut incident ─────────────────────────
  static Color getStatutIncidentColor(String statut) {
    switch (statut) {
      case 'Nouveau':               return error;
      case 'En cours de traitement': return warning;
      case 'Résolu':                return available;
      case 'Clôturé':               return disabled;
      default:                      return disabled;
    }
  }
}