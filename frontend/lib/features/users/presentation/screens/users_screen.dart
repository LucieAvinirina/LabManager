import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/user_admin_model.dart';
import '../providers/users_provider.dart';
import 'user_edit_screen.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// UsersScreen — Liste des utilisateurs avec recherche, filtres et actions admin
// Routes : GET /api/users  |  GET /api/users/stats
// ─────────────────────────────────────────────────────────────────────────────
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
 
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}
 
class _UsersScreenState extends State<UsersScreen> {
  final _searchCtrl = TextEditingController();
 
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().loadUsers();
    });
  }
 
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UsersProvider>();
 
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:           const Text('Gestion des utilisateurs'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation:       0,
        actions: [
          IconButton(
            icon:    const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: () => prov.refresh(),
          ),
        ],
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : prov.status == UsersStatus.error
              ? _buildError(context, prov)
              : RefreshIndicator(
                  color:     AppColors.primary,
                  onRefresh: () => prov.refresh(),
                  child:     _buildContent(context, prov),
                ),
    );
  }
 
  // ─── Écran d'erreur ───────────────────────────────────────
  Widget _buildError(BuildContext context, UsersProvider prov) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(prov.errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed:  () => prov.loadUsers(),
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
  Widget _buildContent(BuildContext context, UsersProvider prov) {
    return CustomScrollView(
      slivers: [
        // ─── Bandeau stats ────────────────────────────────
        SliverToBoxAdapter(child: _buildStatsBar(prov)),
 
        // ─── Barre recherche + filtres ────────────────────
        SliverToBoxAdapter(child: _buildSearchAndFilters(context, prov)),
 
        // ─── Résultat vide ────────────────────────────────
        if (prov.users.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text('Aucun utilisateur trouvé',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else
          // ─── Liste utilisateurs ────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _UserCard(
                user:       prov.users[index],
                onEdit:     () => _openEdit(context, prov.users[index]),
                onToggle:   () => _confirmToggle(context, prov, prov.users[index]),
                onDelete:   () => _confirmDelete(context, prov, prov.users[index]),
              ),
              childCount: prov.users.length,
            ),
          ),
 
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
 
  // ─── Bandeau statistiques en haut ─────────────────────────
  Widget _buildStatsBar(UsersProvider prov) {
    final s = prov.stats;
    if (s == null) return const SizedBox.shrink();
 
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _StatChip(label: 'Total',        value: s.total,       color: AppColors.white),
          const SizedBox(width: 8),
          _StatChip(label: 'Étudiants',    value: s.etudiants,   color: AppColors.white),
          const SizedBox(width: 8),
          _StatChip(label: 'Enseignants',  value: s.enseignants, color: AppColors.white),
          const SizedBox(width: 8),
          _StatChip(label: 'Inactifs',     value: s.inactifs,    color: AppColors.warning),
        ],
      ),
    );
  }
 
  // ─── Barre de recherche + chips de filtre ─────────────────
  Widget _buildSearchAndFilters(BuildContext context, UsersProvider prov) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Recherche
          TextField(
            controller:  _searchCtrl,
            onChanged:   prov.setSearch,
            decoration: InputDecoration(
              hintText:     'Rechercher par nom, prénom, email…',
              prefixIcon:   const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon:      const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        prov.setSearch('');
                      },
                    )
                  : null,
              filled:       true,
              fillColor:    AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:   BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
 
          // Chips filtres
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label:    'Tous',
                  selected: prov.filterRole == null && prov.filterActif == null,
                  onTap:    () => prov.clearFilters(),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label:    'Étudiants',
                  selected: prov.filterRole == 'etudiant',
                  onTap:    () => prov.setFilterRole(
                      prov.filterRole == 'etudiant' ? null : 'etudiant'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label:    'Enseignants',
                  selected: prov.filterRole == 'enseignant',
                  onTap:    () => prov.setFilterRole(
                      prov.filterRole == 'enseignant' ? null : 'enseignant'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label:    'Admins',
                  selected: prov.filterRole == 'admin',
                  onTap:    () => prov.setFilterRole(
                      prov.filterRole == 'admin' ? null : 'admin'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label:    'Inactifs',
                  selected: prov.filterActif == false,
                  color:    AppColors.error,
                  onTap:    () => prov.setFilterActif(
                      prov.filterActif == false ? null : false),
                ),
              ],
            ),
          ),
 
          // Compteur résultats
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${prov.users.length} utilisateur${prov.users.length > 1 ? 's' : ''}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  // ─── Navigation vers l'écran de modification ──────────────
  void _openEdit(BuildContext context, UserAdminModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserEditScreen(user: user)),
    );
  }
 
  // ─── Confirmation toggle actif/inactif ────────────────────
  Future<void> _confirmToggle(
      BuildContext context, UsersProvider prov, UserAdminModel user) async {
    final action = user.estActif ? 'désactiver' : 'activer';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${user.estActif ? 'Désactiver' : 'Activer'} le compte'),
        content: Text(
            'Voulez-vous $action le compte de ${user.fullName} ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed:  () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.estActif ? AppColors.error : AppColors.available,
              foregroundColor: AppColors.white,
            ),
            child: Text(user.estActif ? 'Désactiver' : 'Activer'),
          ),
        ],
      ),
    );
 
    if (confirm == true && context.mounted) {
      final ok = await prov.toggleActif(user.id, estActif: !user.estActif);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? 'Compte ${!user.estActif ? 'activé' : 'désactivé'} avec succès'
              : prov.errorMessage),
          backgroundColor: ok ? AppColors.available : AppColors.error,
        ));
      }
    }
  }
 
  // ─── Confirmation suppression ─────────────────────────────
  Future<void> _confirmDelete(
      BuildContext context, UsersProvider prov, UserAdminModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${user.fullName} ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed:  () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
 
    if (confirm == true && context.mounted) {
      final ok = await prov.deleteUser(user.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Utilisateur supprimé' : prov.errorMessage),
          backgroundColor: ok ? AppColors.available : AppColors.error,
        ));
      }
    }
  }
}
 
// ─── Widget : Carte utilisateur ──────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final UserAdminModel user;
  final VoidCallback   onEdit;
  final VoidCallback   onToggle;
  final VoidCallback   onDelete;
 
  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });
 
  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(user.role);
 
    return Card(
      margin:     const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation:  1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ─── Avatar ──────────────────────────────────
            Stack(
              children: [
                CircleAvatar(
                  radius:          24,
                  backgroundColor: roleColor.withOpacity(0.15),
                  child: Text(
                    user.initiales,
                    style: TextStyle(
                        color:      roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize:   16),
                  ),
                ),
                if (!user.estActif)
                  Positioned(
                    right:  0, bottom: 0,
                    child: Container(
                      width: 12, height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
 
            // ─── Infos ───────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize:   14,
                            color: user.estActif
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (!user.estActif)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:        AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Inactif',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(user.email,
                      style: const TextStyle(
                          color:    AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:        roleColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      user.roleLabel,
                      style: TextStyle(
                          color:      roleColor,
                          fontSize:   11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
 
            // ─── Menu actions ─────────────────────────────
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onSelected: (value) {
                if (value == 'edit')   onEdit();
                if (value == 'toggle') onToggle();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(children: [
                    Icon(
                      user.estActif
                          ? Icons.block_outlined
                          : Icons.check_circle_outline,
                      size:  18,
                      color: user.estActif ? AppColors.error : AppColors.available,
                    ),
                    const SizedBox(width: 8),
                    Text(user.estActif ? 'Désactiver' : 'Activer'),
                  ]),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Supprimer',
                        style: TextStyle(color: AppColors.error)),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
 
  Color _roleColor(String role) {
    switch (role) {
      case 'admin':      return AppColors.primaryDark;
      case 'enseignant': return AppColors.available;
      default:           return AppColors.warning;
    }
  }
}
 
// ─── Widget : Chip statistique dans le bandeau ────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final int    value;
  final Color  color;
 
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(value.toString(),
              style: TextStyle(
                  color:      color,
                  fontWeight: FontWeight.bold,
                  fontSize:   16)),
          Text(label,
              style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}
 
// ─── Widget : Chip de filtre ──────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool   selected;
  final Color? color;
  final VoidCallback onTap;
 
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });
 
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:        selected ? c : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: selected ? c : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:      selected ? AppColors.white : AppColors.textSecondary,
            fontSize:   13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}