import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
 
class IncidentModel {
  final int      idIncident;
  final int      idEquipement;
  final String   equipementNom;
  final String   equipementType;
  final int      idUtilisateur;
  final String   signaleParNom;
  final String   signaleParPrenom;
  final String   description;
  final DateTime dateHeureSignalement;
  final String   statut;
  final String?  photoUrl;
  final DateTime? dateResolution;
 
  IncidentModel({
    required this.idIncident,
    required this.idEquipement,
    required this.equipementNom,
    required this.equipementType,
    required this.idUtilisateur,
    required this.signaleParNom,
    required this.signaleParPrenom,
    required this.description,
    required this.dateHeureSignalement,
    required this.statut,
    this.photoUrl,
    this.dateResolution,
  });
 
  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      idIncident:           json['id_incident']             ?? 0,
      idEquipement:         json['id_equipement']           ?? 0,
      equipementNom:        json['equipement_nom']          ?? '',
      equipementType:       json['equipement_type']         ?? '',
      idUtilisateur:        json['id_utilisateur']          ?? 0,
      signaleParNom:        json['signale_par_nom']         ?? '',
      signaleParPrenom:     json['signale_par_prenom']      ?? '',
      description:          json['description']             ?? '',
      dateHeureSignalement: DateTime.parse(json['date_heure_signalement']),
      statut:               json['statut']                  ?? 'Nouveau',
      photoUrl:             json['photo_url'],
      dateResolution: json['date_resolution'] != null
          ? DateTime.parse(json['date_resolution'])
          : null,
    );
  }
 
  // Couleur selon statut
  Color get statutColor => AppColors.getStatutIncidentColor(statut);
 
  // Nom complet du déclarant
  String get signalePar => '$signaleParPrenom $signaleParNom';
 
  // Icône selon le statut
  IconData get statutIcon {
    switch (statut) {
      case 'Nouveau':               return Icons.fiber_new;
      case 'En cours de traitement': return Icons.build_outlined;
      case 'Résolu':                return Icons.check_circle_outline;
      case 'Clôturé':               return Icons.archive_outlined;
      default:                      return Icons.warning_outlined;
    }
  }
}
 