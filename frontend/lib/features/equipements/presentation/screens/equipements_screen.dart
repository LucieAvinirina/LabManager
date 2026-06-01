import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/equipements_provider.dart';
import '../../data/models/equipement_model.dart';
import 'equipement_detail_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
 
class EquipementsScreen extends StatefulWidget {
  const EquipementsScreen({super.key});
 
  @override
  State<EquipementsScreen> createState() => _EquipementsScreenState();
}
 
class _EquipementsScreenState extends State<EquipementsScreen> {
  String? _selectedStatut;
  String? _selectedType;
 
  final List<String> _statuts = [
    'Tous', 'Disponible', 'En cours d\'utilisation',
    'En maintenance', 'En panne', 'Hors service',
  ];
 
  final List<String> _types = [
    'Tous', 'ordinateur', 'vidéoprojecteur',
    'imprimante', 'switch', 'routeur', 'scanner',
  ];
 
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipementsProvider>().loadAll();
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.equipements),
        actions: [
          // Bouton filtre
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Filtres rapides par statut ──────────────────
          _buildStatutChips(),
 
          // ─── Liste des équipements ───────────────────────
          Expanded(child: _buildList()),
        ],
      ),
 
      // ─── Bouton ajouter (admin seulement) ───────────────
      floatingActionButton: Consumer<AuthProvider>(
        builder: (_, authProvider, __) {
          if (!authProvider.user!.isAdmin) return const SizedBox();
          return FloatingActionButton(
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddDialog(context),
          );
        },
      ),
    );
  }
 
  // ─── Chips de filtre — Wrap pour éviter les coupures ──────
Widget _buildStatutChips() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _statuts.map((statut) {
        final isSelected = (statut == 'Tous' && _selectedStatut == null) ||
                           statut == _selectedStatut;

        final color = statut == 'Tous'
            ? AppColors.primary
            : AppColors.getStatutEquipementColor(statut);

        return FilterChip(
          label: Text(
            statut,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? color : AppColors.textPrimary,
              fontWeight: isSelected
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          selectedColor: color.withOpacity(0.15),
          checkmarkColor: color,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isSelected ? color : AppColors.divider,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          onSelected: (_) {
            setState(() {
              _selectedStatut = statut == 'Tous' ? null : statut;
            });
            context.read<EquipementsProvider>().setFilter(
              statut: _selectedStatut,
              type:   _selectedType,
            );
          },
        );
      }).toList(),
    ),
  );
}
  // ─── Liste des équipements ─────────────────────────────────
  Widget _buildList() {
    return Consumer<EquipementsProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
 
        if (provider.status == EquipementsStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(provider.errorMessage),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadAll(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
 
        if (provider.equipements.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.devices_other, size: 64, color: AppColors.textSecondary),
                SizedBox(height: 16),
                Text(AppStrings.aucunResultat,
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
 
        return RefreshIndicator(
          onRefresh: () => provider.loadAll(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: provider.equipements.length,
            itemBuilder: (_, index) =>
                _buildEquipementCard(provider.equipements[index]),
          ),
        );
      },
    );
  }
 
  // ─── Carte équipement ──────────────────────────────────────
  Widget _buildEquipementCard(EquipementModel eq) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: eq.statutColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(eq.typeIcon, color: eq.statutColor, size: 26),
        ),
        title: Text(
          eq.nom,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(eq.type, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            // Badge statut coloré
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: eq.statutColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: eq.statutColor.withOpacity(0.3)),
              ),
              child: Text(
                eq.statut,
                style: TextStyle(
                  color: eq.statutColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EquipementDetailScreen(equipement: eq),
            ),
          );
        },
      ),
    );
  }
 
  // ─── Dialogue filtre avancé ────────────────────────────────
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrer par type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _types.map((type) {
                return FilterChip(
                  label: Text(type),
                  selected: type == (_selectedType ?? 'Tous'),
                  onSelected: (_) {
                    setState(() => _selectedType = type == 'Tous' ? null : type);
                    context.read<EquipementsProvider>().setFilter(
                      type:   _selectedType,
                      statut: _selectedStatut,
                    );
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() { _selectedType = null; _selectedStatut = null; });
                  context.read<EquipementsProvider>().clearFilters();
                  Navigator.pop(context);
                },
                child: const Text('Réinitialiser les filtres'),
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  // ─── Dialogue ajouter équipement (admin) ───────────────────
  void _showAddDialog(BuildContext context) {
    final nomCtrl  = TextEditingController();
    final typeCtrl = TextEditingController();
    final snCtrl   = TextEditingController();
    final descCtrl = TextEditingController();
 
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter un équipement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomCtrl,
                  decoration: const InputDecoration(labelText: 'Nom *')),
              const SizedBox(height: 12),
              TextField(controller: typeCtrl,
                  decoration: const InputDecoration(labelText: 'Type *')),
              const SizedBox(height: 12),
              TextField(controller: snCtrl,
                  decoration: const InputDecoration(labelText: 'Numéro de série')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomCtrl.text.isEmpty || typeCtrl.text.isEmpty) return;
              final success = await context.read<EquipementsProvider>().create({
                'nom':         nomCtrl.text.trim(),
                'type':        typeCtrl.text.trim(),
                'numero_serie': snCtrl.text.trim(),
                'description': descCtrl.text.trim(),
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? 'Équipement ajouté !'
                      : 'Erreur : ${context.read<EquipementsProvider>().errorMessage}'),
                  backgroundColor: success ? AppColors.available : AppColors.error,
                ));
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
 