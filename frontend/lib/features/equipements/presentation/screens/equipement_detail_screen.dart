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
      appBar: AppBar(
        title: Text(equipement.nom),
        // ─── Boutons Modifier et Supprimer (admin) ───────────
        actions: isAdmin
            ? [
                // Bouton Modifier
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Modifier',
                  onPressed: () => _showEditDialog(context),
                ),
                // Bouton Supprimer
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Supprimer',
                  onPressed: () => _showDeleteConfirmation(context),
                ),
              ]
            : null,
      ),
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
                  Icon(equipement.typeIcon, size: 64, color: equipement.statutColor),
                  const SizedBox(height: 12),
                  Text(
                    equipement.nom,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: equipement.statutColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      equipement.statut,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    _infoRow(Icons.category_outlined, 'Type', equipement.type),
                    if (equipement.numeroSerie != null)
                      _infoRow(Icons.qr_code, 'N° Série', equipement.numeroSerie!),
                    if (equipement.dateAcquisition != null)
                      _infoRow(Icons.calendar_today_outlined, 'Acquisition',
                          _formatDate(equipement.dateAcquisition!)),
                    if (equipement.description != null)
                      _infoRow(Icons.notes_outlined, 'Description', equipement.description!),
                  ],
                ),
              ),
            ),
 
            // ─── Changer statut (admin) ──────────────────────
            if (isAdmin) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Changer le statut',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                          final isCurrent = statut == equipement.statut;
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCurrent ? color : color.withOpacity(0.1),
                              foregroundColor: isCurrent ? Colors.white : color,
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: isCurrent
                                ? null
                                : () async {
                                    final success = await context
                                        .read<EquipementsProvider>()
                                        .updateStatut(equipement.idEquipement, statut);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text(success
                                            ? 'Statut mis à jour : $statut'
                                            : 'Erreur mise à jour'),
                                        backgroundColor: success ? AppColors.available : AppColors.error,
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
 
  // ─── Ligne d'information ──────────────────────────────────
  // ─── Formater la date d'acquisition lisiblement ───────────
  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2,'0')}/'
             '${dt.month.toString().padLeft(2,'0')}/'
             '${dt.year}';
    } catch (_) {
      return raw;
    }
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
                  fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
 
  // ─── Dialogue Modifier ────────────────────────────────────
  void _showEditDialog(BuildContext context) {
    final nomCtrl  = TextEditingController(text: equipement.nom);
    final typeCtrl = TextEditingController(text: equipement.type);
    final snCtrl   = TextEditingController(text: equipement.numeroSerie ?? '');
    final descCtrl = TextEditingController(text: equipement.description ?? '');
 
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Modifier l\'équipement'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  prefixIcon: Icon(Icons.computer_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: typeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Type *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: snCtrl,
                decoration: const InputDecoration(
                  labelText: 'Numéro de série',
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save_outlined),
            label: const Text('Enregistrer'),
            onPressed: () async {
              if (nomCtrl.text.isEmpty || typeCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nom et Type sont obligatoires'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
 
              final success = await context.read<EquipementsProvider>().update(
                equipement.idEquipement,
                {
                  'nom':          nomCtrl.text.trim(),
                  'type':         typeCtrl.text.trim(),
                  'numero_serie': snCtrl.text.trim(),
                  'description':  descCtrl.text.trim(),
                },
              );
 
              if (context.mounted) {
                Navigator.pop(context); // fermer dialogue
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? '✅ Équipement modifié avec succès'
                      : context.read<EquipementsProvider>().errorMessage),
                  backgroundColor: success ? AppColors.available : AppColors.error,
                ));
                if (success) Navigator.pop(context); // retour liste
              }
            },
          ),
        ],
      ),
    );
  }
 
  // ─── Dialogue Supprimer ───────────────────────────────────
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_outlined, color: AppColors.error),
            SizedBox(width: 8),
            Text('Supprimer l\'équipement'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voulez-vous vraiment supprimer "${equipement.nom}" ?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.error, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette action est irréversible. Toutes les données liées seront supprimées.',
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Supprimer'),
            onPressed: () async {
              final success = await context
                  .read<EquipementsProvider>()
                  .delete(equipement.idEquipement);
 
              if (context.mounted) {
                Navigator.pop(context); // fermer dialogue
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? '🗑️ Équipement supprimé avec succès'
                      : context.read<EquipementsProvider>().errorMessage),
                  backgroundColor: success ? AppColors.available : AppColors.error,
                ));
                if (success) Navigator.pop(context); // retour liste
              }
            },
          ),
        ],
      ),
    );
  }
}