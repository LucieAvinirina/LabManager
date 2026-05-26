import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
 
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
 
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Admin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
 
            // ─── Bienvenue ────────────────────────────────
            Text(
              'Bonjour, ${user?.prenom ?? ''} 👋',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            const Text('Voici l\'état du laboratoire aujourd\'hui',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
 
            // ─── Cartes statistiques rapides ──────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  icon:  Icons.computer,
                  label: 'Équipements',
                  color: AppColors.primary,
                  onTap: () {},
                ),
                _StatCard(
                  icon:  Icons.event,
                  label: 'Réservations',
                  color: AppColors.available,
                  onTap: () {},
                ),
                _StatCard(
                  icon:  Icons.warning_outlined,
                  label: 'Incidents',
                  color: AppColors.error,
                  onTap: () {},
                ),
                _StatCard(
                  icon:  Icons.people_outline,
                  label: 'Utilisateurs',
                  color: AppColors.warning,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
 
            // ─── Actions rapides ──────────────────────────
            const Text('Actions rapides',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
 
            _ActionTile(
              icon:  Icons.pending_actions,
              label: 'Réservations en attente',
              color: AppColors.warning,
              onTap: () {},
            ),
            _ActionTile(
              icon:  Icons.build_outlined,
              label: 'Incidents non résolus',
              color: AppColors.error,
              onTap: () {},
            ),
            _ActionTile(
              icon:  Icons.notifications_outlined,
              label: 'Envoyer une notification',
              color: AppColors.primary,
              onTap: () {},
            ),
            _ActionTile(
              icon:  Icons.bar_chart,
              label: 'Voir les rapports',
              color: AppColors.available,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
 
// ─── Widget carte stat ─────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;
 
  const _StatCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
 
// ─── Widget action rapide ──────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;
 
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}