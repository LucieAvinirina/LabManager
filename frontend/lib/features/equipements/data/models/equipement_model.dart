import '../../../../core/constants/app_colors.dart';
import 'package:flutter/material.dart';
 
class EquipementModel {
  final int     idEquipement;
  final String  nom;
  final String  type;
  final String? numeroSerie;
  final String? dateAcquisition;
  final String  statut;
  final String? description;
 
  EquipementModel({
    required this.idEquipement,
    required this.nom,
    required this.type,
    this.numeroSerie,
    this.dateAcquisition,
    required this.statut,
    this.description,
  });
 
  factory EquipementModel.fromJson(Map<String, dynamic> json) {
    return EquipementModel(
      idEquipement:   json['id_equipement'] ?? 0,
      nom:            json['nom']           ?? '',
      type:           json['type']          ?? '',
      numeroSerie:    json['numero_serie'],
      dateAcquisition:json['date_acquisition'],
      statut:         json['statut']        ?? 'Disponible',
      description:    json['description'],
    );
  }
 
  // Couleur selon le statut (palette officielle du document)
  Color get statutColor => AppColors.getStatutEquipementColor(statut);
 
  // Icône selon le type
  IconData get typeIcon {
    switch (type.toLowerCase()) {
      case 'ordinateur':      return Icons.computer;
      case 'vidéoprojecteur': return Icons.videocam_outlined;
      case 'imprimante':      return Icons.print_outlined;
      case 'switch':          return Icons.device_hub_outlined;
      case 'routeur':         return Icons.router_outlined;
      case 'scanner':         return Icons.scanner_outlined;
      default:                return Icons.devices_other_outlined;
    }
  }
 
  bool get isDisponible => statut == 'Disponible';
}