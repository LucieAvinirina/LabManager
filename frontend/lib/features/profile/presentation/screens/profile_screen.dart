import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen — Profil complet avec stats, infos et actions
// Appelle GET /api/users/profile
// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
 
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
 
class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }
 
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProfileProvider>();
 
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:           const Text('Mon profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation:       0,
        actions: [
          IconButton(
            icon:    const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: () => prov.loadProfile(),
          ),
        ],
      ),
      body: switch (prov.status) {
        ProfileStatus.loading => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        ProfileStatus.error => _buildError(context, prov),
        _ => prov.profile == null
            ? const SizedBox.shrink()
            : RefreshIndicator(
                color:     AppColors.primary,
                onRefresh: () => prov.loadProfile(),
                child:     _buildContent(context, prov),
              ),
      },
    );
  }
 
  // ─── Écran d'erreur ───────────────────────────────────────
  Widget _buildError(BuildContext context, ProfileProvider prov) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(prov.errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed:  () => prov.loadProfile(),
              icon:       const Icon(Icons.refresh),
              label:      const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  // ─── Contenu principal ────────────────────────────────────
  Widget _buildContent(BuildContext context, ProfileProvider prov) {
    final profile = prov.profile!;
 
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // ─── En-tête avec avatar et infos ─────────────────
          _buildHeader(context, profile),
 
          // ─── Cartes stats ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon:  Icons.event_outlined,
                    label: 'Réservations',
                    value: profile.totalReservations,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon:  Icons.warning_amber_outlined,
                    label: 'Incidents',
                    value: profile.totalIncidents,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
 
          // ─── Informations du compte ────────────────────────
          _buildSection(
            title: 'Informations du compte',
            children: [
              _InfoTile(
                icon:  Icons.person_outline,
                label: 'Nom complet',
                value: profile.fullName,
              ),
              _InfoTile(
                icon:  Icons.email_outlined,
                label: 'Email',
                value: profile.email,
              ),
              _InfoTile(
                icon:  Icons.badge_outlined,
                label: 'Rôle',
                value: profile.roleLabel,
                valueColor: _roleColor(profile.role),
              ),
              _InfoTile(
                icon:  Icons.calendar_today_outlined,
                label: 'Membre depuis',
                value: _formatDate(profile.dateCreation),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
 
          // ─── Actions ──────────────────────────────────────
          _buildSection(
            title: 'Paramètres',
            children: [
              _ActionTile(
                icon:  Icons.edit_outlined,
                label: 'Modifier mon profil',
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(profile: profile),
                  ),
                ).then((_) => prov.loadProfile()),
              ),
              _ActionTile(
                icon:  Icons.lock_outline,
                label: 'Changer mon mot de passe',
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                ),
              ),
              _ActionTile(
                icon:    Icons.logout,
                label:   'Se déconnecter',
                color:   AppColors.error,
                isLast:  true,
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
 
          // ─── Version app ───────────────────────────────────
          Text(
            'LabManager v1.0.0',
            style: TextStyle(
              color:    AppColors.textSecondary.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
 
  // ─── En-tête avatar + nom + rôle ──────────────────────────
  Widget _buildHeader(BuildContext context, profile) {
    final roleColor = _roleColor(profile.role);
 
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius:          48,
                backgroundColor: AppColors.white.withOpacity(0.2),
                child: Text(
                  profile.initiales,
                  style: const TextStyle(
                    color:      AppColors.white,
                    fontSize:   32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:  roleColor,
                  shape:  BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: const Icon(Icons.verified_user,
                    color: AppColors.white, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
 
          // Nom
          Text(
            profile.fullName,
            style: const TextStyle(
              color:      AppColors.white,
              fontSize:   22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
 
          // Email
          Text(
            profile.email,
            style: TextStyle(
              color:    AppColors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
 
          // Badge rôle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color:        AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: AppColors.white.withOpacity(0.4)),
            ),
            child: Text(
              profile.roleLabel.toUpperCase(),
              style: const TextStyle(
                color:      AppColors.white,
                fontSize:   12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  // ─── Section avec titre et carte ──────────────────────────
  Widget _buildSection({
    required String        title,
    required List<Widget>  children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.bold,
              color:      AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
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
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
 
  // ─── Confirmation déconnexion ──────────────────────────────
  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:   const Text('Se déconnecter'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:     const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
 
    if (confirm == true && context.mounted) {
      context.read<ProfileProvider>().reset();
      await context.read<AuthProvider>().logout();
      if (context.mounted) context.go('/login');
    }
  }
 
  // ─── Helpers ──────────────────────────────────────────────
  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('d MMMM yyyy', 'fr_FR').format(dt);
    } catch (_) {
      return raw;
    }
  }
 
  Color _roleColor(String role) {
    switch (role) {
      case 'admin':      return AppColors.primaryDark;
      case 'enseignant': return AppColors.available;
      default:           return AppColors.warning;
    }
  }
}
 
// ─── Widget : Carte statistique ───────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final int      value;
  final Color    color;
 
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
 
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
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:        color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize:   24,
                  fontWeight: FontWeight.bold,
                  color:      color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color:    AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
 
// ─── Widget : Ligne d'information ────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;
  final bool     isLast;
 
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });
 
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color:    AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w600,
                        color:      valueColor ?? AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 50),
      ],
    );
  }
}
 
// ─── Widget : Ligne d'action ─────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  final bool         isLast;
 
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLast = false,
  });
 
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color:      color == AppColors.error ? AppColors.error : AppColors.textPrimary,
            ),
          ),
          trailing: Icon(Icons.chevron_right,
              color: AppColors.textSecondary, size: 20),
          onTap: onTap,
        ),
        if (!isLast)
          const Divider(height: 1, indent: 56),
      ],
    );
  }
}