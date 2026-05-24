const usersService = require('./users.service');
 
// ─── Lister tous les utilisateurs (admin) ────────────────────────────────────
const getAll = async (req, res) => {
  try {
    const { role, est_actif } = req.query;
    const users = await usersService.getAll({ role, est_actif });
 
    return res.status(200).json({
      success: true,
      count: users.length,
      data: users,
    });
  } catch (error) {
    console.error('Erreur getAll users :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Obtenir un utilisateur par ID (admin) ────────────────────────────────────
const getById = async (req, res) => {
  try {
    const user = await usersService.getById(req.params.id);
    return res.status(200).json({ success: true, data: user });
  } catch (error) {
    if (error.message === 'USER_NOT_FOUND') {
      return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
    }
    console.error('Erreur getById user :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Obtenir son propre profil ────────────────────────────────────────────────
const getProfile = async (req, res) => {
  try {
    const profile = await usersService.getProfile(req.user.id);
    return res.status(200).json({ success: true, data: profile });
  } catch (error) {
    console.error('Erreur getProfile :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Modifier un utilisateur (admin) ─────────────────────────────────────────
const update = async (req, res) => {
  try {
    const { nom, prenom, email, role } = req.body;
    const user = await usersService.update(req.params.id, { nom, prenom, email, role });
 
    return res.status(200).json({
      success: true,
      message: 'Utilisateur modifié avec succès',
      data: user,
    });
  } catch (error) {
    if (error.message === 'USER_NOT_FOUND') {
      return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
    }
    if (error.message === 'EMAIL_ALREADY_EXISTS') {
      return res.status(409).json({ success: false, message: 'Cet email est déjà utilisé' });
    }
    console.error('Erreur update user :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Modifier son propre profil ───────────────────────────────────────────────
const updateProfile = async (req, res) => {
  try {
    const { nom, prenom } = req.body;
    const user = await usersService.updateProfile(req.user.id, { nom, prenom });
 
    return res.status(200).json({
      success: true,
      message: 'Profil mis à jour avec succès',
      data: user,
    });
  } catch (error) {
    console.error('Erreur updateProfile :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Changer son mot de passe ─────────────────────────────────────────────────
const changePassword = async (req, res) => {
  try {
    const { ancien_mot_de_passe, nouveau_mot_de_passe } = req.body;
 
    if (!ancien_mot_de_passe || !nouveau_mot_de_passe) {
      return res.status(400).json({
        success: false,
        message: 'Les champs ancien_mot_de_passe et nouveau_mot_de_passe sont obligatoires',
      });
    }
 
    await usersService.changePassword(req.user.id, {
      ancien_mot_de_passe,
      nouveau_mot_de_passe,
    });
 
    return res.status(200).json({
      success: true,
      message: 'Mot de passe modifié avec succès',
    });
  } catch (error) {
    if (error.message === 'ANCIEN_MDP_INVALIDE') {
      return res.status(401).json({
        success: false,
        message: 'Ancien mot de passe incorrect',
      });
    }
    if (error.message === 'MDP_TROP_COURT') {
      return res.status(400).json({
        success: false,
        message: 'Le nouveau mot de passe doit contenir au moins 6 caractères',
      });
    }
    console.error('Erreur changePassword :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Activer ou désactiver un compte (admin) ──────────────────────────────────
const toggleActif = async (req, res) => {
  try {
    const { est_actif } = req.body;
 
    if (est_actif === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Le champ est_actif (true/false) est obligatoire',
      });
    }
 
    const user = await usersService.toggleActif(req.params.id, est_actif);
    const action = est_actif ? 'activé' : 'désactivé';
 
    return res.status(200).json({
      success: true,
      message: `Compte ${action} avec succès`,
      data: user,
    });
  } catch (error) {
    if (error.message === 'USER_NOT_FOUND') {
      return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
    }
    console.error('Erreur toggleActif :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Supprimer un utilisateur (admin) ────────────────────────────────────────
const remove = async (req, res) => {
  try {
    await usersService.remove(req.params.id);
    return res.status(200).json({
      success: true,
      message: 'Utilisateur supprimé avec succès',
    });
  } catch (error) {
    if (error.message === 'USER_NOT_FOUND') {
      return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
    }
    console.error('Erreur remove user :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Statistiques utilisateurs (admin) ───────────────────────────────────────
const getStats = async (req, res) => {
  try {
    const stats = await usersService.getStats();
    return res.status(200).json({ success: true, data: stats });
  } catch (error) {
    console.error('Erreur getStats users :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
module.exports = {
  getAll, getById, getProfile, update, updateProfile,
  changePassword, toggleActif, remove, getStats,
};
 