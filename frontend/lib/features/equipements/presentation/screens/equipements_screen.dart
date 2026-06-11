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
          // ─── Bandeau alerte équipements critiques (admin) ─
          Consumer2<EquipementsProvider, AuthProvider>(
            builder: (_, eqProv, authProv, __) {
              if (!(authProv.user?.isAdmin ?? false)) return const SizedBox.shrink();
              final pannes = eqProv.equipements
                  .where((e) => e.statut == 'En panne').length;
              final maintenances = eqProv.equipements
                  .where((e) => e.statut == 'En maintenance').length;
              if (pannes == 0 && maintenances == 0) return const SizedBox.shrink();
              return _AlerteEquipementsBanner(
                  pannes: pannes, maintenances: maintenances);
            },
          ),

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
    final snCtrl   = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedType;
    DateTime? selectedDate;

    // Types d'équipements définis
    const types = [
      'ordinateur',
      'ordinateur de bureau',
      'vidéoprojecteur',
      'imprimante',
      'switch',
      'câble réseau',
      'autre',
    ];

    // Descriptions préremplies selon le type
    String descriptionPourType(String type) {
      switch (type) {
        case 'ordinateur':          return 'Poste de travail standard';
        case 'ordinateur de bureau': return 'Poste de travail fixe';
        case 'vidéoprojecteur':     return 'Vidéoprojecteur de salle';
        case 'imprimante':          return 'Imprimante partagée';
        case 'switch':              return 'Switch réseau 24 ports';
        case 'câble réseau':        return 'Câble réseau Cat6';
        default: return '';
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Ajouter un équipement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Nom ─────────────────────────────────
                TextField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    hintText:  'Ex : PC_07, Projecteur_02…',
                  ),
                ),
                const SizedBox(height: 12),

                // ─── Type (dropdown) ──────────────────────
                const Text('Type *',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  hint: const Text('Sélectionner un type'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  items: types.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t[0].toUpperCase() + t.substring(1)),
                  )).toList(),
                  onChanged: (val) {
                    setStateDialog(() {
                      selectedType = val;
                      if (val != null && descCtrl.text.isEmpty) {
                        descCtrl.text = descriptionPourType(val);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),

                // ─── Numéro de série ──────────────────────
                TextField(
                  controller: snCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de série',
                    hintText:  'Ex : SN-PC-007',
                  ),
                ),
                const SizedBox(height: 12),

                // ─── Date d'acquisition ───────────────────
                const Text('Date d\'acquisition',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context:     context, // contexte extérieur au dialog
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate:   DateTime(2000),
                      lastDate:    DateTime.now(),
                    );
                    if (picked != null) {
                      setStateDialog(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    width:   double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border:       Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          selectedDate != null
                              ? '${selectedDate!.day.toString().padLeft(2,'0')}/'
                                '${selectedDate!.month.toString().padLeft(2,'0')}/'
                                '${selectedDate!.year}'
                              : 'Choisir une date',
                          style: TextStyle(
                            color: selectedDate != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ─── Description ──────────────────────────
                TextField(
                  controller: descCtrl,
                  maxLines:   2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText:  'Détails sur l\'équipement',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              onPressed: () async {
                if (nomCtrl.text.trim().isEmpty || selectedType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Le nom et le type sont obligatoires'),
                    backgroundColor: AppColors.error,
                  ));
                  return;
                }
                final success =
                    await context.read<EquipementsProvider>().create({
                  'nom':              nomCtrl.text.trim(),
                  'type':             selectedType,
                  'numero_serie':     snCtrl.text.trim(),
                  'description':      descCtrl.text.trim(),
                  'date_acquisition': selectedDate != null
                      ? '${selectedDate!.year}-'
                        '${selectedDate!.month.toString().padLeft(2,'0')}-'
                        '${selectedDate!.day.toString().padLeft(2,'0')}'
                      : null,
                });
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success
                        ? 'Équipement ajouté avec succès !'
                        : context.read<EquipementsProvider>().errorMessage),
                    backgroundColor:
                        success ? AppColors.available : AppColors.error,
                  ));
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ─── Widget : Bandeau alerte équipements critiques ────────────────────────────
class _AlerteEquipementsBanner extends StatelessWidget {
  final int pannes;
  final int maintenances;
 
  const _AlerteEquipementsBanner({
    required this.pannes,
    required this.maintenances,
  });
 
  @override
  Widget build(BuildContext context) {
    final hasPannes      = pannes > 0;
    final hasMaint       = maintenances > 0;
    final color          = hasPannes ? AppColors.error : AppColors.warningDark;
 
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color:  color.withOpacity(0.08),
        border: Border(bottom: BorderSide(color: color.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Icon(
            hasPannes ? Icons.warning_rounded : Icons.build_circle_outlined,
            color: color,
            size:  20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPannes && hasMaint
                      ? 'Équipements critiques nécessitent votre attention'
                      : hasPannes
                          ? 'Équipements en panne détectés'
                          : 'Équipements en maintenance',
                  style: TextStyle(
                    color:      color,
                    fontWeight: FontWeight.bold,
                    fontSize:   13,
                  ),
                ),
                Text(
                  [
                    if (hasPannes)
                      '$pannes en panne',
                    if (hasMaint)
                      '$maintenances en maintenance',
                  ].join(' · '),
                  style: TextStyle(color: color, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Filtrer directement sur "En panne"
              final provider = context.read<EquipementsProvider>();
              provider.setFilter(statut: hasPannes ? 'En panne' : 'En maintenance');
            },
            style: TextButton.styleFrom(foregroundColor: color),
            child: const Text('Voir', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}