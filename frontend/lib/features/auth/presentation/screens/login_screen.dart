import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';
 
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
 
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
 
class _LoginScreenState extends State<LoginScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _mdpController   = TextEditingController();
  bool  _obscurePassword = true;
 
  @override
  void dispose() {
    _emailController.dispose();
    _mdpController.dispose();
    super.dispose();
  }
 
  // ─── Soumission du formulaire ─────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
 
    final provider = context.read<AuthProvider>();
    final success  = await provider.login(
      email:      _emailController.text.trim(),
      motDePasse: _mdpController.text.trim(),
    );
 
    if (success && mounted) {
      context.go('/home');
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
 
              // ─── Logo et titre ───────────────────────────
              _buildHeader(),
 
              const SizedBox(height: 48),
 
              // ─── Formulaire ──────────────────────────────
              _buildForm(),
 
              const SizedBox(height: 24),
 
              // ─── Bouton connexion ─────────────────────────
              _buildLoginButton(),
 
              const SizedBox(height: 16),
 
              // ─── Lien inscription ─────────────────────────
              _buildRegisterLink(),
            ],
          ),
        ),
      ),
    );
  }
 
  // ─── Header avec logo ─────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.computer,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.appName,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.appSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
 
  // ─── Formulaire de connexion ──────────────────────────────
  Widget _buildForm() {
    return Form(
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
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.errorMessage,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
 
          // Champ email
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
            onChanged: (_) => context.read<AuthProvider>().clearError(),
          ),
 
          const SizedBox(height: 16),
 
          // Champ mot de passe
          TextFormField(
            controller:    _mdpController,
            obscureText:   _obscurePassword,
            decoration: InputDecoration(
              labelText: AppStrings.password,
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Mot de passe obligatoire';
              if (val.length < 6) return 'Minimum 6 caractères';
              return null;
            },
          ),
        ],
      ),
    );
  }
 
  // ─── Bouton connexion ─────────────────────────────────────
  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
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
              : const Text(AppStrings.login),
        );
      },
    );
  }
 
  // ─── Lien vers inscription ────────────────────────────────
  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Pas encore de compte ? ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        GestureDetector(
          onTap: () {
            context.read<AuthProvider>().clearError();
            context.go('/register');
          },
          child: Text(
            AppStrings.register,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}