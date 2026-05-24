const express = require('express');
const router = express.Router();
const usersController = require('./users.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');
const { requireRole } = require('../../middlewares/role.middleware');
 
// ─── Routes accessibles à tous les utilisateurs connectés ────────────────────
 
// GET /api/users/profile → Voir son propre profil
router.get('/profile', verifyToken, usersController.getProfile);
 
// PUT /api/users/profile → Modifier son propre profil (nom, prenom)
router.put('/profile', verifyToken, usersController.updateProfile);
 
// PUT /api/users/password → Changer son propre mot de passe
router.put('/password', verifyToken, usersController.changePassword);
 
// ─── Routes admin seulement ───────────────────────────────────────────────────
 
// GET /api/users → Lister tous les utilisateurs
router.get('/', verifyToken, requireRole('admin'), usersController.getAll);
 
// GET /api/users/stats → Statistiques des utilisateurs
router.get('/stats', verifyToken, requireRole('admin'), usersController.getStats);
 
// GET /api/users/:id → Détail d'un utilisateur
router.get('/:id', verifyToken, requireRole('admin'), usersController.getById);
 
// PUT /api/users/:id → Modifier un utilisateur (nom, email, role)
router.put('/:id', verifyToken, requireRole('admin'), usersController.update);
 
// PATCH /api/users/:id/actif → Activer ou désactiver un compte
router.patch('/:id/actif', verifyToken, requireRole('admin'), usersController.toggleActif);
 
// DELETE /api/users/:id → Supprimer un utilisateur
router.delete('/:id', verifyToken, requireRole('admin'), usersController.remove);
 
module.exports = router;