import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/reservations_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../equipements/data/models/equipement_model.dart';
import '../../../equipements/presentation/providers/equipements_provider.dart';
 
class ReservationFormScreen extends StatefulWidget {
  const ReservationFormScreen({super.key});
 
  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}
 
class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _motifCtrl = TextEditingController();
 
  DateTime? _dateDebut;
  DateTime? _dateFin;
  String    _typeReservation = 'poste';
  bool      _estRecurrente   = false;
  List<int> _selectedIds     = [];
 
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipementsProvider>().loadAll(statut: 'Disponible');
    });
  }
 
  @override
  void dispose() {
    _motifCtrl.dispose();
    super.dispose();
  }
 
  // ─── Sélectionner date + heure ────────────────────────────
  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !context.mounted) return null;
 
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (time == null) return null;
 
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
 
  // ─── Soumettre ────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
 
    if (_dateDebut == null || _dateFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez choisir les dates'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
 
    if (_dateFin!.isBefore(_dateDebut!) ||
        _dateFin!.isAtSameMomentAs(_dateDebut!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date de fin doit être après la date de début'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
 
    if (_typeReservation == 'poste' && _selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez au moins un équipement'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
 
    final data = <String, dynamic>{
      'date_heure_debut': _dateDebut!.toIso8601String(),
      'date_heure_fin':   _dateFin!.toIso8601String(),
      'type_reservation': _typeReservation,
      'est_recurrente':   _estRecurrente,
      'motif':            _motifCtrl.text.trim(),
    };
 
    if (_typeReservation == 'poste') {
      data['ids_equipements'] = _selectedIds;
    }
    if (_estRecurrente) {
      data['frequence'] = 'hebdomadaire';
    }
 
    final success = await context.read<ReservationsProvider>().create(data);
 
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? '✅ Réservation soumise — En attente de validation'
            : context.read<ReservationsProvider>().errorMessage),
        backgroundColor: success ? AppColors.available : AppColors.error,
      ));
      if (success) Navigator.pop(context);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final user         = context.read<AuthProvider>().user;
    final isEnseignant = user?.isEnseignant ?? false;
    final isAdmin      = user?.isAdmin      ?? false;
    final fmt          = DateFormat('dd/MM/yyyy HH:mm');
 
    // Admin et enseignant peuvent réserver la salle entière
    final canReserveSalle = isEnseignant || isAdmin;
 
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle réservation')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
 
              // ─── Type de réservation ──────────────────────
              if (canReserveSalle) ...[
                const Text('Type de réservation',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _typeButton('poste', '💻 Poste individuel')),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _typeButton(
                            'salle_entiere', '🏫 Salle entière')),
                  ],
                ),
                const SizedBox(height: 16),
              ],
 
              // ─── Date début ───────────────────────────────
              const Text('Date et heure de début *',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final dt = await _pickDateTime(context);
                  if (dt != null) setState(() => _dateDebut = dt);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(_dateDebut == null
                          ? 'Choisir la date de début'
                          : fmt.format(_dateDebut!)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
 
              // ─── Date fin ─────────────────────────────────
              const Text('Date et heure de fin *',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final dt = await _pickDateTime(context);
                  if (dt != null) setState(() => _dateFin = dt);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(_dateFin == null
                          ? 'Choisir la date de fin'
                          : fmt.format(_dateFin!)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
 
              // ─── Sélection équipements (si poste) ─────────
              if (_typeReservation == 'poste') ...[
                const Text('Équipements disponibles *',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Consumer<EquipementsProvider>(
                  builder: (_, eqProvider, __) {
                    if (eqProvider.isLoading) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
 
                    final ordinateurs = eqProvider.equipements
                        .where((e) =>
                            e.type == 'ordinateur' ||
                            e.type == 'ordinateur de bureau')
                        .toList();
 
                    if (ordinateurs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Aucun ordinateur disponible actuellement',
                          style: TextStyle(color: AppColors.warning),
                        ),
                      );
                    }
 
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ordinateurs.map((eq) {
                        final selected =
                            _selectedIds.contains(eq.idEquipement);
                        return FilterChip(
                          label: Text(eq.nom),
                          selected: selected,
                          selectedColor:
                              AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                          avatar: Icon(eq.typeIcon,
                              size: 16,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary),
                          onSelected: (_) {
                            setState(() {
                              if (selected) {
                                _selectedIds.remove(eq.idEquipement);
                              } else {
                                _selectedIds.add(eq.idEquipement);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
 
              // ─── Motif ────────────────────────────────────
              TextFormField(
                controller: _motifCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motif (optionnel)',
                  prefixIcon: Icon(Icons.notes_outlined),
                  hintText: 'Ex: Projet de fin d\'études, TP Réseau...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
 
              // ─── Récurrence (enseignant + admin) ──────────
              if (canReserveSalle) ...[
                Card(
                  child: SwitchListTile(
                    title: const Text('Réservation récurrente'),
                    subtitle:
                        const Text('Se répète chaque semaine même créneau'),
                    value: _estRecurrente,
                    activeColor: AppColors.primary,
                    secondary: const Icon(Icons.repeat,
                        color: AppColors.primary),
                    onChanged: (val) =>
                        setState(() => _estRecurrente = val),
                  ),
                ),
                const SizedBox(height: 16),
              ],
 
              // ─── Info admin ───────────────────────────────
              if (isAdmin) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'En tant qu\'admin, votre réservation sera confirmée automatiquement.',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
 
              // ─── Bouton soumettre ─────────────────────────
              Consumer<ReservationsProvider>(
                builder: (_, provider, __) {
                  return ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : _submit,
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Soumettre la réservation'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  // ─── Bouton type réservation ───────────────────────────────
  Widget _typeButton(String value, String label) {
    final selected = _typeReservation == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _typeReservation = value;
          _selectedIds     = []; // Reset sélection
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:         selected ? AppColors.primary : Colors.white,
          borderRadius:  BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color:      selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}