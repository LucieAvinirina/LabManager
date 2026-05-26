import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
 
class ReservationModel {
  final int     idReservation;
  final int     idUtilisateur;
  final String  nom;
  final String  prenom;
  final String  role;
  final DateTime dateHeureDebut;
  final DateTime dateHeureFin;
  final String  statut;
  final String  typeReservation;
  final bool    estRecurrente;
  final String? frequence;
  final String? motif;
  final DateTime dateCreation;
  final List<Map<String, dynamic>> equipements;
 
  ReservationModel({
    required this.idReservation,
    required this.idUtilisateur,
    required this.nom,
    required this.prenom,
    required this.role,
    required this.dateHeureDebut,
    required this.dateHeureFin,
    required this.statut,
    required this.typeReservation,
    required this.estRecurrente,
    this.frequence,
    this.motif,
    required this.dateCreation,
    required this.equipements,
  });
 
  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      idReservation:  json['id_reservation']  ?? 0,
      idUtilisateur:  json['id_utilisateur']  ?? 0,
      nom:            json['nom']             ?? '',
      prenom:         json['prenom']          ?? '',
      role:           json['role']            ?? '',
      dateHeureDebut: DateTime.parse(json['date_heure_debut']),
      dateHeureFin:   DateTime.parse(json['date_heure_fin']),
      statut:         json['statut']          ?? 'En attente',
      typeReservation:json['type_reservation']?? 'poste',
      estRecurrente:  json['est_recurrente']  ?? false,
      frequence:      json['frequence'],
      motif:          json['motif'],
      dateCreation:   DateTime.parse(json['date_creation']),
      equipements:    List<Map<String, dynamic>>.from(json['equipements'] ?? []),
    );
  }
 
  // Couleur selon statut
  Color get statutColor => AppColors.getStatutReservationColor(statut);
 
  // Nom complet du demandeur
  String get fullName => '$prenom $nom';
 
  // Est-ce une réservation salle entière
  bool get isSalleEntiere => typeReservation == 'salle_entiere';
 
  // Durée en heures
  double get dureeHeures =>
      dateHeureFin.difference(dateHeureDebut).inMinutes / 60;
}