import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/secure_storage.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/dashboard/presentation/screens/home_screen.dart';
 
class LabManagerApp extends StatelessWidget {
  const LabManagerApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LabManager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
 
// ─── GoRouter — Navigation ────────────────────────────────────────────────────
final GoRouter _router = GoRouter(
  initialLocation: '/login',
 
  // Redirection selon l'état de connexion
  redirect: (context, state) async {
    final isLoggedIn = await SecureStorage.isLoggedIn();
    final isOnLogin  = state.matchedLocation == '/login' ||
                       state.matchedLocation == '/register';
 
    if (!isLoggedIn && !isOnLogin) return '/login';
    if (isLoggedIn  &&  isOnLogin) return '/home';
    return null;
  },
 
  routes: [
    GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/home',     builder: (_, __) => const HomeScreen()),
  ],
);