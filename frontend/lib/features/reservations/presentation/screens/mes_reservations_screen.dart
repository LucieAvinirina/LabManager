import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/reservations_provider.dart';
import '../../data/models/reservation_model.dart';
import 'planning_screen.dart';
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
      final isAdmin = context.read<AuthProvider>().user?.isAdmin ?? false;
      context.read<ReservationsProvider>().loadAll();
      context.read<ReservationsProvider>().loadHistorique(isAdmin: isAdmin);
    });
  }
 
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
 
  // ─── Formatage sécurisé des dates ─────────────────────────
  String _formatDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return 'Date invalide';
    }
  }
 
  String _formatHeure(DateTime? date) {
    if (date == null) return '--:--';
    try {
      return DateFormat('HH:mm').format(date);
    } catch (_) {
      return '--:--';
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final user    = context.read<AuthProvider>().user;
    final isAdmin = user?.isAdmin ?? false;
 
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservations'),
        actions: [
          // ─── Bouton ouvrir le calendrier interactif ──────
          IconButton(
            icon:    const Icon(Icons.calendar_month_outlined),
            tooltip: 'Voir le calendrier',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlanningScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(text: 'En cours'),
            // Admin voit "Historique global", autres voient "Mon historique"
            Tab(text: isAdmin ? 'Historique global' : 'Mon historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReservationsList(isAdmin),
          _buildHistorique(isAdmin),
        ],
      ),
 
      // ─── Bouton Réserver — visible pour TOUS les rôles ────
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_reservation',
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Réserver',
            style: TextStyle(color: Colors.white)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReservationFormScreen()),
        ),
      ),
    );
  }
 
  // ─── Liste des réservations en cours ──────────────────────
  Widget _buildReservationsList(bool isAdmin) {
    return Consumer<ReservationsProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
 
        if (provider.status == ReservationsStatus.error) {
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
 
        if (provider.reservations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_busy,
                    size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  isAdmin
                      ? 'Aucune réservation dans le système'
                      : 'Aucune réservation en cours',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
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
            itemBuilder: (_, i) {
              try {
                return _buildReservationCard(
                  provider.reservations[i],
                  isAdmin,
                  provider,
                );
              } catch (e) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Erreur affichage : $e',
                        style: const TextStyle(color: AppColors.error)),
                  ),
                );
              }
            },
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
 
            // ─── Type + badge statut ───────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      res.isSalleEntiere
                          ? Icons.meeting_room_outlined
                          : Icons.computer_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      res.isSalleEntiere
                          ? 'Salle entière'
                          : 'Poste individuel',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: res.statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: res.statutColor.withOpacity(0.3)),
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
 
            // ─── Demandeur — visible pour admin ───────────
            if (isAdmin) ...[
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${res.fullName} (${res.role})',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
 
            // ─── Dates ────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(_formatDate(res.dateHeureDebut)),
                const Text('  →  '),
                Text(_formatHeure(res.dateHeureFin)),
              ],
            ),
 
            // ─── Motif ────────────────────────────────────
            if (res.motif != null && res.motif!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.notes_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      res.motif!,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
 
            // ─── Équipements ──────────────────────────────
            if (res.equipements.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.computer_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      res.equipements
                          .map((e) => e['nom'] ?? '')
                          .join(', '),
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
 
            // ─── Actions admin (valider/refuser) ──────────
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? '✅ Réservation confirmée'
                                  : provider.errorMessage),
                              backgroundColor: ok
                                  ? AppColors.available
                                  : AppColors.error,
                            ),
                          );
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? '❌ Réservation refusée'
                                  : provider.errorMessage),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
 
            // ─── Bouton annuler (propre réservation) ──────
            if (res.statut == 'En attente') ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined,
                      color: AppColors.error, size: 16),
                  label: const Text('Annuler cette réservation',
                      style: TextStyle(color: AppColors.error)),
                  onPressed: () async {
                    final ok =
                        await provider.annuler(res.idReservation);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? '✅ Réservation annulée'
                              : provider.errorMessage),
                          backgroundColor: ok
                              ? AppColors.available
                              : AppColors.error,
                        ),
                      );
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
  Widget _buildHistorique(bool isAdmin) {
    return Consumer<ReservationsProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
 
        if (provider.historique.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history,
                    size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  isAdmin
                      ? 'Aucune réservation dans le système'
                      : 'Aucun historique personnel',
                  style:
                      const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }
 
        return RefreshIndicator(
          onRefresh: () => provider.loadHistorique(isAdmin: isAdmin),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: provider.historique.length,
            itemBuilder: (_, i) {
              final res = provider.historique[i];
              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Type + statut ─────────────────
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                res.isSalleEntiere
                                    ? Icons.meeting_room_outlined
                                    : Icons.computer_outlined,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                res.isSalleEntiere
                                    ? 'Salle entière'
                                    : 'Poste individuel',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  res.statutColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: res.statutColor
                                      .withOpacity(0.3)),
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
                      const SizedBox(height: 6),
 
                      // ─── Utilisateur (admin) ───────────
                      if (isAdmin) ...[
                        Row(
                          children: [
                            const Icon(Icons.person_outline,
                                size: 14,
                                color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${res.fullName} (${res.role})',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
 
                      // ─── Date ──────────────────────────
                      Row(
                        children: [
                          const Icon(Icons.schedule,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(res.dateHeureDebut),
                            style: const TextStyle(fontSize: 13),
                          ),
                          const Text('  →  '),
                          Text(
                            _formatHeure(res.dateHeureFin),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
 
                      // ─── Motif ─────────────────────────
                      if (res.motif != null &&
                          res.motif!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          res.motif!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}