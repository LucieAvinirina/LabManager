import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';
 
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
 
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
 
class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _nomController   = TextEditingController();
  final _prenomController= TextEditingController();
  final _emailController = TextEditingController();
  final _mdpController   = TextEditingController();
  bool  _obscurePassword = true;
  String _selectedRole   = 'etudiant';
 
  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _mdpController.dispose();
    super.dispose();
  }
 
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
 
    final provider = context.read<AuthProvider>();
    final success  = await provider.register(
      nom:        _nomController.text.trim(),
      prenom:     _prenomController.text.trim(),
      email:      _emailController.text.trim(),
      motDePasse: _mdpController.text.trim(),
      role:       _selectedRole,
    );
 
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte créé avec succès ! Connectez-vous.'),
          backgroundColor: AppColors.available,
        ),
      );
      context.go('/login');
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.register),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
 
              // ─── Formulaire ──────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  children: [
 
                    // Message d'erreur
                    Consumer<AuthProvider>(
                      builder: (_, provider, __) {
                        if (provider.errorMessage.isEmpty) return const SizedBox();
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.error.withOpacity(0.3)),
                          ),
                          child: Text(
                            provider.errorMessage,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        );
                      },
                    ),
 
                    // Nom
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.nom,
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Nom obligatoire' : null,
                      onChanged: (_) =>
                          context.read<AuthProvider>().clearError(),
                    ),
                    const SizedBox(height: 16),
 
                    // Prénom
                    TextFormField(
                      controller: _prenomController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.prenom,
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Prénom obligatoire' : null,
                    ),
                    const SizedBox(height: 16),
 
                    // Email
                    TextFormField(
                      controller:   _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: AppStrings.email,
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Email obligatoire';
                        if (!val.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
 
                    // Mot de passe
                    TextFormField(
                      controller:  _mdpController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: AppStrings.password,
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Mot de passe obligatoire';
                        if (val.length < 6) return 'Minimum 6 caractères';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
 
                    // Rôle
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Rôle',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'etudiant',
                          child: Text('Étudiant'),
                        ),
                        DropdownMenuItem(
                          value: 'enseignant',
                          child: Text('Enseignant'),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedRole = val ?? 'etudiant'),
                    ),
                    const SizedBox(height: 32),
 
                    // Bouton inscription
                    Consumer<AuthProvider>(
                      builder: (_, provider, __) {
                        return ElevatedButton(
                          onPressed: provider.isLoading ? null : _submit,
                          child: provider.isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Créer mon compte'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}