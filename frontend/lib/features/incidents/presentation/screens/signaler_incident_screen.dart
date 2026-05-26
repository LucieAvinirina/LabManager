import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/incidents_provider.dart';
import '../../../equipements/presentation/providers/equipements_provider.dart';
import '../../../equipements/data/models/equipement_model.dart';
 
class SignalerIncidentScreen extends StatefulWidget {
  const SignalerIncidentScreen({super.key});
 
  @override
  State<SignalerIncidentScreen> createState() => _SignalerIncidentScreenState();
}
 
class _SignalerIncidentScreenState extends State<SignalerIncidentScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _descCtrl     = TextEditingController();
  EquipementModel?    _selectedEquipement;
 
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipementsProvider>().loadAll();
    });
  }
 
  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
 
    if (_selectedEquipement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un équipement'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
 
    final success = await context.read<IncidentsProvider>().create(
      idEquipement: _selectedEquipement!.idEquipement,
      description:  _descCtrl.text.trim(),
    );
 
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? '✅ Incident signalé — L\'équipement est passé en panne'
            : context.read<IncidentsProvider>().errorMessage),
        backgroundColor: success ? AppColors.available : AppColors.error,
      ));
      if (success) Navigator.pop(context);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signaler un incident')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
 
              // ─── Avertissement ────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'L\'équipement passera automatiquement en statut "En panne" après signalement.',
                        style: TextStyle(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
 
              // ─── Sélection équipement ─────────────────────
              const Text('Équipement concerné *',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
 
              Consumer<EquipementsProvider>(
                builder: (_, eqProvider, __) {
                  if (eqProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
 
                  // Filtrer les équipements non hors service
                  final disponibles = eqProvider.equipements
                      .where((e) => e.statut != 'Hors service')
                      .toList();
 
                  if (disponibles.isEmpty) {
                    return const Text(
                      'Aucun équipement disponible',
                      style: TextStyle(color: AppColors.textSecondary),
                    );
                  }
 
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<EquipementModel>(
                        value: _selectedEquipement,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Sélectionner un équipement'),
                        ),
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        borderRadius: BorderRadius.circular(12),
                        items: disponibles.map((eq) {
                          return DropdownMenuItem<EquipementModel>(
                            value: eq,
                            child: Row(
                              children: [
                                Icon(eq.typeIcon,
                                    size: 20, color: eq.statutColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(eq.nom,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      Text(eq.statut,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: eq.statutColor)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (eq) =>
                            setState(() => _selectedEquipement = eq),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
 
              // ─── Description ──────────────────────────────
              const Text('Description du problème *',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines:   5,
                decoration: const InputDecoration(
                  hintText:
                      'Décrivez précisément le problème observé...',
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Description obligatoire';
                  }
                  if (val.trim().length < 10) {
                    return 'La description doit contenir au moins 10 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
 
              // ─── Bouton soumettre ─────────────────────────
              Consumer<IncidentsProvider>(
                builder: (_, provider, __) {
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    onPressed: provider.isLoading ? null : _submit,
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.warning_outlined),
                    label: const Text('Signaler l\'incident'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}