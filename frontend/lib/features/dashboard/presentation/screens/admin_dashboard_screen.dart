import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../data/models/dashboard_model.dart';
import 'home_screen.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// AdminDashboardScreen — Tableau de bord admin avec données réelles de l'API
// Appelle GET /api/rapports/dashboard au chargement
// ─────────────────────────────────────────────────────────────────────────────
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
 
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}
 
class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les stats au premier affichage (après le build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }
 
  @override
  Widget build(BuildContext context) {
    final user            = context.watch<AuthProvider>().user;
    final dashboardProv   = context.watch<DashboardProvider>();
 
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          // ─── Bouton rafraîchir ──────────────────────────
          if (dashboardProv.isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Rafraîchir',
              onPressed: () => context.read<DashboardProvider>().refresh(),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<DashboardProvider>().refresh(),
        child: _buildBody(context, dashboardProv, user?.prenom ?? ''),
      ),
    );
  }
 
  // ─── Corps principal selon l'état ─────────────────────────
  Widget _buildBody(
    BuildContext context,
    DashboardProvider prov,
    String prenom,
  ) {
    switch (prov.status) {
 
      // ─── Chargement initial ────────────────────────────
      case DashboardStatus.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Chargement du tableau de bord…',
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        );
 
      // ─── Erreur ────────────────────────────────────────
      case DashboardStatus.error:
        return ListView(
          // ListView pour que RefreshIndicator fonctionne
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        prov.errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 15),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => prov.loadDashboard(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
 
      // ─── Données disponibles ───────────────────────────
      case DashboardStatus.loaded:
        return _buildDashboard(context, prov.stats!, prenom);
 
      // ─── État initial (ne devrait pas durer) ───────────
      case DashboardStatus.initial:
        return const SizedBox.shrink();
    }
  }
 
  // ─── Dashboard complet avec données réelles ───────────────
  Widget _buildDashboard(
    BuildContext context,
    DashboardStats stats,
    String prenom,
  ) {
    final now = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now());
 
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
 
          // ─── En-tête Bonjour ──────────────────────────
          _buildHeader(context, prenom, now, stats.reservationsAujourdhui),
          const SizedBox(height: 20),
 
          // ─── Alertes urgentes (si en attente ou incidents) ──
          if (stats.reservations.enAttente > 0 ||
              stats.incidents.nouveaux > 0)
            _buildAlertes(context, stats),
 
          const SizedBox(height: 4),
 
          // ─── Titre section stats ──────────────────────
          _sectionTitle('Vue d\'ensemble'),
          const SizedBox(height: 12),
 
          // ─── Grille 4 cartes de stats ─────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              _StatCard(
                icon:   Icons.computer,
                label:  'Équipements',
                value:  stats.equipements.total,
                sublabel: '${stats.equipements.disponibles} disponibles',
                color:  AppColors.primary,
                onTap:  () => _navigateTo(context, 1),
              ),
              _StatCard(
                icon:   Icons.event,
                label:  'Réservations',
                value:  stats.reservations.total,
                sublabel: '${stats.reservations.enAttente} en attente',
                color:  AppColors.available,
                onTap:  () => _navigateTo(context, 2),
              ),
              _StatCard(
                icon:   Icons.warning_outlined,
                label:  'Incidents',
                value:  stats.incidents.total,
                sublabel: '${stats.incidents.nouveaux} nouveaux',
                color:  AppColors.error,
                onTap:  () => _navigateTo(context, 3),
              ),
              _StatCard(
                icon:   Icons.people_outline,
                label:  'Utilisateurs',
                value:  stats.utilisateurs.total,
                sublabel: '${stats.utilisateurs.etudiants} étudiants',
                color:  AppColors.warning,
                onTap:  () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
 
          // ─── Détail équipements ───────────────────────
          _sectionTitle('État des équipements'),
          const SizedBox(height: 12),
          _EquipementsDetail(stats: stats.equipements),
          const SizedBox(height: 24),
 
          // ─── Détail réservations ──────────────────────
          _sectionTitle('Réservations'),
          const SizedBox(height: 12),
          _ReservationsDetail(stats: stats.reservations),
          const SizedBox(height: 24),
 
          // ─── Actions rapides ──────────────────────────
          _sectionTitle('Actions rapides'),
          const SizedBox(height: 12),
          _buildActionsRapides(context, stats),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
 
  // ─── En-tête avec salutation et date ──────────────────────
  Widget _buildHeader(
    BuildContext context,
    String prenom,
    String date,
    int reservationsAujourdhui,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.white.withOpacity(0.2),
                child: Text(
                  prenom.isNotEmpty ? prenom[0].toUpperCase() : 'A',
                  style: const TextStyle(
                      color: AppColors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, $prenom 👋',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.today, color: AppColors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  reservationsAujourdhui == 0
                      ? "Aucune réservation confirmée aujourd'hui"
                      : '$reservationsAujourdhui réservation${reservationsAujourdhui > 1 ? 's' : ''} confirmée${reservationsAujourdhui > 1 ? 's' : ''} aujourd\'hui',
                  style: const TextStyle(
                      color: AppColors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  // ─── Alertes urgentes ─────────────────────────────────────
  Widget _buildAlertes(BuildContext context, DashboardStats stats) {
    return Column(
      children: [
        if (stats.reservations.enAttente > 0)
          _AlertBanner(
            icon:    Icons.pending_actions,
            message: '${stats.reservations.enAttente} réservation${stats.reservations.enAttente > 1 ? 's' : ''} en attente de validation',
            color:   AppColors.warning,
            onTap:   () => _navigateTo(context, 2),
          ),
        if (stats.incidents.nouveaux > 0)
          _AlertBanner(
            icon:    Icons.warning_amber,
            message: '${stats.incidents.nouveaux} nouvel incident${stats.incidents.nouveaux > 1 ? 's' : ''} non traité${stats.incidents.nouveaux > 1 ? 's' : ''}',
            color:   AppColors.error,
            onTap:   () => _navigateTo(context, 3),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
 
  // ─── Actions rapides ──────────────────────────────────────
  Widget _buildActionsRapides(BuildContext context, DashboardStats stats) {
    return Column(
      children: [
        _ActionTile(
          icon:   Icons.pending_actions,
          label:  'Réservations en attente',
          badge:  stats.reservations.enAttente,
          color:  AppColors.warning,
          onTap:  () => _navigateTo(context, 2),
        ),
        _ActionTile(
          icon:   Icons.build_outlined,
          label:  'Incidents non résolus',
          badge:  stats.incidents.nouveaux + stats.incidents.enCours,
          color:  AppColors.error,
          onTap:  () => _navigateTo(context, 3),
        ),
        _ActionTile(
          icon:   Icons.computer_outlined,
          label:  'Gérer les équipements',
          badge:  stats.equipements.enPanne + stats.equipements.enMaintenance,
          color:  AppColors.primary,
          onTap:  () => _navigateTo(context, 1),
        ),
      ],
    );
  }
 
  // ─── Navigation vers un onglet de la BottomNav ────────────
  void _navigateTo(BuildContext context, int tabIndex) {
    final homeState = context.findAncestorStateOfType<HomeScreenState>();
    homeState?.navigateTo(tabIndex);
  }
 
  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
  );
}
 
// ─── Widget : Bannière d'alerte urgente ───────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final String   message;
  final Color    color;
  final VoidCallback onTap;
 
  const _AlertBanner({
    required this.icon,
    required this.message,
    required this.color,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
 
// ─── Widget : Carte statistique avec valeur ───────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final int      value;
  final String   sublabel;
  final Color    color;
  final VoidCallback onTap;
 
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:        color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
              ],
            ),
            const Spacer(),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize:   26,
                fontWeight: FontWeight.bold,
                color:      color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                color:      AppColors.textPrimary,
              ),
            ),
            Text(
              sublabel,
              style: const TextStyle(
                fontSize: 11,
                color:    AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ─── Widget : Détail de la répartition équipements ───────────────────────────
class _EquipementsDetail extends StatelessWidget {
  final EquipementsStats stats;
 
  const _EquipementsDetail({required this.stats});
 
  @override
  Widget build(BuildContext context) {
    final items = [
      _StatusRow('Disponibles',         stats.disponibles,   AppColors.available),
      _StatusRow('En cours utilisation', stats.enUtilisation, AppColors.primaryLight),
      _StatusRow('En maintenance',       stats.enMaintenance, AppColors.warningDark),
      _StatusRow('En panne',             stats.enPanne,       AppColors.error),
      _StatusRow('Hors service',         stats.horsService,   AppColors.disabled),
    ];
 
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildStatusRow(items[i], stats.total),
            if (i < items.length - 1) const Divider(height: 16),
          ],
        ],
      ),
    );
  }
 
  Widget _buildStatusRow(_StatusRow item, int total) {
    final pct = total > 0 ? item.count / total : 0.0;
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color:  item.color,
            shape:  BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(item.label,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        ),
        SizedBox(
          width: 80,
          child: LinearProgressIndicator(
            value:            pct,
            backgroundColor:  item.color.withOpacity(0.15),
            color:            item.color,
            borderRadius:     BorderRadius.circular(4),
            minHeight:        6,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 30,
          child: Text(
            item.count.toString(),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:      item.color,
              fontSize:   13,
            ),
          ),
        ),
      ],
    );
  }
}
 
// ─── Widget : Détail des réservations ────────────────────────────────────────
class _ReservationsDetail extends StatelessWidget {
  final ReservationsStats stats;
 
  const _ReservationsDetail({required this.stats});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat('En attente',  stats.enAttente,  AppColors.warning),
          _dividerV(),
          _MiniStat('Confirmées',  stats.confirmees, AppColors.available),
          _dividerV(),
          _MiniStat('Annulées',    stats.annulees,   AppColors.error),
          _dividerV(),
          _MiniStat('Terminées',   stats.terminees,  AppColors.disabled),
        ],
      ),
    );
  }
 
  Widget _dividerV() => Container(
    height: 40,
    width:  1,
    color:  AppColors.divider,
  );
}
 
class _MiniStat extends StatelessWidget {
  final String label;
  final int    value;
  final Color  color;
 
  const _MiniStat(this.label, this.value, this.color);
 
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize:   22,
            fontWeight: FontWeight.bold,
            color:      color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
 
// ─── Widget : Tuile action rapide ────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final int      badge;
  final Color    color;
  final VoidCallback onTap;
 
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.badge,
    required this.color,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:        color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: badge > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:        color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              )
            : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
 
// ─── Data holder interne ──────────────────────────────────────
class _StatusRow {
  final String label;
  final int    count;
  final Color  color;
  const _StatusRow(this.label, this.count, this.color);
}