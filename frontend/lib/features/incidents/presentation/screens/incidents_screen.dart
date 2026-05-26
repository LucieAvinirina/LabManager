import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/incidents_provider.dart';
import '../../data/models/incident_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'signaler_incident_screen.dart';
 
class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});
 
  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}
 
class _IncidentsScreenState extends State<IncidentsScreen> {
  String? _selectedStatut;
 
  final List<String> _statuts = [
    'Tous',
    'Nouveau',
    'En cours de traitement',
    'Résolu',
    'Clôturé',
  ];
 
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentsProvider>().loadAll();
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidents'),
      ),
      body: Column(
        children: [
          // ─── Chips de filtre ─────────────────────────────
          _buildFilterChips(),
 
          // ─── Liste des incidents ──────────────────────────
          Expanded(child: _buildList()),
        ],
      ),
 
      // ─── Bouton signaler ──────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.error,
        icon: const Icon(Icons.warning_outlined, color: Colors.white),
        label: const Text('Signaler', style: TextStyle(color: Colors.white)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignalerIncidentScreen()),
        ),
      ),
    );
  }
 
  // ─── Chips filtre statut ───────────────────────────────────
  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: _statuts.map((statut) {
          final isSelected = statut == 'Tous'
              ? _selectedStatut == null
              : statut == _selectedStatut;
 
          final color = statut == 'Tous'
              ? AppColors.primary
              : AppColors.getStatutIncidentColor(statut);
 
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(statut),
              selected: isSelected,
              selectedColor: color.withOpacity(0.2),
              checkmarkColor: color,
              onSelected: (_) {
                setState(() {
                  _selectedStatut = statut == 'Tous' ? null : statut;
                });
                context.read<IncidentsProvider>().loadAll(
                  statut: _selectedStatut,
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
 
  // ─── Liste des incidents ───────────────────────────────────
  Widget _buildList() {
    return Consumer<IncidentsProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
 
        if (provider.status == IncidentsStatus.error) {
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
 
        if (provider.incidents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: AppColors.available),
                SizedBox(height: 16),
                Text('Aucun incident signalé',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
 
        return RefreshIndicator(
          onRefresh: () => provider.loadAll(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: provider.incidents.length,
            itemBuilder: (_, i) =>
                _buildIncidentCard(provider.incidents[i], provider),
          ),
        );
      },
    );
  }
 
  // ─── Carte incident ────────────────────────────────────────
  Widget _buildIncidentCard(IncidentModel incident, IncidentsProvider provider) {
    final fmt     = DateFormat('dd/MM/yyyy HH:mm');
    final isAdmin = context.read<AuthProvider>().user?.isAdmin ?? false;
 
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
 
            // En-tête
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(incident.statutIcon,
                        color: incident.statutColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      incident.equipementNom,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: incident.statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: incident.statutColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    incident.statut,
                    style: TextStyle(
                      color: incident.statutColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
 
            // Description
            Text(incident.description,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
 
            // Infos
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(incident.signalePar,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 12),
                const Icon(Icons.access_time,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  fmt.format(incident.dateHeureSignalement),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
 
            // Date résolution si disponible
            if (incident.dateResolution != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 14, color: AppColors.available),
                  const SizedBox(width: 4),
                  Text(
                    'Résolu le ${fmt.format(incident.dateResolution!)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.available),
                  ),
                ],
              ),
            ],
 
            // Actions admin
            if (isAdmin && incident.statut != 'Clôturé') ...[
              const SizedBox(height: 12),
              const Divider(),
              const Text('Mettre à jour le statut :',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _getNextStatuts(incident.statut).map((statut) {
                  final color = AppColors.getStatutIncidentColor(statut);
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () async {
                      final ok = await provider.updateStatut(
                          incident.idIncident, statut);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok
                              ? 'Statut mis à jour : $statut'
                              : provider.errorMessage),
                          backgroundColor:
                              ok ? AppColors.available : AppColors.error,
                        ));
                      }
                    },
                    child: Text(statut,
                        style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
 
  // ─── Statuts suivants selon statut actuel ──────────────────
  List<String> _getNextStatuts(String current) {
    switch (current) {
      case 'Nouveau':
        return ['En cours de traitement'];
      case 'En cours de traitement':
        return ['Résolu'];
      case 'Résolu':
        return ['Clôturé'];
      default:
        return [];
    }
  }
}