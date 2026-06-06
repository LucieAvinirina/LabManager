import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/user_admin_model.dart';
import '../providers/users_provider.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// UserEditScreen — Formulaire de modification d'un utilisateur (admin)
// Appelle PUT /api/users/:id
// ─────────────────────────────────────────────────────────────────────────────
class UserEditScreen extends StatefulWidget {
  final UserAdminModel user;
 
  const UserEditScreen({super.key, required this.user});
 
  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}
 
class _UserEditScreenState extends State<UserEditScreen> {
  final _formKey   = GlobalKey<FormState>();
  late final TextEditingController _nomCtrl;
  late final TextEditingController _prenomCtrl;
  late final TextEditingController _emailCtrl;
  late String _selectedRole;
  bool _isSaving = false;
 
  final List<String> _roles = ['etudiant', 'enseignant', 'admin'];
 
  @override
  void initState() {
    super.initState();
    _nomCtrl      = TextEditingController(text: widget.user.nom);
    _prenomCtrl   = TextEditingController(text: widget.user.prenom);
    _emailCtrl    = TextEditingController(text: widget.user.email);
    _selectedRole = widget.user.role;
  }
 
  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }
 
  // ─── Sauvegarde ───────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
 
    final ok = await context.read<UsersProvider>().updateUser(
      widget.user.id,
      nom:    _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim(),
      email:  _emailCtrl.text.trim(),
      role:   _selectedRole,
    );
 
    if (!mounted) return;
    setState(() => _isSaving = false);
 
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:         Text('Utilisateur modifié avec succès'),
        backgroundColor: AppColors.available,
      ));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.read<UsersProvider>().errorMessage),
        backgroundColor: AppColors.error,
      ));
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:           const Text('Modifier l\'utilisateur'),
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
 
              // ─── Avatar + nom actuel ──────────────────────
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius:          36,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text(
                        widget.user.initiales,
                        style: const TextStyle(
                          color:      AppColors.primary,
                          fontSize:   24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.user.email,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
 
              // ─── Champs du formulaire ─────────────────────
              _buildCard([
                _label('Prénom'),
                _field(
                  controller: _prenomCtrl,
                  hint:       'Prénom',
                  icon:       Icons.person_outline,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Le prénom est requis' : null,
                ),
                const SizedBox(height: 12),
                _label('Nom'),
                _field(
                  controller: _nomCtrl,
                  hint:       'Nom',
                  icon:       Icons.person_outline,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Le nom est requis' : null,
                ),
                const SizedBox(height: 12),
                _label('Email'),
                _field(
                  controller:  _emailCtrl,
                  hint:        'Email institutionnel',
                  icon:        Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'L\'email est requis';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
              ]),
              const SizedBox(height: 16),
 
              // ─── Sélection du rôle ────────────────────────
              _buildCard([
                _label('Rôle'),
                const SizedBox(height: 8),
                ...['etudiant', 'enseignant', 'admin'].map((role) {
                  final color  = _roleColor(role);
                  final label  = _roleLabel(role);
                  final select = _selectedRole == role;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRole = role),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:        select ? color.withOpacity(0.12) : AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border:       Border.all(
                            color: select ? color : AppColors.divider,
                            width: select ? 2 : 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            select
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: select ? color : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label,
                                  style: TextStyle(
                                    fontWeight: select ? FontWeight.bold : FontWeight.normal,
                                    color:      select ? color : AppColors.textPrimary,
                                  )),
                              Text(_roleDesc(role),
                                  style: const TextStyle(
                                      color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ]),
              const SizedBox(height: 24),
 
              // ─── Bouton sauvegarder ───────────────────────
              SizedBox(
                width:  double.infinity,
                height: 50,
                child:  ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width:  20, height: 20,
                          child:  CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white),
                        )
                      : const Text('Enregistrer les modifications',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
 
  // ─── Helpers UI ───────────────────────────────────────────
  Widget _buildCard(List<Widget> children) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset:     const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
 
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize:   13,
            color:      AppColors.textPrimary)),
  );
 
  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:   controller,
      keyboardType: keyboardType,
      validator:    validator,
      decoration: InputDecoration(
        hintText:  hint,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
 
  Color  _roleColor(String r) =>
      r == 'admin' ? AppColors.primaryDark : r == 'enseignant' ? AppColors.available : AppColors.warning;
 
  String _roleLabel(String r) =>
      r == 'admin' ? 'Administrateur' : r == 'enseignant' ? 'Enseignant' : 'Étudiant';
 
  String _roleDesc(String r) {
    switch (r) {
      case 'admin':      return 'Accès complet à toutes les fonctionnalités';
      case 'enseignant': return 'Peut réserver la salle entière et voir les stats';
      default:           return 'Peut réserver un poste de travail individuel';
    }
  }
}
 