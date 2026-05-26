import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/reservations_provider.dart';
import '../../data/models/reservation_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'reservation_form_screen.dart';
 
class MesReservationsScreen extends StatefulWidget {
  const MesReservationsScreen({super.key});
 
  @override
  State<MesReservationsScreen> createState() => _MesReservationsScreenState();
}
 
class _MesReservationsScreenState extends State<MesReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
 
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationsProvider>().loadAll();
      context.read<ReservationsProvider>().loadHistorique();
    });
  }
 
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().user?.isAdmin ?? false;
    final isEnseignant = context.read<AuthProvider>().user?.isEnseignant ?? false;
 
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservations'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'En cours'),
            Tab(text: 'Historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReservationsList(isAdmin),
          _buildHistorique(),
        ],
      ),
      floatingActionButton: (isEnseignant || !isAdmin)
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Réserver',
                  style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ReservationFormScreen()),
              ),
            )
          : null,
    );
  }
 
  // ─── Liste des réservations en cours ──────────────────────
  Widget _buildReservationsList(bool isAdmin) {
    return Consumer<ReservationsProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
 
        if (provider.reservations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_busy,
                    size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                const Text('Aucune réservation',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadAll(),
                  child: const Text('Actualiser'),
                ),
              ],
            ),
          );
        }
 
        return RefreshIndicator(
          onRefresh: () => provider.loadAll(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: provider.reservations.length,
            itemBuilder: (_, i) => _buildReservationCard(
              provider.reservations[i],
              isAdmin,
              provider,
            ),
          ),
        );
      },
    );
  }
 
  // ─── Carte réservation ─────────────────────────────────────
  Widget _buildReservationCard(
    ReservationModel res,
    bool isAdmin,
    ReservationsProvider provider,
  ) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
 
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
 
            // En-tête : nom + badge statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    res.isSalleEntiere ? '🏫 Salle entière' : '💻 Poste individuel',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: res.statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: res.statutColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    res.statut,
                    style: TextStyle(
                      color: res.statutColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
 
            // Demandeur (visible pour admin)
            if (isAdmin)
              Text('👤 ${res.fullName} (${res.role})',
                  style: const TextStyle(color: AppColors.textSecondary)),
 
            // Dates
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(fmt.format(res.dateHeureDebut)),
                const Text(' → '),
                Text(DateFormat('HH:mm').format(res.dateHeureFin)),
              ],
            ),
 
            // Motif
            if (res.motif != null && res.motif!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('📝 ${res.motif}',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
 
            // Équipements
            if (res.equipements.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '🖥️ ${res.equipements.map((e) => e['nom']).join(', ')}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
 
            // Actions admin
            if (isAdmin && res.statut == 'En attente') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.available),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Confirmer'),
                      onPressed: () async {
                        final ok = await provider.valider(
                            res.idReservation, 'Confirmée');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                ok ? '✅ Réservation confirmée' : provider.errorMessage),
                            backgroundColor:
                                ok ? AppColors.available : AppColors.error,
                          ));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Refuser'),
                      onPressed: () async {
                        final ok = await provider.valider(
                            res.idReservation, 'Annulée');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok
                                ? '❌ Réservation refusée'
                                : provider.errorMessage),
                            backgroundColor:
                                ok ? AppColors.error : AppColors.error,
                          ));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
 
            // Bouton annuler (propre réservation)
            if (res.statut == 'En attente' && !isAdmin) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined,
                      color: AppColors.error),
                  label: const Text('Annuler',
                      style: TextStyle(color: AppColors.error)),
                  onPressed: () async {
                    final ok =
                        await provider.annuler(res.idReservation);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(ok
                            ? 'Réservation annulée'
                            : provider.errorMessage),
                        backgroundColor:
                            ok ? AppColors.available : AppColors.error,
                      ));
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
 
  // ─── Historique ────────────────────────────────────────────
  Widget _buildHistorique() {
    return Consumer<ReservationsProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.historique.isEmpty) {
          return const Center(
            child: Text('Aucun historique',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.builder(
          itemCount: provider.historique.length,
          itemBuilder: (_, i) {
            final res = provider.historique[i];
            final fmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
            return Card(
              child: ListTile(
                leading: Icon(
                  res.isSalleEntiere ? Icons.meeting_room : Icons.computer,
                  color: res.statutColor,
                ),
                title: Text(fmt.format(res.dateHeureDebut)),
                subtitle: Text(res.motif ?? res.typeReservation),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: res.statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    res.statut,
                    style: TextStyle(
                        color: res.statutColor, fontSize: 11),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}