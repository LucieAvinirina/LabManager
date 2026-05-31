import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/equipements/presentation/providers/equipements_provider.dart';
import 'features/reservations/presentation/providers/reservations_provider.dart';
import 'features/incidents/presentation/providers/incidents_provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // ← AJOUTER cet import
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Initialiser Firebase seulement sur mobile ────────────
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase non initialisé : $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EquipementsProvider()),
        ChangeNotifierProvider(create: (_) => ReservationsProvider()),
        ChangeNotifierProvider(create: (_) => IncidentsProvider()),
      ],
      child: const LabManagerApp(),
    ),
  );
}
 