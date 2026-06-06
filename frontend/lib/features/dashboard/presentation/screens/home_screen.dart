import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../equipements/presentation/screens/equipements_screen.dart';
import '../../../reservations/presentation/screens/mes_reservations_screen.dart';
import '../../../incidents/presentation/screens/incidents_screen.dart';
import '../../../users/presentation/screens/users_screen.dart';
import 'admin_dashboard_screen.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — Shell de navigation avec BottomNavigationBar
// Expose _HomeScreenState pour permettre la navigation depuis le Dashboard
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
 
  @override
  State<HomeScreen> createState() => HomeScreenState();
}
 
// Classe publique pour que AdminDashboardScreen puisse y accéder
class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
 
  // ─── Naviguer vers un onglet donné (appelé depuis le Dashboard) ──
  void navigateTo(int index) {
    setState(() => _currentIndex = index);
  }
 
  // ─── Pages selon le rôle ──────────────────────────────────
  List<Widget> _getPages(bool isAdmin) {
    return [
      if (isAdmin) const AdminDashboardScreen(),
      const EquipementsScreen(),
      const MesReservationsScreen(),
      const IncidentsScreen(),
      if (isAdmin) const UsersScreen(),
      const _ProfilePage(),
    ];
  }
 
  // ─── Items de navigation selon le rôle ───────────────────
  List<NavigationDestination> _getNavItems(bool isAdmin) {
    return [
      if (isAdmin)
        const NavigationDestination(
          icon:         Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label:        'Dashboard',
        ),
      const NavigationDestination(
        icon:         Icon(Icons.computer_outlined),
        selectedIcon: Icon(Icons.computer),
        label:        'Équipements',
      ),
      const NavigationDestination(
        icon:         Icon(Icons.event_outlined),
        selectedIcon: Icon(Icons.event),
        label:        'Réservations',
      ),
      const NavigationDestination(
        icon:         Icon(Icons.warning_amber_outlined),
        selectedIcon: Icon(Icons.warning_amber),
        label:        'Incidents',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon:         Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label:        'Utilisateurs',
        ),
      const NavigationDestination(
        icon:         Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label:        'Profil',
      ),
    ];
  }
 
  @override
  Widget build(BuildContext context) {
    final user     = context.watch<AuthProvider>().user;
    final isAdmin  = user?.isAdmin ?? false;
    final pages    = _getPages(isAdmin);
    final navItems = _getNavItems(isAdmin);
 
    // S'assurer que l'index ne dépasse pas le nombre de pages
    final safeIndex = _currentIndex.clamp(0, pages.length - 1);
 
    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: AppColors.white,
        indicatorColor:  AppColors.primary.withOpacity(0.15),
        labelBehavior:   NavigationDestinationLabelBehavior.alwaysShow,
        destinations:    navItems,
      ),
    );
  }
}
 
// ─── Page Profil ──────────────────────────────────────────────
class _ProfilePage extends StatelessWidget {
  const _ProfilePage();
 
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
 
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profil)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
 
            // ─── Avatar ───────────────────────────────────
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryDark,
              child: Text(
                user?.prenom.isNotEmpty == true
                    ? user!.prenom[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize:   36,
                    color:      Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
 
            // ─── Nom et rôle ──────────────────────────────
            Text(
              user?.fullName ?? '',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color:        AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user?.role.toUpperCase() ?? '',
                style: const TextStyle(
                    color:      AppColors.primary,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
 
            // ─── Options ──────────────────────────────────
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline,
                        color: AppColors.primary),
                    title:   const Text('Modifier mon profil'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap:   () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_outline,
                        color: AppColors.primary),
                    title:   const Text('Changer mon mot de passe'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap:   () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.history,
                        color: AppColors.primary),
                    title:   const Text('Historique de réservations'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap:   () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
 
            // ─── Déconnexion ──────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                icon:  const Icon(Icons.logout),
                label: const Text(AppStrings.logout),
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 