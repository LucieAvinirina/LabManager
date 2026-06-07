import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/profile_provider.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// ChangePasswordScreen — Formulaire changement de mot de passe
// Appelle PUT /api/users/password
// ─────────────────────────────────────────────────────────────────────────────
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
 
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}
 
class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _ancienCtrl    = TextEditingController();
  final _nouveauCtrl   = TextEditingController();
  final _confirmCtrl   = TextEditingController();
 
  bool _showAncien    = false;
  bool _showNouveau   = false;
  bool _showConfirm   = false;
 
  @override
  void dispose() {
    _ancienCtrl.dispose();
    _nouveauCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
 
    final ok = await context.read<ProfileProvider>().changePassword(
      ancienMotDePasse:  _ancienCtrl.text,
      nouveauMotDePasse: _nouveauCtrl.text,
    );
 
    if (!mounted) return;
 
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:         Text('Mot de passe modifié avec succès'),
        backgroundColor: AppColors.available,
      ));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text(context.read<ProfileProvider>().errorMessage),
        backgroundColor: AppColors.error,
      ));
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProfileProvider>();
 
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:           const Text('Changer le mot de passe'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation:       0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
 
              // ─── Info box ────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:        AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Le mot de passe doit contenir au moins 6 caractères.',
                        style: TextStyle(
                            color:    AppColors.primary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
 
              // ─── Champs ───────────────────────────────────
              _buildCard([
                _label('Mot de passe actuel'),
                _passwordField(
                  controller: _ancienCtrl,
                  hint:       'Votre mot de passe actuel',
                  show:       _showAncien,
                  onToggle:   () => setState(() => _showAncien = !_showAncien),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Ce champ est requis' : null,
                ),
                const SizedBox(height: 16),
                _label('Nouveau mot de passe'),
                _passwordField(
                  controller: _nouveauCtrl,
                  hint:       'Choisissez un nouveau mot de passe',
                  show:       _showNouveau,
                  onToggle:   () => setState(() => _showNouveau = !_showNouveau),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ce champ est requis';
                    if (v.length < 6)
                      return 'Minimum 6 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _label('Confirmer le nouveau mot de passe'),
                _passwordField(
                  controller: _confirmCtrl,
                  hint:       'Retapez le nouveau mot de passe',
                  show:       _showConfirm,
                  onToggle:   () => setState(() => _showConfirm = !_showConfirm),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ce champ est requis';
                    if (v != _nouveauCtrl.text)
                      return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),
              ]),
              const SizedBox(height: 24),
 
              // ─── Bouton ───────────────────────────────────
              SizedBox(
                width:  double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: prov.isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: prov.isSaving
                      ? const SizedBox(
                          width:  20, height: 20,
                          child:  CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white),
                        )
                      : const Text('Modifier le mot de passe',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  // ─── Helpers ──────────────────────────────────────────────
  Widget _buildCard(List<Widget> children) => Container(
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
        crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
 
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize:   13,
            color:      AppColors.textPrimary)),
  );
 
  Widget _passwordField({
    required TextEditingController   controller,
    required String                  hint,
    required bool                    show,
    required VoidCallback            onToggle,
    String? Function(String?)?       validator,
  }) =>
      TextFormField(
        controller:    controller,
        obscureText:   !show,
        validator:     validator,
        decoration: InputDecoration(
          hintText:    hint,
          prefixIcon: const Icon(Icons.lock_outline,
              color: AppColors.textSecondary, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.textSecondary,
              size:  20,
            ),
            onPressed: onToggle,
          ),
          filled:    true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:   BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:   const BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 14),
        ),
      );
}