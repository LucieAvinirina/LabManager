import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/equipement_model.dart';
import '../providers/equipements_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
 
class EquipementDetailScreen extends StatelessWidget {
  final EquipementModel equipement;
  const EquipementDetailScreen({super.key, required this.equipement});
 
  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().user?.isAdmin ?? false;
 
    return Scaffold(
      appBar: AppBar(title: Text(equipement.nom)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
 
            // ─── Header avec icône et statut ────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: equipement.statutColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: equipement.statutColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(equipement.typeIcon,
                      size: 64, color: equipement.statutColor),
                  const SizedBox(height: 12),
                  Text(equipement.nom,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: equipement.statutColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      equipement.statut,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
 
            // ─── Informations ────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informations',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    _infoRow(Icons.category_outlined, 'Type', equipement.type),
                    if (equipement.numeroSerie != null)
                      _infoRow(Icons.qr_code, 'N° Série', equipement.numeroSerie!),
                    if (equipement.dateAcquisition != null)
                      _infoRow(Icons.calendar_today_outlined,
                          'Acquisition', equipement.dateAcquisition!),
                    if (equipement.description != null)
                      _infoRow(Icons.notes_outlined,
                          'Description', equipement.description!),
                  ],
                ),
              ),
            ),
 
            // ─── Changer statut (admin seulement) ───────────
            if (isAdmin) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Changer le statut',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Disponible',
                          'En maintenance',
                          'En panne',
                          'Hors service',
                        ].map((statut) {
                          final color = AppColors.getStatutEquipementColor(statut);
                          final isCurrentStatut = statut == equipement.statut;
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCurrentStatut
                                  ? color
                                  : color.withOpacity(0.1),
                              foregroundColor: isCurrentStatut
                                  ? Colors.white
                                  : color,
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onPressed: isCurrentStatut
                                ? null
                                : () async {
                                    final success = await context
                                        .read<EquipementsProvider>()
                                        .updateStatut(
                                            equipement.idEquipement, statut);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(success
                                            ? 'Statut mis à jour : $statut'
                                            : 'Erreur mise à jour'),
                                        backgroundColor: success
                                            ? AppColors.available
                                            : AppColors.error,
                                      ));
                                      if (success) Navigator.pop(context);
                                    }
                                  },
                            child: Text(statut),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
 
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text('$label : ',
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
 