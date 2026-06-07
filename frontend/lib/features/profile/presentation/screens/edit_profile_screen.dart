import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/profile_model.dart';
import '../providers/profile_provider.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// EditProfileScreen — Modifier nom et prénom
// Appelle PUT /api/users/profile
// ─────────────────────────────────────────────────────────────────────────────
class EditProfileScreen extends StatefulWidget {
  final ProfileModel profile;
 
  const EditProfileScreen({super.key, required this.profile});
 
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}
 
class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey   = GlobalKey<FormState>();
  late final TextEditingController _nomCtrl;
  late final TextEditingController _prenomCtrl;
 
  @override
  void initState() {
    super.initState();
    _nomCtrl    = TextEditingController(text: widget.profile.nom);
    _prenomCtrl = TextEditingController(text: widget.profile.prenom);
  }
 
  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
 
    final ok = await context.read<ProfileProvider>().updateProfile(
      nom:    _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim(),
    );
 
    if (!mounted) return;
 
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:         Text('Profil mis à jour avec succès'),
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
        title:           const Text('Modifier mon profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation:       0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ─── Avatar ──────────────────────────────────
              const SizedBox(height: 16),
              CircleAvatar(
                radius:          48,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  widget.profile.initiales,
                  style: const TextStyle(
                    color:      AppColors.primary,
                    fontSize:   32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(widget.profile.email,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 28),
 
              // ─── Formulaire ──────────────────────────────
              _buildCard([
                _label('Prénom'),
                _field(
                  controller: _prenomCtrl,
                  hint:       'Votre prénom',
                  icon:       Icons.person_outline,
                  validator:  (v) => v == null || v.trim().isEmpty
                      ? 'Le prénom est requis' : null,
                ),
                const SizedBox(height: 16),
                _label('Nom'),
                _field(
                  controller: _nomCtrl,
                  hint:       'Votre nom',
                  icon:       Icons.person_outline,
                  validator:  (v) => v == null || v.trim().isEmpty
                      ? 'Le nom est requis' : null,
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
                      : const Text('Enregistrer',
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
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
 
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize:   13,
            color:      AppColors.textPrimary)),
  );
 
  Widget _field({
    required TextEditingController   controller,
    required String                  hint,
    required IconData                icon,
    String? Function(String?)?       validator,
  }) =>
      TextFormField(
        controller: controller,
        validator:  validator,
        decoration: InputDecoration(
          hintText:   hint,
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
          filled:     true,
          fillColor:  AppColors.background,
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