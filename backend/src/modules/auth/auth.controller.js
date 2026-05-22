const authService = require('./auth.service');
 
// ─── Inscription ──────────────────────────────────────────────────────────────
const register = async (req, res) => {
  try {
    const { nom, prenom, email, mot_de_passe, role } = req.body;
 
    // Validation des champs obligatoires
    if (!nom || !prenom || !email || !mot_de_passe) {
      return res.status(400).json({
        success: false,
        message: 'Tous les champs sont obligatoires (nom, prenom, email, mot_de_passe)',
      });
    }
 
    // Validation format email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: 'Format email invalide',
      });
    }
 
    // Validation mot de passe (minimum 6 caractères)
    if (mot_de_passe.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Le mot de passe doit contenir au moins 6 caractères',
      });
    }
 
    const user = await authService.register({ nom, prenom, email, mot_de_passe, role });
 
    return res.status(201).json({
      success: true,
      message: 'Compte créé avec succès',
      data: user,
    });
 
  } catch (error) {
    if (error.message === 'EMAIL_ALREADY_EXISTS') {
      return res.status(409).json({
        success: false,
        message: 'Cet email est déjà utilisé',
      });
    }
    if (error.message === 'ROLE_INVALIDE') {
      return res.status(400).json({
        success: false,
        message: 'Rôle invalide. Valeurs acceptées : etudiant, enseignant, admin',
      });
    }
    console.error('Erreur register :', error.message);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de l\'inscription',
    });
  }
};
 
// ─── Connexion ────────────────────────────────────────────────────────────────
const login = async (req, res) => {
  try {
    const { email, mot_de_passe } = req.body;
 
    // Validation des champs obligatoires
    if (!email || !mot_de_passe) {
      return res.status(400).json({
        success: false,
        message: 'Email et mot de passe obligatoires',
      });
    }
 
    const result = await authService.login({ email, mot_de_passe });
 
    return res.status(200).json({
      success: true,
      message: 'Connexion réussie',
      data: result,
    });
 
  } catch (error) {
    if (error.message === 'IDENTIFIANTS_INVALIDES') {
      return res.status(401).json({
        success: false,
        message: 'Email ou mot de passe incorrect',
      });
    }
    if (error.message === 'COMPTE_DESACTIVE') {
      return res.status(403).json({
        success: false,
        message: 'Votre compte a été désactivé. Contactez l\'administrateur',
      });
    }
    console.error('Erreur login :', error.message);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la connexion',
    });
  }
};
 
// ─── Mise à jour FCM token ────────────────────────────────────────────────────
const updateFcmToken = async (req, res) => {
  try {
    const { fcm_token } = req.body;
    const id_utilisateur = req.user.id;
 
    if (!fcm_token) {
      return res.status(400).json({
        success: false,
        message: 'fcm_token obligatoire',
      });
    }
 
    await authService.updateFcmToken(id_utilisateur, fcm_token);
 
    return res.status(200).json({
      success: true,
      message: 'FCM token mis à jour avec succès',
    });
 
  } catch (error) {
    console.error('Erreur updateFcmToken :', error.message);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
};
 
module.exports = { register, login, updateFcmToken };
 