
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../equipements/presentation/screens/equipements_screen.dart';
import '../../../reservations/presentation/screens/mes_reservations_screen.dart';
import '../../../incidents/presentation/screens/incidents_screen.dart';
import '../../../users/presentation/screens/users_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
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
      const ProfileScreen(),
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
 